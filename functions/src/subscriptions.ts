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

      if (context.auth == null) {
        return channel;
      }

      // get the channel id associated with the profile
      const profile = await admin
        .firestore()
        .collection("profiles")
        .doc(context.auth.uid)
        .get();
      if (!profile.exists) {
        return channel;
      }

      functions.logger.info("updating last active time");

      // update the metadata for this channel to indicate the last active time.
      await profile.ref.update({
        lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (profile.get("twitch") && profile.get("twitch")["id"] == channelId) {
        functions.logger.info("checking eventsub subscriptions.");

        await checkEventSubSubscriptions(context.auth.uid);

        await admin
          .firestore()
          .collection("channels")
          .doc(`${provider}:${channelId}`)
          .update({
            lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        // if there are no messages logged, this is a new user.
        if (profile.get("lastActiveAt") == null) {
          functions.logger.info("new user, sending welcome message.");

          // send a welcome message as muxfd.
          // we must directly inject this because the room might be in follower/sub only mode.
          const messagesRef = admin
            .firestore()
            .collection("channels")
            .doc(`twitch:${channelId}`)
            .collection("messages");
          const baseData = {
            channelId: `twitch:${channelId}`,
            annotations: {
              isAction: false,
              isFirstTimeChatter: false,
            },
            author: {
              displayName: "muxfd",
              userId: "158394109",
              color: "",
            },
            reply: null,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            tags: {
              "user-id": "158394109",
              "room-id": "158394109",
              "display-name": "muxfd",
              color: "",
              username: "muxfd",
              badges: {},
              "emotes-raw": "",
              "badges-raw": "",
            },
            type: "message",
          };
          await messagesRef.add({
            message: `Welcome to RealtimeChat, @${channel}! VoHiYo`,
            expiresAt: new Date(Date.now() + 2 * 7 * 86400 * 1000),
            ...baseData,
          });
          await new Promise((resolve) => setTimeout(resolve, 3000));
          await messagesRef.add({
            message: `Your chat will appear here, even if you close the app. Have a good stream!`,
            expiresAt: new Date(Date.now() + 2 * 7 * 86400 * 1000),
            ...baseData,
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
      // ignore twitch:muxfd
      if (assignment.id === "twitch:muxfd") {
        continue;
      }
      const data = assignment.data();
      if (data.subscribedAt.toMillis() < limit) {
        // delete this doc
        await assignment.ref.delete();
      }
    }
  });
