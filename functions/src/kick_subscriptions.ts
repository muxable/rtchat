import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { kickApi } from "./kick";
import { getAppAccessToken } from "./oauth";

// Events every viewed Kick channel is subscribed to. They're delivered to
// kickWebhook. https://docs.kick.com/events/subscribe-to-events
export const KICK_EVENTS = [
  "chat.message.sent",
  "channel.followed",
  "channel.subscription.new",
  "channel.subscription.renewal",
  "channel.subscription.gifts",
  "kicks.gifted",
  "livestream.status.updated",
  "livestream.metadata.updated",
  "moderation.banned",
  "channel.reward.redemption.updated",
].map((name) => ({ name, version: 1 }));

// Unverified Kick apps can hold at most 1,000 chat.message.sent subscriptions.
const CHAT_SUBSCRIPTION_WARNING = 900;

// How often subscribe re-checks a channel's subscriptions with Kick. Kick
// drops subscriptions whose webhook keeps failing, so they're re-created here.
const RECHECK_MS = 60 * 60 * 1000;

const IDLE_MS = 7 * 86400 * 1000;

export interface KickSubscription {
  id: string;
  event: string;
  version: number;
}

export function missingEvents(existing: KickSubscription[]) {
  return KICK_EVENTS.filter(
    (wanted) =>
      !existing.some(
        (sub) => sub.event === wanted.name && sub.version === wanted.version
      )
  );
}

export function chunk<T>(items: T[], size: number) {
  const chunks: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}

// Fields kept on channels/kick:{id}, matching the ones twitch channels have.
export function toChannelMetadata(channel: any) {
  const stream = channel.stream ?? {};
  return {
    login: channel.slug,
    title: channel.stream_title ?? null,
    language: stream.language ?? null,
    categoryId: channel.category?.id ?? null,
    categoryName: channel.category?.name ?? null,
    viewerCount: stream.is_live ? stream.viewer_count ?? 0 : 0,
    // channels subscribed mid-stream never see livestream.status.updated, so
    // the poll keeps onlineAt in sync too.
    onlineAt:
      stream.is_live && stream.start_time ? new Date(stream.start_time) : null,
  };
}

async function appToken() {
  const token = await getAppAccessToken("kick");
  if (!token) {
    throw new functions.https.HttpsError("internal", "kick auth error");
  }
  return String(token.token.access_token);
}

// webhooks/{provider}:{id} tracks the channels whose events are pushed to us.
function subscriptionRef(broadcasterId: string) {
  return admin.firestore().collection("webhooks").doc(`kick:${broadcasterId}`);
}

// Returns the kick broadcaster ids among webhooks docs.
function kickBroadcasterIds(docs: admin.firestore.QueryDocumentSnapshot[]) {
  return docs
    .map((doc) => doc.id.split(":"))
    .filter(([provider]) => provider === "kick")
    .map(([, id]) => id);
}

// Makes sure a broadcaster's events are delivered to kickWebhook and marks the
// channel as active so the daily cleanup keeps it.
export async function ensureKickSubscriptions(broadcasterId: string) {
  const ref = subscriptionRef(broadcasterId);
  const doc = await ref.get();
  const checkedAt = doc.get("checkedAt")?.toMillis() ?? 0;
  if (doc.exists && Date.now() - checkedAt < RECHECK_MS) {
    await ref.update({
      lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  const token = await appToken();
  const listed = await kickApi(
    token,
    `/events/subscriptions?broadcaster_user_id=${broadcasterId}`
  );
  const existing: KickSubscription[] = listed?.data ?? [];
  const missing = missingEvents(existing);
  const created: string[] = [];
  if (missing.length > 0) {
    const response = await kickApi(token, "/events/subscriptions", {
      method: "POST",
      body: JSON.stringify({
        broadcaster_user_id: Number(broadcasterId),
        events: missing,
        method: "webhook",
      }),
    });
    for (const result of response?.data ?? []) {
      if (result.error) {
        functions.logger.error("failed to subscribe to kick event", {
          broadcasterId,
          result,
        });
      } else {
        created.push(result.subscription_id);
      }
    }
  }

  await ref.set({
    subscriptionIds: [...existing.map((sub) => sub.id), ...created],
    checkedAt: admin.firestore.FieldValue.serverTimestamp(),
    lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  if (!doc.exists) {
    // only kick channels live in webhooks today.
    const count = (
      await admin.firestore().collection("webhooks").count().get()
    ).data().count;
    if (count >= CHAT_SUBSCRIPTION_WARNING) {
      functions.logger.warn(
        `${count} kick channels subscribed; unverified apps are limited to 1,000 chat subscriptions`
      );
    }
  }
}

export async function removeKickSubscriptions(broadcasterId: string) {
  const ref = subscriptionRef(broadcasterId);
  const ids: string[] = (await ref.get()).get("subscriptionIds") ?? [];
  if (ids.length > 0) {
    const token = await appToken();
    for (const batch of chunk(ids, 50)) {
      const query = batch.map((id) => `id=${encodeURIComponent(id)}`).join("&");
      await kickApi(token, `/events/subscriptions?${query}`, {
        method: "DELETE",
      });
    }
  }
  await ref.delete();
}

// Called from the daily unsubscribe job.
export async function removeIdleKickSubscriptions() {
  const idle = await admin
    .firestore()
    .collection("webhooks")
    .where(
      "lastActiveAt",
      "<",
      admin.firestore.Timestamp.fromMillis(Date.now() - IDLE_MS)
    )
    .get();
  for (const broadcasterId of kickBroadcasterIds(idle.docs)) {
    try {
      await removeKickSubscriptions(broadcasterId);
    } catch (err) {
      functions.logger.error("failed to remove kick subscriptions", {
        broadcasterId,
        err,
      });
    }
  }
}

// Kick has no viewer count events, so poll the channels people are watching.
export const updateKickChannelMetadata = functions.pubsub
  .schedule("*/4 * * * *") // every 4 minutes, like twitch
  .onRun(async () => {
    const active = await admin
      .firestore()
      .collection("webhooks")
      .where(
        "lastActiveAt",
        ">",
        admin.firestore.Timestamp.fromMillis(Date.now() - 86400 * 1000)
      )
      .get();
    const ids = kickBroadcasterIds(active.docs);
    if (ids.length === 0) {
      return;
    }
    const token = await appToken();
    for (const batch of chunk(ids, 50)) {
      const query = batch.map((id) => `broadcaster_user_id=${id}`).join("&");
      const response = await kickApi(token, `/channels?${query}`);
      const writes = admin.firestore().batch();
      for (const channel of response?.data ?? []) {
        writes.set(
          admin
            .firestore()
            .collection("channels")
            .doc(`kick:${channel.broadcaster_user_id}`),
          toChannelMetadata(channel),
          { merge: true }
        );
      }
      await writes.commit();
    }
  });
