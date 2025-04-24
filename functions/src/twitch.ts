import * as admin from "firebase-admin";
import fetch from "cross-fetch";
import { getAccessToken, getAppAccessToken, TWITCH_CLIENT_ID } from "./oauth";

// Twitch's API evolves so rapidly that it's not worth using a client like twurple.

export async function getChannelId(uid: string, provider: string) {
  const usernameDoc = await admin
    .firestore()
    .collection("profiles")
    .doc(uid)
    .get();

  return `${provider}:${usernameDoc.get(provider)["id"]}`;
}

export async function getTwitchLogin(id: string) {
  const token = await getAppAccessToken("twitch");

  if (!token) {
    return null;
  }

  const response = await fetch(`https://api.twitch.tv/helix/users?id=${id}`, {
    headers: {
      Authorization: `Bearer ${token.token["access_token"]}`,
      "Client-Id": TWITCH_CLIENT_ID,
    },
  });

  const json = (await response.json()) as any;

  if (!json || !json["data"] || json["data"].length == 0) {
    return null;
  }
  return json["data"][0]["login"] as string;
}

export async function getTwitchId(login: string) {
  const token = await getAppAccessToken("twitch");

  if (!token) {
    return null;
  }

  const response = await fetch(
    `https://api.twitch.tv/helix/users?login=${login}`,
    {
      headers: {
        Authorization: `Bearer ${token.token["access_token"]}`,
        "Client-Id": TWITCH_CLIENT_ID,
      },
    },
  );

  const json = (await response.json()) as any;

  if (!json || !json["data"] || json["data"].length == 0) {
    return null;
  }
  return json["data"][0]["id"] as string;
}

async function getHeaders(uid: string) {
  const token = await getAccessToken(uid, "twitch");
  return {
    Authorization: `Bearer ${token}`,
    "Client-ID": TWITCH_CLIENT_ID,
    "Content-Type": "application/json",
  };
}

export async function timeout(
  uid: string,
  broadcasterId: string,
  userId: string,
  length: number,
  reason: string,
) {
  const profile = await admin.firestore().collection("profiles").doc(uid).get();
  if (!profile.exists) {
    return;
  }
  const moderatorId = profile.get("twitch")?.id;
  if (!moderatorId) {
    return;
  }
  const response = await fetch(
    `https://api.twitch.tv/helix/moderation/bans?broadcaster_id=${broadcasterId}&moderator_id=${moderatorId}`,
    {
      method: "POST",
      headers: await getHeaders(uid),
      body: JSON.stringify({
        data: {
          user_id: userId,
          duration: length,
          reason,
        },
      }),
    },
  );
  return await response.json();
}

export async function unban(
  uid: string,
  broadcasterId: string,
  userId: string,
) {
  const profile = await admin.firestore().collection("profiles").doc(uid).get();
  if (!profile.exists) {
    return;
  }
  const moderatorId = profile.get("twitch")?.id;
  if (!moderatorId) {
    return;
  }
  const response = await fetch(
    `https://api.twitch.tv/helix/moderation/bans?broadcaster_id=${broadcasterId}&moderator_id=${moderatorId}&user_id=${userId}`,
    {
      method: "DELETE",
      headers: await getHeaders(uid),
    },
  );
  return await response.json();
}

export async function ban(uid: string, broadcasterId: string, userId: string) {
  const profile = await admin.firestore().collection("profiles").doc(uid).get();
  if (!profile.exists) {
    return;
  }
  const moderatorId = profile.get("twitch")?.id;
  if (!moderatorId) {
    return;
  }
  const response = await fetch(
    `https://api.twitch.tv/helix/moderation/bans?broadcaster_id=${broadcasterId}&moderator_id=${moderatorId}`,
    {
      method: "POST",
      headers: await getHeaders(uid),
      body: JSON.stringify({
        data: {
          user_id: userId,
        },
      }),
    },
  );
  return await response.json();
}

export async function deleteMessage(
  uid: string,
  broadcasterId: string,
  messageId: string,
) {
  const profile = await admin.firestore().collection("profiles").doc(uid).get();
  if (!profile.exists) {
    return;
  }
  const moderatorId = profile.get("twitch")?.id;
  if (!moderatorId) {
    return;
  }
  const response = await fetch(
    `https://api.twitch.tv/helix/moderation/chat?broadcaster_id=${broadcasterId}&moderator_id=${moderatorId}&message_id=${messageId}`,
    {
      method: "DELETE",
      headers: await getHeaders(uid),
    },
  );
  return await response.json();
}

export async function raid(
  uid: string,
  fromBroadcasterId: string,
  toBroadcasterId: string,
) {
  const profile = await admin.firestore().collection("profiles").doc(uid).get();
  if (!profile.exists) {
    return;
  }

  const response = await fetch(
    `https://api.twitch.tv/helix/raids?from_broadcaster_id=${fromBroadcasterId}&to_broadcaster_id=${toBroadcasterId}`,
    {
      method: "POST",
      headers: await getHeaders(uid),
    },
  );
  return await response.json();
}
