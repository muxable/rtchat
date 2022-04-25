import { PubSubClient, PubSubListener } from "@twurple/pubsub";
import * as admin from "firebase-admin";
import fetch from "node-fetch";
import { ClientCredentials } from "simple-oauth2";
import TwitchJs, {
  Chat,
  PrivateMessage,
  PrivateMessageWithBits,
} from "twitch-js";
import {
  FirebaseAdapter,
  getTwitchOAuthConfig,
  TWITCH_CLIENT_ID,
} from "../adapters/firebase";
import { log } from "../log";

const ACTION_MESSAGE_REGEX = /^\u0001ACTION ([^\u0001]+)\u0001$/;
const BADGES_RAW_REGEX = /badges=([^;]+);/;
const EMOTES_RAW_REGEX = /emotes=([^;]+);/;

function tmiJsEmotes(emotes: string) {
  if (emotes.length === 0) {
    return null;
  }
  const map: { [key: string]: string[] } = {};
  for (const block of emotes.split("/")) {
    const [key, value] = block.split(":");
    if (map[key]) {
      map[key].push(value);
    } else {
      map[key] = [value];
    }
  }
  return map;
}

function tmiJsTagsShim(
  message: PrivateMessage | PrivateMessageWithBits,
  isAction: boolean
) {
  const tags = message.tags;

  const badgesRaw = message._raw.match(BADGES_RAW_REGEX);
  const emotesRaw = message._raw.match(EMOTES_RAW_REGEX);

  return {
    "user-id": tags.userId,
    "display-name": tags.displayName,
    "room-id": tags.roomId,
    "message-type": isAction ? "action" : "chat",
    "badges-raw": badgesRaw ? badgesRaw[1] : null,
    "emote-only": tags.emoteOnly === "1",
    emotes: tmiJsEmotes(emotesRaw ? emotesRaw[1] : ""),
    "emotes-raw": emotesRaw ? emotesRaw[1] : null,
    // the frontend expects null color instead of an empty string. oops.
    color: tags.color == "" ? null : tags.color,
  };
}

async function getTwitchUserId(username: string): Promise<string> {
  const client = new ClientCredentials(await getTwitchOAuthConfig());
  const token = await client.getToken({});
  const res = await fetch(
    "https://api.twitch.tv/helix/users?login=" + username,
    {
      headers: {
        "Content-Type": "application/json",
        "Client-Id": TWITCH_CLIENT_ID,
        Authorization: "Bearer " + token.token["access_token"],
      },
    }
  );
  const json = await res.json();
  if (json.data.length === 0) {
    throw new Error("user not found");
  }
  return json.data[0]["id"];
}

const provider = "twitch";

async function addMessage(
  firebase: FirebaseAdapter,
  channelId: string,
  channel: string,
  messageId: string,
  message: string,
  timestamp: Date,
  tags: any
) {
  log.debug({ channelId, channel, messageId, message }, "adding message");
  await firebase.getMessage(`twitch:${messageId}`).set({
    channelId: `twitch:${channelId}`,
    channel,
    type: "message",
    timestamp: admin.firestore.Timestamp.fromDate(timestamp),
    tags,
    message,
  });
}

async function addHost(
  firebase: FirebaseAdapter,
  channel: string,
  displayName: string,
  timestamp: Date,
  viewers: number
) {
  await firebase.getMessage(`twitch:host-${timestamp.toISOString()}`).set({
    channel,
    channelId: `twitch:${await getTwitchUserId(channel)}`,
    type: "host",
    displayName,
    hosterChannelId: `twitch:${await getTwitchUserId(displayName)}`,
    timestamp: admin.firestore.Timestamp.fromDate(timestamp),
    viewers,
  });
}

async function deleteMessage(
  firebase: FirebaseAdapter,
  messageId: string,
  timestamp: Date,
  tags: any
) {
  const original = await firebase.getMessage(`twitch:${messageId}`).get();

  if (!original.exists) {
    log.error({ messageId, timestamp, tags }, "no message to delete");
    return;
  }

  await firebase.getMessage(`twitch:x-${messageId}`).set({
    channelId: original.get("channelId"),
    type: "messagedeleted",
    timestamp: admin.firestore.Timestamp.fromDate(timestamp),
    tags,
    messageId,
  });
}

/**
 * Gets the agent for a given channel. If we have a token (ie the user is actively signed in), we auth as that user. Otherwise, we auth as the bot user.
 * @param channel the channel to fetch an agent for
 */
