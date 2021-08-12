import { PubSub } from "@google-cloud/pubsub";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { checkEventSubSubscriptions } from "./eventsub";
import { getTwitchLogin } from "./twitch";

const PROJECT_ID = "rtchat-47692";

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

  const pubsub = new PubSub({ projectId: PROJECT_ID });

  switch (provider) {
    case "twitch":
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "invalid channel"
        );
      }

      // log the subscription.
      await admin
        .database()
        .ref("subscriptions")
        .child(provider)
        .child(channel)
        .set(admin.database.ServerValue.TIMESTAMP);

      await checkEventSubSubscriptions(context.auth.uid);
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
      await pubsub
        .topic(`projects/${PROJECT_ID}/topics/subscribe`)
        .publish(Buffer.from(JSON.stringify({ provider, channel })));

      // acquire an agent if there's not already one.
      await admin
        .database()
        .ref("agents")
        .child(provider)
        .child(channel)
        .transaction((data) => {
          if (!data) {
            return "";
          }
          return;
        });

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

  const pubsub = new PubSub({ projectId: PROJECT_ID });

  switch (provider) {
    case "twitch":
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "invalid channel"
        );
      }

      // clear the subscription.
      await admin
        .database()
        .ref("subscriptions")
        .child(provider)
        .child(channel)
        .set(null);

      await pubsub
        .topic(`projects/${PROJECT_ID}/topics/unsubscribe`)
        .publish(Buffer.from(JSON.stringify({ provider, channel })));

      // release the agent.
      await admin
        .database()
        .ref("agents")
        .child(provider)
        .child(channel)
        .set(null);

      return channel;
  }
  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const unsubscribeCron = functions.pubsub
  .schedule("0 4 * * *") // daily at 4a
  .onRun(async (context) => {
    const limit = Date.now() - 7 * 86400 * 1000;
    const subscriptionsRef = admin.database().ref("subscriptions");
    const subscriptions = await subscriptionsRef.get();
    const providers = subscriptions.val() as {
      [provider: string]: { [channel: string]: number };
    };
    const pubsub = new PubSub({ projectId: PROJECT_ID });

    for (const [provider, channels] of Object.entries(providers)) {
      for (const [channel, timestamp] of Object.entries(channels)) {
        if (timestamp > limit) {
          continue;
        }

        switch (provider) {
          case "twitch":
            console.log("unsubscribing from", provider, channel);

            await pubsub
              .topic(`projects/${PROJECT_ID}/topics/unsubscribe`)
              .publish(Buffer.from(JSON.stringify({ provider, channel })));
            await subscriptionsRef.child(provider).child(channel).set(null);
        }
      }
    }
  });
