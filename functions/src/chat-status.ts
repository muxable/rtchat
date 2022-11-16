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

export const updateFollowerAndViewerCount = functions.https.onRequest(
  async function (req, res) {
    // fetch the channels that have been active in the last 3 days.
    const snapshot = await admin
      .firestore()
      .collection("channels")
      .where("lastActiveAt", ">", new Date(Date.now() - 3 * 86400 * 1000))
      .get();
    const channelIds = snapshot.docs.map((doc) => doc.id);

    // process twitch channel ids.
    const token = await getAppAccessToken("twitch");
    if (!token) {
      throw new functions.https.HttpsError("internal", "auth error");
    }

    const twitchChannelIds = channelIds.filter((id) =>
      id.startsWith("twitch:")
    );

    // batch into groups of 100.
    const twitchChannelIdBatches = [];
    for (let i = 0; i < twitchChannelIds.length; i += 100) {
      twitchChannelIdBatches.push(
        twitchChannelIds.slice(i, i + 100).map((id) => id.slice(7))
      );
    }

    const updateBatch = admin.firestore().batch();

    // for each batch, fetch the viewer count
    for (const batch of twitchChannelIdBatches) {
      const query = batch
        .map((channelId) => "user_id=" + encodeURIComponent(channelId))
        .join("&");
      const response = await fetch(
        `https://api.twitch.tv/helix/streams?${query}`,
        {
          headers: {
            "Client-ID": TWITCH_CLIENT_ID,
            Authorization: `Bearer ${token.token.access_token}`,
          },
        }
      );
      const json = await response.json();
      for (const stream of json["data"]) {
        const channelId = `twitch:${stream["user_id"]}`;
        const viewerCount = stream["viewer_count"];
        const language = stream["language"];
        const doc = admin.firestore().collection("channels").doc(channelId);
        updateBatch.set(doc, { viewerCount, language }, { merge: true });
      }
      // find any channels that are not in the response and reissue a request to helix/channels
      const missingChannelIds = batch.filter(
        (channelId) =>
          !json["data"].some((stream: any) => stream["user_id"] === channelId)
      );
      if (missingChannelIds.length > 0) {
        const query = missingChannelIds
          .map((channelId) => "broadcaster_id=" + encodeURIComponent(channelId))
          .join("&");
        const response = await fetch(
          `https://api.twitch.tv/helix/channels?${query}`,
          {
            headers: {
              "Client-ID": TWITCH_CLIENT_ID,
              Authorization: `Bearer ${token.token.access_token}`,
            },
          }
        );
        const json = await response.json();
        for (const channel of json["data"]) {
          const channelId = `twitch:${channel["broadcaster_id"]}`;
          const viewerCount = 0;
          const language = channel["broadcaster_language"];
          const doc = admin.firestore().collection("channels").doc(channelId);
          updateBatch.set(doc, { viewerCount, language }, { merge: true });
        }
      }
    }

    // lastly, fetch the follower count for each channel individually.
    for (const channelId of twitchChannelIds) {
      const response = await fetch(
        `https://api.twitch.tv/helix/users/follows?to_id=${channelId.slice(
          7
        )}&first=1`,
        {
          headers: {
            "Client-ID": TWITCH_CLIENT_ID,
            Authorization: `Bearer ${token.token.access_token}`,
          },
        }
      );
      const json = await response.json();
      const doc = admin.firestore().collection("channels").doc(channelId);
      updateBatch.set(doc, { followerCount: json["total"] }, { merge: true });
    }

    // commit the update batch
    await updateBatch.commit();
  }
);

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
