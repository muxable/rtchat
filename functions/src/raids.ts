import * as admin from "firebase-admin";

// Outgoing raid events, written in place of the PubSub raid topic that Twitch
// shut down. The app renders them with TwitchRaidingEventModel.

// Twitch sends a raid 90 seconds after it's started unless the streamer clicks
// "raid now" first.
export const RAID_COUNTDOWN_SECONDS = 90;

const TWO_WEEKS = 1000 * 86400 * 14;

export type RaidEventType = "raid_update_v2" | "raid_go_v2" | "raid_cancel_v2";

export interface RaidTarget {
  id: string;
  login: string;
  displayName: string;
}

// The `raid` field the app reads, in the shape PubSub delivered it.
export interface Raid {
  id: string;
  target_id: string;
  target_login: string;
  target_display_name: string;
  force_raid_now_seconds: number;
}

export interface MessageDoc {
  // the document id within channels/{channelId}/messages
  id: string;
  data: Record<string, unknown>;
}

// Twitch doesn't return a raid id, so it's derived from the target and the
// time Twitch started the raid.
export function toRaid(
  target: RaidTarget,
  startedAt: number,
  countdown = RAID_COUNTDOWN_SECONDS
): Raid {
  return {
    id: `${target.id}-${startedAt}`,
    target_id: target.id,
    target_login: target.login,
    target_display_name: target.displayName,
    force_raid_now_seconds: countdown,
  };
}

// Keyed by type and raid id, like the agent did, so retries don't duplicate.
export function toRaidDocument(
  type: RaidEventType,
  fromBroadcasterId: string,
  raid: Raid,
  at: number,
  now = Date.now()
): MessageDoc {
  return {
    id: `${type}-${raid.id}`,
    data: {
      channelId: `twitch:${fromBroadcasterId}`,
      type,
      raid,
      timestamp: admin.firestore.Timestamp.fromMillis(at),
      expiresAt: admin.firestore.Timestamp.fromMillis(now + TWO_WEEKS),
    },
  };
}

// Maps a channel.raid notification out of the channel to its documents. Raids
// started outside the app (eg. from Twitch's UI) have no start event, so one
// is written just before the completion for the app to complete.
export function toRaidGoDocuments(
  fromBroadcasterId: string,
  pending: Raid | undefined | null,
  event: any,
  at: number,
  now = Date.now()
): MessageDoc[] {
  if (pending && pending.target_id === event.to_broadcaster_user_id) {
    return [toRaidDocument("raid_go_v2", fromBroadcasterId, pending, at, now)];
  }
  const raid = toRaid(
    {
      id: event.to_broadcaster_user_id,
      login: event.to_broadcaster_user_login,
      displayName: event.to_broadcaster_user_name,
    },
    at,
    0
  );
  return [
    toRaidDocument("raid_update_v2", fromBroadcasterId, raid, at, now),
    toRaidDocument("raid_go_v2", fromBroadcasterId, raid, at + 1, now),
  ];
}

function channelRef(broadcasterId: string) {
  return admin
    .firestore()
    .collection("channels")
    .doc(`twitch:${broadcasterId}`);
}

async function writeMessages(broadcasterId: string, messages: MessageDoc[]) {
  for (const message of messages) {
    try {
      await channelRef(broadcasterId)
        .collection("messages")
        .doc(message.id)
        .create(message.data);
    } catch (err: any) {
      // ALREADY_EXISTS: a retry of an event we've stored.
      if (err?.code !== 6) {
        throw err;
      }
    }
  }
}

// The raid in progress is kept on the channel so its completion and
// cancellation can reference it.
async function getPendingRaid(broadcasterId: string) {
  const channel = await channelRef(broadcasterId).get();
  return channel.get("outgoingRaid") as Raid | undefined | null;
}

async function setPendingRaid(broadcasterId: string, raid: Raid | null) {
  await channelRef(broadcasterId).set({ outgoingRaid: raid }, { merge: true });
}

export async function recordRaidStart(
  fromBroadcasterId: string,
  target: RaidTarget,
  startedAt: number
) {
  const raid = toRaid(target, startedAt);
  await writeMessages(fromBroadcasterId, [
    toRaidDocument("raid_update_v2", fromBroadcasterId, raid, startedAt),
  ]);
  await setPendingRaid(fromBroadcasterId, raid);
}

export async function recordRaidGo(event: any, at: number, messageId: string) {
  const fromBroadcasterId = event.from_broadcaster_user_id as string;
  const channel = await channelRef(fromBroadcasterId).get();
  // the pending raid is cleared once it's complete, so redeliveries
  // (at-least-once) are skipped by message id instead.
  if (channel.get("outgoingRaidMessageId") === messageId) {
    return;
  }
  const pending = channel.get("outgoingRaid") as Raid | undefined | null;
  await writeMessages(
    fromBroadcasterId,
    toRaidGoDocuments(fromBroadcasterId, pending, event, at)
  );
  await channelRef(fromBroadcasterId).set(
    { outgoingRaid: null, outgoingRaidMessageId: messageId },
    { merge: true }
  );
}

export async function recordRaidCancel(fromBroadcasterId: string, at: number) {
  const pending = await getPendingRaid(fromBroadcasterId);
  if (!pending) {
    return;
  }
  await writeMessages(fromBroadcasterId, [
    toRaidDocument("raid_cancel_v2", fromBroadcasterId, pending, at),
  ]);
  await setPendingRaid(fromBroadcasterId, null);
}
