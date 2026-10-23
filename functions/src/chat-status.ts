import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "cross-fetch";
import { getAppAccessToken, TWITCH_CLIENT_ID } from "./oauth";
import { AccessToken } from "simple-oauth2";

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
    `https://api.twitch.tv/helix/channels/followers?broadcaster_id=${channelId}&first=1`,
    {
      headers: {
        "Client-ID": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${token.token.access_token}`,
      },
    },
  );
  const json = await response.json();
  return json["total"];
}

async function twitchGetViewerCounts(token: AccessToken, channelIds: string[]) {
  const data: {
    [channelId: string]: {
      viewerCount: number;
      language: string;
      login: string;
      displayName: string;
      onlineAt: Date | null;
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
      },
    );
    const json = await response.json();
    if (!json["data"]) {
      continue;
    }
    for (const stream of json["data"]) {
      const channelId = stream["user_id"];
      const displayName = stream["user_name"];
      const onlineAt = new Date(Date.parse(stream["started_at"]));
      const viewerCount = stream["viewer_count"];
      const language = stream["language"];
      const login = stream["user_login"];
      data[channelId] = { viewerCount, language, login, displayName, onlineAt };
    }
    // find any channels that are not in the response and reissue a request to helix/channels
    const missingChannelIds = batch.filter(
      (channelId) =>
        !json["data"].some((stream: any) => stream["user_id"] === channelId),
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
        },
      );
      const json = await response.json();
      if (!json["data"]) {
        continue;
      }
      for (const channel of json["data"]) {
        const channelId = channel["broadcaster_id"];
        const language = channel["broadcaster_language"];
        const displayName = channel["broadcaster_name"];
        const login = channel["broadcaster_login"];
        data[channelId] = {
          viewerCount: 0,
          language,
          login,
          displayName,
          onlineAt: null,
        };
      }
    }
  }
  return data;
}

export async function runUpdateFollowerAndViewerCount(
  token: AccessToken,
  channelIds: string[],
) {
  let updateBatch = admin.firestore().batch();
  let batchSize = 0;

  // for each batch, fetch the viewer count
  const data = await twitchGetViewerCounts(token, channelIds);
  for (const [
    channelId,
    { viewerCount, language, login, displayName, onlineAt },
  ] of Object.entries(data)) {
    console.log(
      "updating",
      channelId,
      viewerCount,
      language,
      login,
      displayName,
      onlineAt,
    );
    updateBatch.set(
      admin.firestore().collection("channels").doc(`twitch:${channelId}`),
      { viewerCount, language, login, displayName, onlineAt },
      { merge: true },
    );
    if (++batchSize == 500) {
      console.log("committing batch");
      await updateBatch.commit();
      updateBatch = admin.firestore().batch();
      batchSize = 0;
    }
  }

  // shuffle and sample 200 channel ids to reduce the number of requests due to twitch rate limit
  for (let i = channelIds.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    const temp = channelIds[i];
    channelIds[i] = channelIds[j];
    channelIds[j] = temp;
  }
  channelIds = channelIds.slice(0, 200);

  // lastly, fetch the follower count for each channel individually.
  const followerCountRequests = channelIds.map((channelId) =>
    twitchGetFollowerCount(token, channelId),
  );
  for (let i = 0; i < channelIds.length; i++) {
    const channelId = channelIds[i];
    const followerCount = await followerCountRequests[i];
    if (!followerCount) {
      continue;
    }
    console.log("updating", channelId, followerCount);
    updateBatch.set(
      admin.firestore().collection("channels").doc(`twitch:${channelId}`),
      { followerCount },
      { merge: true },
    );
    if (++batchSize == 500) {
      console.log("committing batch");
      await updateBatch.commit();
      updateBatch = admin.firestore().batch();
      batchSize = 0;
    }
  }

  if (batchSize > 0) {
    console.log("committing batch");
    await updateBatch.commit();
  }
}

export const updateFollowerAndViewerCount = functions.pubsub
  .schedule("*/4 * * * *") // every 4 minutes
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
