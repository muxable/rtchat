import { PubSub } from "@google-cloud/pubsub";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { checkEventSubSubscriptions } from "./eventsub";
import { getTwitchLogin } from "./twitch";

export const subscribe = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  if (!provider || !channelId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId"
    );
  }

  const pubsub = new PubSub({ projectId: "rtchat-47692" });

  switch (provider) {
    case "twitch":
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        return null;
      }
      // check if it's currently locked
      const lock = await admin
        .database()
        .ref("locks")
        .child(provider)
        .child(channel)
        .get();
      if (lock.exists()) {
        return channel;
      }
      await checkEventSubSubscriptions(context.auth.uid);
      await pubsub
        .topic("projects/rtchat-47692/topics/subscribe")
        .publish(Buffer.from(JSON.stringify({ provider, channel })));
      return channel;
  }
  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const unsubscribe = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  if (!provider || !channelId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId"
    );
  }

  return {};
});
