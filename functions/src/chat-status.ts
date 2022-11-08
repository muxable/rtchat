import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "cross-fetch";
import { getAppAccessToken, TWITCH_CLIENT_ID } from "./oauth";

async function getTwitchUserId(channel: string) {
  // fetch the twitch user id from the database based on login.
  const doc = await admin
    .firestore()
    .collection("profiles")
    .where("twitch.login", "==", channel)
    .limit(1)
    .get();
  if (doc.empty) {
    return null;
  }
  return doc.docs[0].data()["twitch"]["id"];
}

export const updateChatStatus = functions.pubsub
  .schedule("* * * * *") // every 1 minute
  .onRun(async () => {
    const promises: Promise<any>[] = [];
    // fetch the active connections from realtime database
    const connections =
      (await admin.database().ref("connections").once("value")).val() || {};
    for (const [provider, channels] of Object.entries(connections)) {
      for (const channel of Object.keys(channels as any)) {
        switch (provider) {
          case "twitch":
            const promise = fetch(
              `https://tmi.twitch.tv/group/user/${channel}/chatters`
            )
              .then((res) => res.json() as any)
              .then(async (json) => {
                return admin
                  .firestore()
                  .collection("chat-status")
                  .add({
                    provider,
                    channel,
                    channelId: `twitch:${await getTwitchUserId(channel)}`,
                    ...json["chatters"],
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                  });
              });
            promises.push(promise);
        }
      }
    }

    await Promise.all(promises);
  });

export const getViewerList = functions.https.onCall(
  async (channelId: string, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "must be authenticated"
      );
    }
    const [provider, channel] = channelId.split(":");
    switch (provider) {
      case "twitch":
        const token = await getAppAccessToken(provider);
        if (!token) {
          throw new functions.https.HttpsError("internal", "auth error");
        }
        // fetch the twitch login from the helix api
        const profile = await fetch(
          `https://api.twitch.tv/helix/users?id=${channel}`,
          {
            headers: {
              "Client-ID": TWITCH_CLIENT_ID,
              Authorization: `Bearer ${token}`,
            },
          }
        );
        const profileJson = await profile.json();
        if (profileJson["data"].length === 0) {
          throw new functions.https.HttpsError(
            "not-found",
            "channel not found"
          );
        }
        const login = profileJson["data"][0]["login"];
        if (!login) {
          throw new functions.https.HttpsError(
            "not-found",
            "channel not found"
          );
        }
        const chatters = await fetch(
          `https://tmi.twitch.tv/group/user/${channel}/chatters`
        );
        const chattersJson = await chatters.json();
        return chattersJson["chatters"];
    }
  }
);
