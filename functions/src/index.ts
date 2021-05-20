import { PubSub } from "@google-cloud/pubsub";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as tmi from "tmi.js";
import { app as authApp } from "./auth";
import { getAccessToken } from "./oauth";

admin.initializeApp({
  credential: admin.credential.cert(
    require("../rtchat-47692-firebase-adminsdk-ax5x8-9938439836.json")
  ),
  databaseURL: "https://rtchat-47692-default-rtdb.firebaseio.com",
});

export const subscribe = functions.https.onCall(async (data) => {
  const provider = data?.provider;
  const channel = data?.channel;
  if (!provider || !channel) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channel"
    );
  }

  const pubsub = new PubSub({ projectId: "rtchat-47692" });

  return await pubsub
    .topic("projects/rtchat-47692/topics/subscribe")
    .publish(Buffer.from(JSON.stringify({ provider, channel })));
});

export const unsubscribe = functions.https.onCall(async (data) => {
  const provider = data?.provider;
  const channel = data?.channel;
  if (!provider || !channel) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channel"
    );
  }

  return {};
});

async function getTwitchClient(uid: string, channel: string) {
  const token = await getAccessToken(uid, "twitch");

  const usernameDoc = await admin
    .firestore()
    .collection("profiles")
    .doc(uid)
    .get();

  const username = usernameDoc.get("twitch")["login"];
  const identity = { username, password: `oauth:${token}` };
  const client = new tmi.Client({
    channels: [channel],
    identity,
  });
  await client.connect();
  return client;
}

export const send = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channel = data?.channel;
  const message = data?.message;
  if (!provider || !channel || !message) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channel, message"
    );
  }

  switch (provider) {
    case "twitch":
      const client = await getTwitchClient(context.auth.uid, channel);
      return await client.say(channel, message);
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const ban = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channel = data?.channel;
  const username = data?.username;
  const reason = data?.reason;
  if (!provider || !channel || !username || !reason) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channel, username, reason"
    );
  }

  switch (provider) {
    case "twitch":
      const client = await getTwitchClient(context.auth.uid, channel);
      return await client.ban(channel, username, reason);
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const unban = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channel = data?.channel;
  const username = data?.username;
  if (!provider || !channel || !username) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channel, username"
    );
  }

  switch (provider) {
    case "twitch":
      const client = await getTwitchClient(context.auth.uid, channel);
      return await client.unban(channel, username);
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const timeout = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channel = data?.channel;
  const username = data?.username;
  const length = data?.length;
  const reason = data?.reason;
  if (!provider || !channel || !username || !length || !reason) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channel, username, length, reason"
    );
  }

  switch (provider) {
    case "twitch":
      const client = await getTwitchClient(context.auth.uid, channel);
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
  const channel = data?.channel;
  const messageId = data?.messageId;
  if (!provider || !channel || !messageId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channel, messageId"
    );
  }

  switch (provider) {
    case "twitch":
      const client = await getTwitchClient(context.auth.uid, channel);
      await client.connect();
      return await client.deletemessage(channel, messageId);
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const auth = functions.https.onRequest(authApp);
