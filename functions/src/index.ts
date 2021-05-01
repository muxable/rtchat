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

export const auth = functions.https.onRequest(authApp);
