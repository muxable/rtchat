import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "node-fetch";
import * as serviceAccount from "../service_account.json";
import { app as authApp } from "./auth";
import { eventsub } from "./eventsub";
import { getAccessToken, TWITCH_CLIENT_ID } from "./oauth";
import { subscribe, unsubscribe } from "./subscriptions";
import { getTwitchClient, getTwitchLogin } from "./twitch";

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
  databaseURL: `https://${serviceAccount.project_id}-default-rtdb.firebaseio.com`,
});

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
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        return;
      }
      const client = await getTwitchClient(context.auth.uid, channelId);
      await client.connect();
      try {
        await await client.say(channel, message);
      } catch (err) {
        console.error(err);
      }
      return;
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
  const reason = data?.reason;
  if (!provider || !channelId || !username || !reason) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, username, reason"
    );
  }

  switch (provider) {
    case "twitch":
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        return;
      }
      const client = await getTwitchClient(context.auth.uid, channelId);
      await client.connect();
      try {
        await client.ban(channel, username, reason);
      } catch (err) {
        console.error(err);
      }
      return;
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
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        return;
      }
      const client = await getTwitchClient(context.auth.uid, channelId);
      await client.connect();
      try {
        await client.unban(channel, username);
      } catch (err) {
        console.error(err);
      }
      return;
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
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        return;
      }
      const client = await getTwitchClient(context.auth.uid, channelId);
      await client.connect();
      try {
        await client.timeout(channel, username, length, reason);
      } catch (err) {
        console.error(err);
      }
      return;
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
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        return;
      }
      const client = await getTwitchClient(context.auth.uid, channelId);
      await client.connect();
      try {
        await client.deletemessage(channel, messageId);
      } catch (err) {
        console.error(err);
      }
      return;
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
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        return;
      }
      const client = await getTwitchClient(context.auth.uid, channelId);
      await client.connect();
      try {
        await client.clear(channel);
      } catch (err) {
        console.error(err);
      }
      return;
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const getStatistics = functions.https.onCall(async (data, context) => {
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
      const token = await getAccessToken(context.auth.uid, "twitch");
      const headers = {
        "Client-Id": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${token}`,
      };
      const viewerResponse = await fetch(
        `https://api.twitch.tv/helix/streams?user_id=${channelId}&first=1`,
        { headers }
      );
      const viewerJson = await viewerResponse.json();
      const followerResponse = await fetch(
        `https://api.twitch.tv/helix/users/follows?to_id=${channelId}&first=1`,
        { headers }
      );
      const followerJson = await followerResponse.json();
      const stream = viewerJson["data"][0];
      if (!stream) {
        return {
          isOnline: false,
          viewers: 0,
          followers: followerJson["total"],
        };
      }
      return {
        isOnline: true,
        viewers: stream["viewer_count"],
        followers: followerJson["total"],
      };
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export { subscribe, unsubscribe, eventsub };
export const auth = functions.https.onRequest(authApp);
