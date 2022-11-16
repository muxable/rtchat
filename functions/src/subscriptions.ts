import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { checkEventSubSubscriptions } from "./eventsub";
import { getTwitchLogin } from "./twitch";

export const subscribe = functions.https.onCall(async (data, context) => {
  const provider = data?.provider;
  const channelId = data?.channelId;
  if (!provider || !channelId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId"
    );
  }

  switch (provider) {
    case "twitch":
      const channel = await getTwitchLogin(channelId);
      if (!channel) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "invalid channel"
        );
      }

      functions.logger.info(
        context.auth?.uid,
        "subscribing to",
        provider,
        channel,
        channelId
      );

      // log the subscription.
      await admin
        .database()
        .ref("subscriptions")
        .child(provider)
        .child(channel)
        .set(admin.database.ServerValue.TIMESTAMP);

      // mark any existing agents for a disconnect. this cleans up any accidental zombie agents.
      await admin
        .database()
        .ref("connections")
        .child(provider)
        .child(channel)
        .remove();

      // acquire an agent. this might cause a reconnection but it's ok because
      // the user just opened the app.
      await admin
        .database()
        .ref("requests")
        .child(provider)
        .child(channel)
        .set(admin.database.ServerValue.TIMESTAMP);

      if (context.auth != null) {
        await checkEventSubSubscriptions(context.auth.uid);
        // get the channel id associated with the profile
        const profile = await admin
          .firestore()
          .collection("profiles")
          .doc(context.auth.uid)
          .get();
        if (profile.exists && profile.get("twitch")) {
          const channelId = `twitch:${profile.get("twitch")["id"]}`;
          // update the metadata for this channel to indicate the last active time.
          await admin
            .firestore()
            .collection("channels")
            .doc(channelId)
            .set(
              { lastActiveAt: admin.firestore.FieldValue.serverTimestamp() },
              { merge: true }
            );
          await profile.ref.update({
            lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }

      return channel;
  }
  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const unsubscribe = functions.pubsub
  .schedule("0 4 * * *") // daily at 4a
  .onRun(async (context) => {
    const limit = Date.now() - 7 * 86400 * 1000;
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
              .ref("connections")
              .child(provider)
              .child(channel)
              .set(null);

            await subscriptionsRef.child(provider).child(channel).set(null);
        }
      }
    }
  });
