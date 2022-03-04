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

  console.log(context.auth.uid, "requested subscribe to", provider, channelId);

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

      // acquire an agent. this might cause a reconnection but it's ok because
      // the user just opened the app.
      await admin
        .database()
        .ref("agents")
        .child(provider)
        .child(channel)
        .set("");

      await checkEventSubSubscriptions(context.auth.uid);

      return channel;
  }
  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const unsubscribe = functions.pubsub
  .schedule("0 4 * * *") // daily at 4a
  .onRun(async (context) => {
    const limit = Date.now() - 3 * 86400 * 1000;
    const subscriptionsRef = admin.database().ref("subscriptions");
    const subscriptions = await subscriptionsRef.get();
    const providers = subscriptions.val() as {
      [provider: string]: { [channel: string]: number };
    };

    for (const [provider, channels] of Object.entries(providers)) {
      for (const [channel, timestamp] of Object.entries(channels)) {
        if (timestamp > limit) {
          continue;
        }

        switch (provider) {
          case "twitch":
            console.log("unsubscribing from", provider, channel);

            // release the agent.
            await admin
              .database()
              .ref("agents")
              .child(provider)
              .child(channel)
              .set(null);

            await subscriptionsRef.child(provider).child(channel).set(null);
        }
      }
    }
  });

export const cleanup = functions.pubsub
  .schedule("0 * */6 * *") // every ten minutes
  .onRun(async (context) => {
    // delete up to 19200 records a day.
    const batch = admin.firestore().batch();
    const snapshot = await admin
      .firestore()
      .collection("messages")
      .where("timestamp", "<", Date.now() - 7 * 86400 * 1000)
      .orderBy("timestamp", "asc")
      .limit(80)
      .get();
    snapshot.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  });
