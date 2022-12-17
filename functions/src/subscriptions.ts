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

      // acquire a new assignment.
      await admin
        .firestore()
        .collection("assignments")
        .doc(`${provider}:${channel}`)
        .set({
          subscribedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

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
  .onRun(async () => {
    const limit = Date.now() - 7 * 86400 * 1000;
    const assignmentsRef = admin.firestore().collection("assignments");
    const assignments = await assignmentsRef.get();
    for (const assignment of assignments.docs) {
      const data = assignment.data();
      if (data.subscribedAt.toMillis() > limit) {
        // delete this doc
        await assignment.ref.delete();
      }
    }
  });
