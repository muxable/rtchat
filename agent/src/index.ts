import * as admin from "firebase-admin";
import { Message, PubSub } from "@google-cloud/pubsub";
import * as dotenv from "dotenv";
import * as tmi from "tmi.js";
import Bottleneck from "bottleneck";
import * as process from "process";
import { v4 as uuidv4 } from "uuid";

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
});

async function subscribe(provider: string, channel: string) {
  switch (provider) {
    case "twitch":
      if (JOIN_BOTTLENECK.check()) {
        await JOIN_BOTTLENECK.schedule(() => TWITCH_CLIENT.join(channel));
        return true;
      }
  }
  return false; // not handled by this agent.
}

async function unsubscribe(provider: string, channel: string) {
  switch (provider) {
    case "twitch":
      TWITCH_CLIENT.part(channel);
      return true;
  }
  return false; // not handled by this agent.
}

async function onSubscribe(message: Message) {
  const { provider, channel } = JSON.parse(message.data.toString());
  if (await subscribe(provider, channel)) {
    console.log("successful subscribe", provider, channel);
    message.ack();
  } else {
    console.log("failed subscribe", provider, channel);
    message.nack();
  }
}

async function onUnsubscribe(message: Message) {
  const { provider, channel } = JSON.parse(message.data.toString());
  if (await unsubscribe(provider, channel)) {
    console.log("successful unsubscribe", provider, channel);
    message.ack();
  } else {
    console.log("failed unsubscribe", provider, channel);
    message.nack();
  }
}

const JOIN_TOPIC = new PubSub().topic("projects/rtchat-47692/topics/subscribe");

const JOIN_SUBSCRIPTION = JOIN_TOPIC.subscription(
  "projects/rtchat-47692/subscriptions/subscribe-sub"
);

JOIN_SUBSCRIPTION.on("message", onSubscribe);

const LEAVE_TOPIC = new PubSub().topic(
  "projects/rtchat-47692/topics/unsubscribe"
);

const AGENT_ID = uuidv4();
const LEAVE_SUBSCRIPTION_ID = `projects/rtchat-47692/subscriptions/unsubscribe-${AGENT_ID}`;

(async function () {
  const [subscription] = await LEAVE_TOPIC.createSubscription(
    LEAVE_SUBSCRIPTION_ID
  );

  subscription.on("message", onUnsubscribe);
})();

process.once("SIGTERM", async () => {
  JOIN_SUBSCRIPTION.off("message", onSubscribe);

  await LEAVE_TOPIC.subscription(LEAVE_SUBSCRIPTION_ID).delete();

  const twitch = TWITCH_CLIENT.getChannels().map((channel) =>
    JOIN_TOPIC.publish(
      Buffer.from(JSON.stringify({ provider: "twitch", channel }))
    )
  );

  await Promise.all(twitch);

  process.exit(0);
});
