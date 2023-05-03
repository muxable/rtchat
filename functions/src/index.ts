import fetch from "cross-fetch";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  alchemyWebhook,
  ethAlchemyWebhook,
  setRealTimeCashAddress,
} from "./alchemy_webhook";
import { app as authApp } from "./auth";
import { getBadges } from "./badges";
import { getViewerList, updateFollowerAndViewerCount } from "./chat-status";
import { getEmotes, getUserEmotes } from "./emotes";
import { eventsub } from "./eventsub";
import { getAccessToken, getAppAccessToken, TWITCH_CLIENT_ID } from "./oauth";
import { search } from "./search";
import { subscribe, unsubscribe } from "./subscriptions";
import { getVoices, synthesize } from "./tts";
import { getChannelId, getTwitchId, getTwitchLogin } from "./twitch";

async function write(
  channelId: string,
  targetChannel: string,
  message: string
) {
  const ref = await admin.firestore().collection("actions").add({
    channelId,
    targetChannel,
    message,
    sentAt: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  // wait for the message to be sent.
  const error = await new Promise<string | null>((resolve) =>
    ref.onSnapshot((snapshot) => {
      if (snapshot.get("isComplete")) {
        resolve(snapshot.get("error") || null);
      }
    })
  );
  return error;
}

export const send = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const message = data?.message;
  if (!provider || !channelId || !message) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, message"
    );
  }

  switch (provider) {
    case "twitch":
      const targetChannel = await getTwitchLogin(channelId);
      if (!targetChannel) {
        return;
      }
      const ref = data?.id
        ? admin.firestore().collection("actions").doc(String(data?.id))
        : admin.firestore().collection("actions").doc(); // optional idempotency key
      const senderChannelId = await getChannelId(context.auth.uid, "twitch");
      await admin.firestore().runTransaction(async (transaction) => {
        const doc = await transaction.get(ref);
        if (doc.exists) {
          return;
        }
        transaction.set(ref, {
          channelId: senderChannelId,
          targetChannel,
          message,
          sentAt: null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      // wait for the message to be sent.
      return await new Promise<string | null>((resolve) =>
        ref.onSnapshot((snapshot) => {
          if (snapshot.get("isComplete")) {
            resolve(snapshot.get("error") || null);
          }
        })
      );
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const ban = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const username = data?.username;
  if (!provider || !channelId || !username) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, username"
    );
  }

  switch (provider) {
    case "twitch":
      const profile = await admin
        .firestore()
        .collection("profiles")
        .doc(context.auth.uid)
        .get();
      if (!profile.exists) {
        return;
      }
      const moderatorId = profile.get("twitch")?.id;
      if (!moderatorId) {
        return;
      }
      const token = await getAccessToken(context.auth.uid, "twitch");
      const response = await fetch(
        `https://api.twitch.tv/helix/moderation/bans?broadcaster_id=${channelId}&moderator_id=${moderatorId}`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token}`,
            "Client-ID": TWITCH_CLIENT_ID,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            data: {
              user_id: await getTwitchId(username),
            },
          }),
        }
      );
      return await response.json();
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const unban = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const username = data?.username;
  if (!provider || !channelId || !username) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, username"
    );
  }

  switch (provider) {
    case "twitch":
      const profile = await admin
        .firestore()
        .collection("profiles")
        .doc(context.auth.uid)
        .get();
      if (!profile.exists) {
        return;
      }
      const moderatorId = profile.get("twitch")?.id;
      if (!moderatorId) {
        return;
      }
      const token = await getAccessToken(context.auth.uid, "twitch");
      const userId = await getTwitchId(username);
      const response = await fetch(
        `https://api.twitch.tv/helix/moderation/bans?broadcaster_id=${channelId}&moderator_id=${moderatorId}&user_id=${userId}`,
        {
          method: "DELETE",
          headers: {
            Authorization: `Bearer ${token}`,
            "Client-ID": TWITCH_CLIENT_ID,
          },
        }
      );
      return await response.json();
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const timeout = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const username = data?.username;
  const length = data?.length;
  const reason = data?.reason;
  if (!provider || !channelId || !username || !length || !reason) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, username, length, reason"
    );
  }

  switch (provider) {
    case "twitch":
      const profile = await admin
        .firestore()
        .collection("profiles")
        .doc(context.auth.uid)
        .get();
      if (!profile.exists) {
        return;
      }
      const moderatorId = profile.get("twitch")?.id;
      if (!moderatorId) {
        return;
      }
      const token = await getAccessToken(context.auth.uid, "twitch");
      const response = await fetch(
        `https://api.twitch.tv/helix/moderation/bans?broadcaster_id=${channelId}&moderator_id=${moderatorId}`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${token}`,
            "Client-ID": TWITCH_CLIENT_ID,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            data: {
              user_id: await getTwitchId(username),
              duration: length,
              reason,
            },
          }),
        }
      );
      return await response.json();
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const deleteMessage = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const messageId = data?.messageId;
  if (!provider || !channelId || !messageId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, messageId"
    );
  }

  switch (provider) {
    case "twitch":
      const targetChannel = await getTwitchLogin(channelId);
      if (!targetChannel) {
        return;
      }
      const response = await write(
        await getChannelId(context.auth.uid, "twitch"),
        targetChannel,
        `/delete ${messageId.substring("twitch:".length)}`
      );
      return response;
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const clear = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
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
      const targetChannel = await getTwitchLogin(channelId);
      if (!targetChannel) {
        return;
      }
      const response = await write(
        await getChannelId(context.auth.uid, "twitch"),
        targetChannel,
        `/clear`
      );
      return response;
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const getStatistics = functions.https.onCall(async (data, context) => {
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
      const token = await getAppAccessToken(provider);
      if (!token) {
        throw new functions.https.HttpsError("internal", "auth error");
      }
      const headers = {
        "Client-Id": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${token.token["access_token"]}`,
      };
      const viewerResponse = await fetch(
        `https://api.twitch.tv/helix/streams?user_id=${channelId}&first=1`,
        { headers }
      );
      const viewerJson = (await viewerResponse.json()) as any;
      const followerResponse = await fetch(
        `https://api.twitch.tv/helix/users/follows?to_id=${channelId}&first=1`,
        { headers }
      );
      const followerJson = (await followerResponse.json()) as any;
      const stream = viewerJson["data"][0];
      const languageResponse = await fetch(
        `https://api.twitch.tv/helix/channels?broadcaster_id=${channelId}`,
        { headers }
      );
      const languageJson = (await languageResponse.json()) as any;
      if (!stream) {
        return {
          isOnline: false,
          viewers: 0,
          followers: followerJson["total"],
          language: languageJson["data"][0]["broadcaster_language"],
        };
      }
      return {
        isOnline: true,
        viewers: stream["viewer_count"],
        followers: followerJson["total"],
        language: languageJson["data"][0]["broadcaster_language"],
      };
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const embedRedirect = functions.https.onRequest(async (req, res) => {
  const provider = req.query?.provider as string | null;
  const channelId = req.query?.channelId as string | null;
  if (!provider || !channelId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId"
    );
  }
  switch (provider) {
    case "twitch":
      const login = await getTwitchLogin(channelId);
      if (!login) {
        res.status(404).send("channel not found");
        return;
      }
      res.redirect(
        `https://player.twitch.tv/?channel=${login}&controls=false&parent=chat.rtirl.com&muted=true`
      );
      break;
    default:
      throw new functions.https.HttpsError(
        "invalid-argument",
        "invalid provider"
      );
  }
});

async function validate(
  provider: string,
  token: string
): Promise<{ clientId: string; docId: string } | null> {
  switch (provider) {
    case "twitch":
      // make sure the token is valid
      const response = await fetch("https://id.twitch.tv/oauth2/validate", {
        headers: {
          Authorization: `OAuth ${token}`,
        },
      });
      const json = await response.json();
      if (!json["client_id"]) {
        return null;
      }
      return {
        clientId: json["client_id"],
        docId: `twitch:${json["user_id"]}`,
      };
  }
  return null;
}

const CLIENT_IDS: { [id: string]: string } = {};

export const metadata = functions.https.onRequest(async (req, res) => {
  // make sure this is a post request.
  if (req.method !== "POST") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "only POST requests are allowed"
    );
  }
  const { key, value, token, provider } = req.body;
  if (!key || !value || !token || !provider) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing key, value, token, or provider"
    );
  }
  const data = await validate(provider, token);
  if (!data) {
    throw new functions.https.HttpsError("unauthenticated", "invalid token");
  }
  if (!CLIENT_IDS[data.clientId]) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "client id not registered, contact kevin@muxable.com"
    );
  }
  await admin
    .firestore()
    .collection("channels")
    .doc(data.docId)
    .collection("third-party")
    .add({
      key,
      value,
      clientId: data.clientId,
      name: CLIENT_IDS[data.clientId],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
});

export {
  subscribe,
  unsubscribe,
  eventsub,
  search,
  getUserEmotes,
  getEmotes,
  getBadges,
  synthesize,
  getVoices,
  getViewerList,
  setRealTimeCashAddress,
  alchemyWebhook,
  ethAlchemyWebhook,
  updateFollowerAndViewerCount,
};
export const auth = functions.https.onRequest(authApp);
