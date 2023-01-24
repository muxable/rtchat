import * as crypto from "crypto";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "cross-fetch";
import { ClientCredentials } from "simple-oauth2";
import {
  getAppAccessToken,
  TWITCH_CLIENT_ID,
  TWITCH_CLIENT_SECRET,
  TWITCH_OAUTH_CONFIG,
} from "./oauth";
import { runUpdateFollowerAndViewerCount } from "./chat-status";

enum EventsubType {
  ChannelFollow = "channel.follow",
  ChannelSubscribe = "channel.subscribe",
  ChannelSubscriptionGift = "channel.subscription.gift",
  ChannelSubscriptionMessage = "channel.subscription.message",
  ChannelSubscriptionEnd = "channel.subscription.end",
  ChannelCheer = "channel.cheer",
  ChannelRaid = "channel.raid",
  ChannelBan = "channel.ban",
  ChannelUnban = "channel.unban",
  ChannelChannelPointsCustomRewardRedemptionAdd = "channel.channel_points_custom_reward_redemption.add",
  ChannelChannelPointsCustomRewardRedemptionUpdate = "channel.channel_points_custom_reward_redemption.update",
  ChannelPollBegin = "channel.poll.begin",
  ChannelPollProgress = "channel.poll.progress",
  ChannelPollEnd = "channel.poll.end",
  ChannelPredictionBegin = "channel.prediction.begin",
  ChannelPredictionProgress = "channel.prediction.progress",
  ChannelPredictionLock = "channel.prediction.lock",
  ChannelPredictionEnd = "channel.prediction.end",
  ChannelHypeTrainBegin = "channel.hype_train.begin",
  ChannelHypeTrainProgress = "channel.hype_train.progress",
  ChannelHypeTrainEnd = "channel.hype_train.end",
  ChannelUpdate = "channel.update",
  StreamOnline = "stream.online",
  StreamOffline = "stream.offline",
  ChannelShoutoutCreate = "channel.shoutout.create",
  ChannelShoutoutReceive = "channel.shoutout.receive",
}

function createEventsub(token: string, type: string, twitchUserId: string) {
  var condition: any = { broadcaster_user_id: twitchUserId };
  if (type === "channel.raid") {
    condition = { to_broadcaster_user_id: twitchUserId };
  } else if (
    type === "channel.shoutout.create" ||
    type === "channel.shoutout.receive"
  ) {
    condition = {
      broadcaster_user_id: twitchUserId,
      moderator_user_id: twitchUserId,
    };
  }
  const version =
    type === "channel.shoutout.create" || type === "channel.shoutout.receive"
      ? "beta"
      : "1";
  return fetch("https://api.twitch.tv/helix/eventsub/subscriptions", {
    method: "POST",
    headers: {
      "Client-ID": TWITCH_CLIENT_ID,
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      type,
      version: version,
      condition,
      transport: {
        method: "webhook",
        callback:
          "https://us-central1-rtchat-47692.cloudfunctions.net/eventsub",
        secret: TWITCH_CLIENT_SECRET,
      },
    }),
  });
}

export async function checkEventSubSubscriptions(userId: string) {
  const credentials = await new ClientCredentials(TWITCH_OAUTH_CONFIG).getToken(
    { scopes: [] }
  );
  const appAccessToken = credentials.token.access_token;
  const snapshot = await admin
    .database()
    .ref("userIds")
    .child("twitch")
    .orderByValue()
    .equalTo(userId)
    .get();
  const twitchUserId = Object.keys(snapshot.val() || {})[0];
  if (!twitchUserId) {
    console.log("missing twitch user id");
    return;
  }
  const promises = Object.values(EventsubType).map(async (type) => {
    // TODO: clean this up.
    let response = await createEventsub(appAccessToken, type, twitchUserId);
    if (response.status == 409) {
      // subscription already exists, this is ok.
      return;
    }
    const json = await response.json();
    console.log("subscribing to", type, twitchUserId);
    console.log(JSON.stringify(json));
  });
  await Promise.all(promises);
}

export const eventsub = functions.https.onRequest(async (req, res) => {
  const messageId = req.headers["twitch-eventsub-message-id"] as string;
  const timestamp = req.headers["twitch-eventsub-message-timestamp"] as string;
  const hmacMessage = messageId + timestamp + req.rawBody.toString("utf-8");
  const signature = crypto
    .createHmac("sha256", TWITCH_CLIENT_SECRET)
    .update(hmacMessage)
    .digest("hex");
  if (
    String(req.headers["twitch-eventsub-message-signature"]) !==
    `sha256=${signature}`
  ) {
    console.error(new Error("failed to match signature"));
    // res.status(403).send();
    // return;
  }
  console.log("/eventsub", JSON.stringify(req.body));

  const status = req.body?.subscription?.status;
  if (status === "webhook_callback_verification_pending") {
    res.setHeader("Content-Type", "text/plain; charset=utf-8");
    res.status(200).send(req.body.challenge);
    return;
  } else if (status === "enabled") {
    const type = req.body?.subscription?.type as EventsubType;

    const channelId = `twitch:${
      req.body.event["broadcaster_user_id"] ??
      req.body.event["to_broadcaster_user_id"]
    }`;

    const channelRef = admin.firestore().collection("channels").doc(channelId);

    const messageRef = channelRef
      .collection("messages")
      .doc(`twitch:${messageId}`);

    await messageRef.set({
      channelId,
      type,
      timestamp: admin.firestore.Timestamp.fromMillis(Date.parse(timestamp)),
      expiresAt: admin.firestore.Timestamp.fromMillis(
        Date.now() + 1000 * 86400 * 7 * 2
      ),
      event: req.body.event,
    });

    switch (type) {
      case EventsubType.StreamOnline:
        await channelRef.set(
          { onlineAt: admin.firestore.FieldValue.serverTimestamp() },
          { merge: true }
        );
        // process twitch channel ids.
        const token = await getAppAccessToken("twitch");
        if (!token) {
          throw new functions.https.HttpsError("internal", "auth error");
        }
        await runUpdateFollowerAndViewerCount(token, [channelId]);
        break;
      case EventsubType.StreamOffline:
        await channelRef.set({ onlineAt: null }, { merge: true });
        break;
      case EventsubType.ChannelFollow:
        // increment the follower count.
        try {
          await channelRef.update({
            followerCount: admin.firestore.FieldValue.increment(1),
          });
        } catch {}
        break;
      case EventsubType.ChannelUpdate:
        await channelRef.set(
          {
            login: req.body.event.broadcaster_user_login,
            displayName: req.body.event.broadcaster_user_name,
            title: req.body.event.title,
            language: req.body.event.language,
            categoryId: req.body.event.category_id,
            categoryName: req.body.event.category_name,
          },
          { merge: true }
        );
        break;
    }
  }
  res.status(200).send();
});
