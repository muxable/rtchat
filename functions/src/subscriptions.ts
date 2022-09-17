import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { checkEventSubSubscriptions } from "./eventsub";
import { getTwitchLogin } from "./twitch";

export const subscribe = functions.https.onCall(async (data, context) => {
  const provider = data?.provider;
  const channelId = data?.channelId;
  const translate = data?.translate;
  if (!provider || !channelId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId"
    );
  }

  if (translate) {
    await admin
      .database()
      .ref("translations")
      .child(provider)
      .child(channelId)
      .child(translate)
      .set(admin.database.ServerValue.TIMESTAMP);
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
        if (profile.exists) {
          const channelId = `twitch:${profile.get("twitch")["id"]}`;
          // update the metadata for this channel to indicate the last active time.
          await admin
            .firestore()
            .collection("metadata")
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
    const subscriptionLimit = Date.now() - 7 * 86400 * 1000;
    const subscriptionsRef = admin.database().ref("subscriptions");
    const subscriptions = await subscriptionsRef.get();
    const providers = (subscriptions.val() || {}) as {
      [provider: string]: { [channel: string]: number };
    };

    for (const [provider, channels] of Object.entries(providers)) {
      for (const [channel, timestamp] of Object.entries(channels)) {
        if (timestamp > subscriptionLimit) {
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

    const translationLimit = Date.now() - 86400 * 1000;
    const translationsRef = admin.database().ref("translations");
    const translations = await translationsRef.get();
    const translationsProviders = (translations.val() || {}) as {
      [provider: string]: { [channel: string]: { [language: string]: number } };
    };

    for (const [provider, channels] of Object.entries(translationsProviders)) {
      for (const [channel, languages] of Object.entries(channels)) {
        for (const [language, timestamp] of Object.entries(languages)) {
          if (timestamp > translationLimit) {
            continue;
          }

          await admin
            .database()
            .ref("translations")
            .child(provider)
            .child(channel)
            .child(language)
            .remove();
        }
      }
    }
  });

export const cleanup = functions.pubsub
  .schedule("*/6 * * * *") // every ten minutes
  .onRun(async (context) => {
    // delete up to 19200 records a day.
    const batch = admin.firestore().batch();
    const snapshot = await admin
      .firestore()
      .collection("messages")
      .where("timestamp", "<", new Date(Date.now() - 7 * 86400 * 1000))
      .orderBy("timestamp", "asc")
      .limit(80)
      .get();
    snapshot.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    functions.logger.info("deleted", snapshot.size, "messages");

    const claimRef = admin.database().ref("agents").child("twitch");

    const unclaimed = await claimRef.orderByValue().equalTo("").get();
    // log an error for any unclaimed agents. we don't want to delete them
    // because this might be a race condition/false positive but logging an
    // error will get reported.
    for (const channel of Object.keys(unclaimed.val() || {})) {
      functions.logger.error("unclaimed channel detected", channel);
    }
  });
