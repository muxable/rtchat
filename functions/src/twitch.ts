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
    }
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
  reason: string
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
    }
  );
  return await response.json();
}

// Helix DELETE endpoints respond with 204 No Content on success, which has no
// JSON body to parse.
async function parseResponse(response: {
  status: number;
  json(): Promise<any>;
}) {
  return response.status === 204 ? null : await response.json();
}

export async function unban(
  uid: string,
  broadcasterId: string,
  userId: string
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
    }
  );
  return await parseResponse(response);
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
    }
  );
  return await response.json();
}

// https://dev.twitch.tv/docs/api/reference/#send-chat-message
export async function sendChatMessage(
  uid: string,
  broadcasterId: string,
  message: string,
  replyParentMessageId?: string
): Promise<{ sent: boolean; error?: string; unauthorized?: boolean }> {
  const profile = await admin.firestore().collection("profiles").doc(uid).get();
  const senderId = profile.get("twitch")?.id;
  if (!senderId) {
    return { sent: false, error: "not signed in with twitch" };
  }
  const response = await fetch("https://api.twitch.tv/helix/chat/messages", {
    method: "POST",
    headers: await getHeaders(uid),
    body: JSON.stringify({
      broadcaster_id: broadcasterId,
      sender_id: senderId,
      message,
      ...(replyParentMessageId
        ? { reply_parent_message_id: replyParentMessageId }
        : {}),
    }),
  });
  // tokens from before user:write:chat was requested can't use the api.
  if (response.status === 401 || response.status === 403) {
    return { sent: false, unauthorized: true };
  }
  const json = (await response.json()) as any;
  const result = json?.data?.[0];
  if (result?.is_sent) {
    return { sent: true };
  }
  return {
    sent: false,
    error: result?.drop_reason?.message ?? json?.message ?? "failed to send",
  };
}

export async function clearChat(uid: string, broadcasterId: string) {
  const profile = await admin.firestore().collection("profiles").doc(uid).get();
  const moderatorId = profile.get("twitch")?.id;
  if (!moderatorId) {
    return;
  }
  const response = await fetch(
    `https://api.twitch.tv/helix/moderation/chat?broadcaster_id=${broadcasterId}&moderator_id=${moderatorId}`,
    {
      method: "DELETE",
      headers: await getHeaders(uid),
    }
  );
  return await parseResponse(response);
}

export async function deleteMessage(
  uid: string,
  broadcasterId: string,
  messageId: string
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
    }
  );
  return await parseResponse(response);
}

export async function raid(
  uid: string,
  fromBroadcasterId: string,
  toBroadcasterId: string
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
    }
  );
  return await response.json();
}
