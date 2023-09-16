import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "cross-fetch";
import { getAppAccessToken, getAccessToken, TWITCH_CLIENT_ID } from "./oauth";
import { AccessToken } from "simple-oauth2";

type UserData = {
  user_id: string;
  user_login: string;
  user_name: string;
};

async function findModerators(
  token: string,
  twitchBroadcasterId: string,
  twitchUserIds: string[]
) {
  const twitchChannelIds: UserData[] = [];
  for (let i = 0; i < twitchUserIds.length; i += 100) {
    const query = twitchUserIds
      .slice(i, i + 100)
      .map((id) => "user_id=" + encodeURIComponent(id))
      .join("&");
    const response = await fetch(
      `https://api.twitch.tv/helix/moderation/moderators?broadcaster_id=${twitchBroadcasterId}&${query}&first=100`,
      {
        headers: {
          "Client-ID": TWITCH_CLIENT_ID,
          Authorization: `Bearer ${token}`,
        },
      }
    );
    const json = await response.json();
    if (json["data"]) {
      twitchChannelIds.push(...json["data"]);
    }
  }
  return twitchChannelIds;
}

async function findVIPs(
  token: string,
  twitchBroadcasterId: string,
  twitchUserIds: string[]
) {
  const twitchChannelIds: UserData[] = [];
  for (let i = 0; i < twitchUserIds.length; i += 100) {
    const query = twitchUserIds
      .slice(i, i + 100)
      .map((id) => "user_id=" + encodeURIComponent(id))
      .join("&");
    const response = await fetch(
      `https://api.twitch.tv/helix/channels/vips?broadcaster_id=${twitchBroadcasterId}&${query}&first=100`,
      {
        headers: {
          "Client-ID": TWITCH_CLIENT_ID,
          Authorization: `Bearer ${token}`,
        },
      }
    );
    const json = await response.json();
    if (json["data"]) {
      twitchChannelIds.push(...json["data"]);
    }
  }
  return twitchChannelIds;
}

async function findChatters(
  token: string,
  twitchBroadcasterId: string,
  after = ""
): Promise<UserData[]> {
  const chatters = await fetch(
    `https://api.twitch.tv/helix/chat/chatters?broadcaster_id=${twitchBroadcasterId}&moderator_id=${twitchBroadcasterId}&first=1000&after=${after}`,
    {
      headers: {
        "Client-ID": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${token}`,
      },
    }
  );
  if (chatters.status !== 200) {
    throw new Error("Failed to fetch chatters");
  }
  const json = await chatters.json();
  if (json["data"]) {
    const chatters = json["data"];
    if (json["pagination"]["cursor"]) {
      chatters.push(
        ...(await findChatters(
          token,
          twitchBroadcasterId,
          json["pagination"]["cursor"]
        ))
      );
    }
    return chatters;
  }
  return [];
}

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
      }
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

export async function twitchGetChatters(
  twitchBroadcasterId: string,
  asUserId: string
) {
  const token = await getAccessToken(asUserId, "twitch");
  if (!token) {
    throw new functions.https.HttpsError("internal", "auth error");
  }
  // fetch the chatters for the requested channel.
  const chatters = await findChatters(token, twitchBroadcasterId);
  // find the moderators if possible
  let broadcaster: UserData[] = []; // this is historically an array by convention
  try {
    broadcaster = chatters.filter((c) => c.user_id == twitchBroadcasterId);
  } catch (e) {
    console.error(e);
  }
  broadcaster.sort((a, b) => a.user_name.localeCompare(b.user_name));
  let mods: UserData[] = [];
  try {
    mods = await findModerators(
      token,
      twitchBroadcasterId,
      chatters.map((c) => c.user_id)
    );
  } catch (e) {
    console.error(e);
  }
  mods.sort((a, b) => a.user_name.localeCompare(b.user_name));
  let vips: UserData[] = [];
  try {
    vips = await findVIPs(
      token,
      twitchBroadcasterId,
      chatters.map((c) => c.user_id)
    );
  } catch (e) {
    console.error(e);
  }
  vips.sort((a, b) => a.user_name.localeCompare(b.user_name));
  // remove mods and vips from the list of chatters.
  const viewers = chatters.filter(
    (c) =>
      !broadcaster.some((b) => b.user_id == c.user_id) &&
      !mods.some((m) => m.user_id == c.user_id) &&
      !vips.some((v) => v.user_id == c.user_id)
  );
  viewers.sort((a, b) => a.user_name.localeCompare(b.user_name));
  // for backwards compatibility, return the list of usernames as strings.
  // and return the full profile as <key>Data.
  return {
    broadcaster: broadcaster.map((c) => c.user_name),
    broadcasterData: broadcaster,
    viewers: viewers.map((c) => c.user_name),
    viewersData: viewers,
    moderators: mods.map((c) => c.user_name),
    moderatorsData: mods,
    vips: vips.map((c) => c.user_name),
    vipsData: vips,
  };
}

export async function runUpdateFollowerAndViewerCount(
  token: AccessToken,
  channelIds: string[]
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
      onlineAt
    );
    updateBatch.set(
      admin.firestore().collection("channels").doc(`twitch:${channelId}`),
      { viewerCount, language, login, displayName, onlineAt },
      { merge: true }
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
    twitchGetFollowerCount(token, channelId)
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
      { merge: true }
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
        // twitch's permission scheme is a little annoying here. we need an auth
        // token that represents the broadcaster, otherwise pretty much all the
        // calls will fail.
        //
        // so, we do this in three steps:
        // 1. fetch the user id corresponding to the requested channel and its token.
        //    if this fails, then use the user's token and we will not filter mods/vips.
        // 2. fetch the chatters for the requested channel.
        // 3. filter out mods/vips.
        const profile = await admin
          .firestore()
          .collection("profiles")
          .where("twitch.id", "==", channel)
          .get();
        if (!profile.empty) {
          try {
            return await twitchGetChatters(channel, profile.docs[0].id);
          } catch (e) {}
        }
        // channel is not in the database, use the authenticated user's token.
        return await twitchGetChatters(channel, context.auth.uid);
    }
    throw new functions.https.HttpsError("invalid-argument", "invalid channel");
  }
);
