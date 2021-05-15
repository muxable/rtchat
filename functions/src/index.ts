import { PubSub } from "@google-cloud/pubsub";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as tmi from "tmi.js";
import { app as authApp } from "./auth";

admin.initializeApp({
  credential: admin.credential.cert(
    require("../rtchat-47692-firebase-adminsdk-ax5x8-9938439836.json")
  ),
  databaseURL: "https://itsli7-87384.firebaseio.com",
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

export const send = functions.https.onCall(async (data) => {
  const provider = data?.provider;
  const channel = data?.channel;
  const message = data?.message;
  const identity = data?.identity;
  if (!provider || !channel || !message || !identity) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channel, message, or identity"
    );
  }

  switch (provider) {
    case "twitch":
      const client = new tmi.Client({ channels: [channel], identity });
      await client.connect();
      return await client.say(channel, message);
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const ban = functions.https.onCall(async (data) => {
  const provider = data?.provider;
  const channel = data?.channel;
  const username = data?.username;
  const reason = data?.reason;
  const identity = data?.identity;
  if (!provider || !channel || !username || !reason || !identity) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channel, username, reason, or identity"
    );
  }

  switch (provider) {
    case "twitch":
      const client = new tmi.Client({ channels: [channel], identity });
      await client.connect();
      return await client.ban(channel, username, reason);
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const unban = functions.https.onCall(async (data) => {
  const provider = data?.provider;
  const channel = data?.channel;
  const username = data?.username;
  const identity = data?.identity;
  if (!provider || !channel || !username || !identity) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channel, username, or identity"
    );
  }

  switch (provider) {
    case "twitch":
      const client = new tmi.Client({ channels: [channel], identity });
      await client.connect();
      return await client.unban(channel, username);
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const timeout = functions.https.onCall(async (data) => {
  const provider = data?.provider;
  const channel = data?.channel;
  const username = data?.username;
  const length = data?.length;
  const reason = data?.reason;
  const identity = data?.identity;
  if (!provider || !channel || !username || !length || !reason || !identity) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channel, username, length, reason, or identity"
    );
  }

  switch (provider) {
    case "twitch":
      const client = new tmi.Client({ channels: [channel], identity });
      await client.connect();
      return await client.timeout(channel, username, length, reason);
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const deleteMessage = functions.https.onCall(async (data) => {
  const provider = data?.provider;
  const channel = data?.channel;
  const messageId = data?.messageId;
  const identity = data?.identity;
  if (!provider || !channel || !messageId || !identity) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channel, messageId, or identity"
    );
  }

  switch (provider) {
    case "twitch":
      const client = new tmi.Client({ channels: [channel], identity });
      await client.connect();
      return await client.deletemessage(channel, messageId);
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const auth = functions.https.onRequest(authApp);
