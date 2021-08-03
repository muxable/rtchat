import { Message, PubSub } from "@google-cloud/pubsub";
import Bottleneck from "bottleneck";
import * as admin from "firebase-admin";
import fetch from "node-fetch";
import { v4 as uuidv4 } from "uuid";
import * as serviceAccount from "../service_account.json";
import { buildClient } from "./client";

const PROJECT_ID = serviceAccount.project_id;

admin.initializeApp({
  databaseURL: `https://${PROJECT_ID}-default-rtdb.firebaseio.com`,
});

const AGENT_ID = uuidv4();

console.log("running agent", AGENT_ID);

console.log(process.env);

(async function () {
  const CLIENTS = [await buildClient()];

  const JOIN_BOTTLENECK = new Bottleneck({
    maxConcurrent: 20,
    minTime: 10 * 1000,
  });

  async function isSubscribed(provider: string, channel: string) {
    switch (provider) {
      case "twitch":
        const response = await fetch(
          `https://tmi.twitch.tv/group/user/${channel}/chatters`
        );
        const json = await response.json();
        return Object.values(json["chatters"]).flat().includes("realtimechat"); // TODO: autodetermine bot username.
    }
    return false; // not handled by this agent.
  }

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

  async function onSubscribe(message: Message) {
    console.log("received subscribe message", message.data.toString());
    const { provider, channel } = JSON.parse(message.data.toString());
    // check if we already have a lock for this channel.
    try {
      if (await isSubscribed(provider, channel)) {
        console.log("channel already subscribed", provider, channel);
        message.ack();
        return;
      }
    } catch (err) {
      console.error(err);
      message.nack();
      return;
    }
    if (await subscribe(provider, channel)) {
      console.log("successful subscribe", provider, channel);
      message.ack();
    } else {
      console.log("failed subscribe", provider, channel);
      message.nack();
    }
  }

  async function onUnsubscribe(message: Message) {
    console.log("received unsubscribe message: " + message);
    const { provider, channel } = JSON.parse(message.data.toString());
    if (await unsubscribe(provider, channel)) {
      console.log("successful unsubscribe", provider, channel);
      message.ack();
    } else {
      console.log("failed unsubscribe", provider, channel);
      message.nack();
    }
  }

  const JOIN_TOPIC = new PubSub().topic(
    `projects/${PROJECT_ID}/topics/subscribe`
  );

  const JOIN_SUBSCRIPTION = JOIN_TOPIC.subscription(
    `projects/${PROJECT_ID}/subscriptions/subscribe-sub`
  );

  JOIN_SUBSCRIPTION.on("message", onSubscribe);

  const LEAVE_TOPIC = new PubSub().topic(
    `projects/${PROJECT_ID}/topics/unsubscribe`
  );

  const LEAVE_SUBSCRIPTION_ID = `projects/${PROJECT_ID}/subscriptions/unsubscribe-${AGENT_ID}`;

  (async function () {
    const [subscription] = await LEAVE_TOPIC.createSubscription(
      LEAVE_SUBSCRIPTION_ID
    );

    subscription.on("message", onUnsubscribe);
  })();

  async function cleanup() {
    JOIN_SUBSCRIPTION.off("message", onSubscribe);

    await LEAVE_TOPIC.subscription(LEAVE_SUBSCRIPTION_ID).delete();

    // stop subscribing.
    const channels = new Set<string>();
    for (const client of CLIENTS) {
      for (const channel of client.getChannels()) {
        channels.add(channel);
      }
      await client.disconnect();
    }
    for (const channel of Array.from(channels)) {
      const payload = JSON.stringify({
        provider: "twitch",
        channel: channel.substring(1),
      });
      await JOIN_TOPIC.publish(Buffer.from(payload));
    }

    process.exit(0);
  }

  process.on("SIGTERM", cleanup);
  process.on("uncaughtException", cleanup);
})();
