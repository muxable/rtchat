import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "cross-fetch";
import { getAppAccessToken, TWITCH_CLIENT_ID } from "./oauth";
import { AccessToken } from "simple-oauth2";

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

async function twitchLoginsToUserIds(token: AccessToken, logins: string[]) {
  const twitchChannelIds: string[] = [];
  for (let i = 0; i < logins.length; i += 100) {
    const query = logins
      .slice(i, i + 100)
      .map((id) => "login=" + encodeURIComponent(id))
      .join("&");
    const response = await fetch(`https://api.twitch.tv/helix/users?${query}`, {
      headers: {
        "Client-ID": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${token.token.access_token}`,
      },
    });
    const json = await response.json();
    if (json["data"]) {
      twitchChannelIds.push(...json["data"].map((user: any) => user["id"]));
    }
  }
  return twitchChannelIds;
}

async function twitchGetFollowerCount(token: AccessToken, channelId: string) {
  const response = await fetch(
    `https://api.twitch.tv/helix/users/follows?to_id=${channelId}&first=1`,
    {
      headers: {
        "Client-ID": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${token.token.access_token}`,
      },
    }
  );
  const json = await response.json();
  return json["total"];
}

async function twitchGetViewerCounts(token: AccessToken, channelIds: string[]) {
  const data: {
    [channelId: string]: {
      viewerCount: number;
      language: string;
      displayName: string;
      startedAt: Date | null;
    };
  } = {};
  for (let i = 0; i < channelIds.length; i += 100) {
    const batch = channelIds.slice(i, i + 100);
    const query = batch
      .map((channelId) => "user_id=" + encodeURIComponent(channelId))
      .join("&");
    const response = await fetch(
      `https://api.twitch.tv/helix/streams?first=100&${query}`,
      {
        headers: {
          "Client-ID": TWITCH_CLIENT_ID,
          Authorization: `Bearer ${token.token.access_token}`,
        },
      }
    );
    const json = await response.json();
    if (!json["data"]) {
      continue;
    }
    for (const stream of json["data"]) {
      const channelId = stream["user_id"];
      const displayName = stream["user_name"];
      const startedAt = new Date(Date.parse(stream["started_at"]));
      const viewerCount = stream["viewer_count"];
      const language = stream["language"];
      data[channelId] = { viewerCount, language, displayName, startedAt };
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
      if (!json["data"]) {
        continue;
      }
      for (const channel of json["data"]) {
        const channelId = channel["broadcaster_id"];
        const language = channel["broadcaster_language"];
        const displayName = channel["broadcaster_name"];
        data[channelId] = {
          viewerCount: 0,
          language,
          displayName,
          startedAt: null,
        };
      }
    }
  }
  return data;
}

export async function runUpdateFollowerAndViewerCount(
  token: AccessToken,
  channelIds: string[]
) {
  const updateBatch = admin.firestore().batch();

  // for each batch, fetch the viewer count
  const data = await twitchGetViewerCounts(token, channelIds);
  for (const [
    channelId,
    { viewerCount, language, displayName, startedAt },
  ] of Object.entries(data)) {
    console.log(
      "updating",
      channelId,
      viewerCount,
      language,
      displayName,
      startedAt
    );
    updateBatch.set(
      admin.firestore().collection("channels").doc(`twitch:${channelId}`),
      { viewerCount, language },
      { merge: true }
    );
  }

  // lastly, fetch the follower count for each channel individually.
  for (const channelId of channelIds) {
    const followerCount = await twitchGetFollowerCount(token, channelId);
    if (!followerCount) {
      continue;
    }
    console.log("updating", channelId, followerCount);
    updateBatch.set(
      admin.firestore().collection("channels").doc(`twitch:${channelId}`),
      { followerCount },
      { merge: true }
    );
  }

  // commit the update batch
  await updateBatch.commit();
}

export const updateFollowerAndViewerCount = functions.pubsub
  .schedule("*/2 * * * *") // every 2 minutes
  .onRun(async () => {
    // fetch the channels that have been active in the last 3 days.
    const snapshot = await admin.firestore().collection("assignments").get();
    const channels = snapshot.docs
      .map((doc) => doc.id)
      .filter((id) => id.startsWith("twitch:"))
      .map((id) => id.slice(7));
    // process twitch channel ids.
    const token = await getAppAccessToken("twitch");
    if (!token) {
      throw new functions.https.HttpsError("internal", "auth error");
    }

    // first, convert the channel logins to twitch channel ids.
    const channelIds = await twitchLoginsToUserIds(token, channels);
    runUpdateFollowerAndViewerCount(token, channelIds);
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
              Authorization: `Bearer ${token.token.access_token}`,
            },
          }
        );
        const profileJson = await profile.json();
        if (!profileJson["data"]?.length) {
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
          `https://tmi.twitch.tv/group/user/${login}/chatters`
        );
        const chattersJson = await chatters.json();
        return chattersJson["chatters"];
    }
  }
);
