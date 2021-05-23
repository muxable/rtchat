import { PubSub } from "@google-cloud/pubsub";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "node-fetch";
import { app as authApp } from "./auth";
import { getAccessToken, TWITCH_CLIENT_ID, TWITCH_CLIENT_ID } from "./oauth";
import { getTwitchClient, getTwitchLogin } from "./twitch";

admin.initializeApp({
  credential: admin.credential.cert(
    require("../rtchat-47692-firebase-adminsdk-ax5x8-9938439836.json")
  ),
  databaseURL: "https://rtchat-47692-default-rtdb.firebaseio.com",
});

export const subscribe = functions.https.onCall(async (data, context) => {
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

  const pubsub = new PubSub({ projectId: "rtchat-47692" });

  const channel = await getTwitchLogin(context.auth.uid, channelId);
  if (!channel) {
    return true;
  }
  // check if it's currently locked
  const lock = await admin
    .database()
    .ref("locks")
    .child(provider)
    .child(channel)
    .get();
  if (lock.exists()) {
    return true;
  }
  await pubsub
    .topic("projects/rtchat-47692/topics/subscribe")
    .publish(Buffer.from(JSON.stringify({ provider, channel })));
  return true;
});

export const unsubscribe = functions.https.onCall(async (data, context) => {
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

  return {};
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
      return await client.say(channel, message);
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
      return await client.ban(channel, username, reason);
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
      return await client.unban(channel, username);
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
      return await client.timeout(channel, username, length, reason);
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
      return await client.deletemessage(channel, messageId);
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const getViewerCount = functions.https.onCall(async (data, context) => {
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
      const response = await fetch(
        `https://api.twitch.tv/helix/streams?user_id=${channelId}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            "Client-Id": TWITCH_CLIENT_ID,
          },
        }
      );
      const json = await response.json();
      const stream = json["data"][0];
      if (!stream) {
        return 0;
      }
      return stream["viewer_count"];
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const auth = functions.https.onRequest(authApp);
