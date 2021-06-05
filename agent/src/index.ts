import * as admin from "firebase-admin";
import { Message, PubSub } from "@google-cloud/pubsub";
import * as dotenv from "dotenv";
import Bottleneck from "bottleneck";
import * as process from "process";
import { v4 as uuidv4 } from "uuid";
import { buildClient } from "./client";

dotenv.config();
admin.initializeApp({
  databaseURL: "https://rtchat-47692-default-rtdb.firebaseio.com",
});

const AGENT_ID = uuidv4();

console.log("running agent", AGENT_ID);

const CLIENTS = [buildClient(), buildClient()];

const JOIN_BOTTLENECK = new Bottleneck({
  maxConcurrent: 50,
  minTime: 15 * 1000,
});

async function subscribe(provider: string, channel: string) {
  switch (provider) {
    case "twitch":
      if (JOIN_BOTTLENECK.check()) {
        try {
          await JOIN_BOTTLENECK.schedule(async () => {
            for (const client of CLIENTS) {
              await client.join(channel);
            }
          });
        } catch (err) {
          console.error(err);
          return false;
        }
        return true;
      }
  }
  return false; // not handled by this agent.
}

async function unsubscribe(provider: string, channel: string) {
  switch (provider) {
    case "twitch":
      try {
        for (const client of CLIENTS) {
          await client.part(channel);
        }
      } catch (err) {
        console.error(err);
        return false;
      }
      return true;
  }
  return false; // not handled by this agent.
}

const locks = new Set<string>();

async function onSubscribe(message: Message) {
  const { provider, channel } = JSON.parse(message.data.toString());
  // attempt to lock the key.
  const key = `${provider}:${channel}`;
  const lockRef = admin.database().ref("locks").child(provider).child(channel);
  await lockRef.transaction(
    (current) => {
      if (!current) {
        return AGENT_ID;
      }
    },
    async (error, committed) => {
      if (error) {
        console.error(error);
      }
      if (!committed) {
        return;
      }
      if (await subscribe(provider, channel)) {
        console.log("successful subscribe", provider, channel);
        message.ack();
        locks.add(key);
      } else {
        console.log("failed subscribe", provider, channel);
        message.nack();
        await lockRef.set(null);
        locks.delete(key);
      }
    }
  );
}

async function onUnsubscribe(message: Message) {
  const { provider, channel } = JSON.parse(message.data.toString());
  const key = `${provider}:${channel}`;
  if (await unsubscribe(provider, channel)) {
    console.log("successful unsubscribe", provider, channel);
    message.ack();
    if (locks.has(key)) {
      const lockRef = admin
        .database()
        .ref("locks")
        .child(provider)
        .child(channel);
      await lockRef.set(null);
      locks.delete(key);
    }
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

  // release locks.
  for (const lock of Array.from(locks.values())) {
    const [provider, channel] = lock.split(":");
    await admin
      .database()
      .ref("locks")
      .child(provider)
      .child(channel)
      .set(null);
  }

  // stop subscribing.
  const channels = new Set<string>();
  for (const client of CLIENTS) {
    for (const channel of client.getChannels()) {
      channels.add(channel);
    }
  }
  for (const channel of Array.from(channels)) {
    const payload = JSON.stringify({
      provider: "twitch",
      channel: channel.substring(1),
    });
    await JOIN_TOPIC.publish(Buffer.from(payload));
  }

  process.exit(0);
});