async function getChatAgent(
  firebase: FirebaseAdapter,
  agentId: string,
  channel: string
) {
  const { username, userId, isBot } = await firebase.getAgent(channel);
  const token = await firebase.getCredentials(userId);

  log.info({ username, userId, channel }, "getting chat agent");

  const twitch = new TwitchJs({
    username,
    token: token["access_token"],
    onAuthenticationFailure: async () => {
      const token = await firebase.getCredentials(userId, true);
      log.warn({ agentId, provider: "twitch" }, "authentication failure");
      return token["access_token"];
    },
    chat: {
      connectionTimeout: 5 * 1000,
      joinTimeout: 3 * 1000,
    },
    log: { level: "warn" },
  });

  twitch.chat.on(TwitchJs.Chat.Events.PRIVATE_MESSAGE, (message) => {
    if (message.event !== TwitchJs.Chat.Commands.PRIVATE_MESSAGE) {
      return;
    }

    const actionMessage = message.message.match(ACTION_MESSAGE_REGEX);
    const isAction = Boolean(actionMessage);

    // strip off the action data.
    addMessage(
      firebase,
      message.tags.roomId,
      message.channel,
      message.tags.id,
      actionMessage ? actionMessage[1] : message.message,
      message.timestamp,
      {
        ...message.tags,
        isAction,
        ...tmiJsTagsShim(message, isAction),
      }
    );
  });

  twitch.chat.on(TwitchJs.Chat.Events.CLEAR_MESSAGE, (message) => {
    if (message.command !== TwitchJs.Chat.Commands.CLEAR_MESSAGE) {
      return;
    }
    deleteMessage(
      firebase,
      message.tags.targetMsgId,
      message.timestamp,
      message.tags
    );
  });

  twitch.chat.on(TwitchJs.Chat.Events.CLEAR_CHAT, async (message) => {
    await firebase
      .getMessage(`twitch:clear-${message.timestamp.toISOString()}`)
      .set({
        channel,
        channelId: `twitch:${await getTwitchUserId(channel)}`,
        type: "clear",
      });
  });

  twitch.chat.on(TwitchJs.Chat.Events.ALL, (message) => {
    if (message.event.startsWith("HOSTED/")) {
      addHost(
        firebase,
        message.channel,
        (message as any).tags.displayName,
        message.timestamp,
        (message as any).numberOfViewers || 0
      );
    }
  });

  await twitch.chat.connect();

  return { chat: twitch.chat, userId, isBot };
}

export async function runTwitchAgent(
  firebase: FirebaseAdapter,
  agentId: string
) {
  const agents: { [key: string]: Chat } = {};

  const raidListeners: { [key: string]: PubSubListener } = {};

  const pubsub = new PubSubClient();

  const unsubscribe = firebase.onAssignment(
    provider,
    agentId,
    async (channel) => {
      log.info({ channel, agentId, provider }, "assigned to channel");
      const { chat, userId, isBot } = await getChatAgent(
        firebase,
        agentId,
        channel
      );
      await Promise.race([
        chat.join(channel),
        new Promise<void>((_, reject) =>
          setTimeout(() => reject("failed to join in time"), 1000)
        ),
      ]);
      log.info({ channel, agentId, provider }, "joined channel");

      chat.on(TwitchJs.Chat.Events.DISCONNECTED, async () => {
        log.info({ agentId, provider }, "disconnected");

        await unsubscribe(channel);
      });

      agents[channel] = chat;

      if (!isBot) {
        pubsub.registerUserListener(
          {
            clientId: TWITCH_CLIENT_ID,
            tokenType: "user",
            currentScopes: [],
            getAccessToken: async () => {
              const token = await firebase.getCredentials(userId);
              return token["access_token"];
            },
          },
          userId
        );

        raidListeners[channel] = await pubsub.onCustomTopic(
          userId,
          "raid",
          async (message) => {
            const data = JSON.parse(
              (message.data as { message: string }).message
            );
            await firebase
              .getMessage(`twitch:${data["raid"]["id"]}-${+Date.now()}`)
              .set({
                channel,
                channelId: `twitch:${userId}`,
                ...data,
              });
          }
        );
      }
    },
    async (channel) => {
      const chat = agents[channel];
      if (!chat) {
        log.error(
          { channel, agentId, provider },
          "agent missing for unsubscribe"
        );
        return;
      }
      log.info({ channel, agentId, provider }, "unassigned from channel");

      await raidListeners[channel]?.remove();
      delete raidListeners[channel];

      await Promise.race([
        chat.part(channel),
        new Promise<void>((_, reject) =>
          setTimeout(() => reject("failed to part in time"), 1000)
        ),
      ]);
      log.info({ channel, agentId, provider }, "parted channel");
      chat.disconnect();
      delete agents[channel];
    },
    async (channel, message) => {
      const chat = agents[channel];
      if (!chat) {
        log.error({ channel, agentId, provider }, "agent missing for message");
        return;
      }
      log.info({ channel, agentId, provider }, "sending message");
      await chat.say(channel, message);
    }
  );

  return async () => {
    log.info({ agentId, provider }, "disconnecting");

    await unsubscribe();
  };
}
