import * as admin from "firebase-admin";
import { Message, PubSub } from "@google-cloud/pubsub";
import * as dotenv from "dotenv";
import * as tmi from "tmi.js";
import Bottleneck from "bottleneck";
import * as process from "process";

dotenv.config();
admin.initializeApp();

const TWITCH_CLIENT = new tmi.Client({
  connection: { reconnect: true },
  channels: [],
});

TWITCH_CLIENT.connect();

TWITCH_CLIENT.on("message", async (channel, tags, message) => {
  const unix = tags["tmi-sent-ts"];

  const seconds = Number(unix.substring(0, unix.length - 3));
  const nanoseconds = Number(unix.substring(unix.length - 3));

  const timestamp = new admin.firestore.Timestamp(seconds, nanoseconds);

  console.log(channel, tags, message);

  await admin
    .firestore()
    .collection("messages")
    .doc(`twitch:${tags.id}`)
    .set({
      channel: `twitch:${channel.substring(1)}`,
      timestamp,
      tags,
      message,
    });
});

const JOIN_BOTTLENECK = new Bottleneck({
  maxConcurrent: 50,
  minTime: 15 * 1000,
  highWater: 0, // another agent will handle this request if we're blocked.
  strategy: Bottleneck.strategy.BLOCK,
});

async function subscribe(provider: string, channel: string) {
  switch (provider) {
    case "twitch":
      await JOIN_BOTTLENECK.schedule(() => TWITCH_CLIENT.join(channel));
      return true;
  }
  return false; // not handled by this agent.
}

const TOPIC = new PubSub().topic("projects/rtchat-47692/topics/subscribe");

TOPIC.subscription("projects/rtchat-47692/subscriptions/subscribe-sub").on(
  "message",
  async (message: Message) => {
    const { provider, channel } = JSON.parse(message.data.toString());
    if (await subscribe(provider, channel)) {
      message.ack();
    } else {
      message.nack();
    }
  }
);

process.once("SIGTERM", async () => {
  const twitch = TWITCH_CLIENT.getChannels().map((channel) =>
    TOPIC.publish(Buffer.from(JSON.stringify({ provider: "twitch", channel })))
  );

  await Promise.all(twitch);

  process.exit(0);
});
