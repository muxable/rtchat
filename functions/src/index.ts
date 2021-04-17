import { PubSub } from "@google-cloud/pubsub";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as tmi from "tmi.js";

admin.initializeApp();

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

export const send = functions.https.onRequest(async (req, res) => {
  const provider = req.body?.provider;
  const channel = req.body?.channel;
  const message = req.body?.message;
  const identity = req.body?.identity;
  if (!provider || !channel || !message || !identity) {
    res.status(400).send("missing provider, channel, message, or identity");
    return;
  }

  switch (provider) {
    case "twitch":
      const client = new tmi.Client({ channels: [channel], identity });
      await client.connect();
      res.status(200).send(await client.say(channel, message));
      return;
  }

  res.status(400).send("invalid provider");
});
