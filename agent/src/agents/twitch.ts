import { AccessToken } from "@twurple/auth";
import { SingleUserPubSubClient, PubSubListener } from "@twurple/pubsub";
import * as admin from "firebase-admin";
import fetch from "node-fetch";
import { ClientCredentials, Token } from "simple-oauth2";
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
import { v4 as uuidv4 } from "uuid";

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
  if ((json.data || []).length === 0) {
    throw new Error("user not found " + username);
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
  username: string,
  token: Token
) {
  const twitch = new TwitchJs({
    username,
    token: token["access_token"],
    chat: {
      connectionTimeout: 5 * 1000,
      joinTimeout: 1000,
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
    ).catch((err) => {
      log.error(err);
    });
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
    ).catch((err) => {
      log.error(err);
    });
  });

  twitch.chat.on(TwitchJs.Chat.Events.CLEAR_CHAT, (message) => {
    (async () => {
      await firebase
        .getMessage(`twitch:clear-${message.timestamp.toISOString()}`)
        .set({
          channel: message.channel,
          channelId: `twitch:${await getTwitchUserId(message.channel)}`,
          type: "clear",
        });
    })().catch((err) => {
      log.error(err);
    });
  });

  twitch.chat.on(TwitchJs.Chat.Events.ALL, (message) => {
    if (message.event.startsWith("HOSTED/")) {
      addHost(
        firebase,
        message.channel.replace("#", ""),
        (message as any).tags.displayName,
        message.timestamp,
        (message as any).numberOfViewers || 0
      ).catch((err) => {
        log.error(err);
      });
    }
  });

  await twitch.chat.connect();

  return twitch.chat;
}

const agents: { [userId: string]: Promise<Chat> } = {};

type Agent = {
  userId: string;
  username: string;
  isBot: boolean;
  token: Token;
};

async function getAgent(
  firebase: FirebaseAdapter,
  channel: string
): Promise<Agent> {
  const profile = await firebase.getProfile(channel);
  const token = await firebase.getCredentials(channel);
  if (!profile || !token) {
    const bot = await firebase.getBot();
    const token = await firebase.getCredentials(bot.userId);
    if (!token) {
      throw new Error("no credentials for bot");
    }
    return { isBot: true, token, ...bot };
  }
  // validate the auth token we have for this user.
  const verify = await fetch("https://id.twitch.tv/oauth2/validate", {
    headers: { Authorization: `OAuth ${token["access_token"]}` },
  });
  if (verify.status != 200) {
    await firebase.clearCredentials(profile.id);
    await admin.auth().revokeRefreshTokens(profile.id);
    return await getAgent(firebase, channel);
  }
  return {
    userId: profile.id,
    username: profile.get("twitch")["login"] as string,
    isBot: false,
    token,
  };
}

async function join(
  firebase: FirebaseAdapter,
  agentId: string,
  channel: string
) {
  let raidListener: PubSubListener | null = null;
  const { username, userId, isBot, token } = await getAgent(firebase, channel);

  log.info({ username, userId, channel }, "getting chat agent");

  if (!agents[userId]) {
    agents[userId] = getChatAgent(firebase, username, token);
  }
  const chat = await agents[userId];
  log.info({ channel, agentId, provider }, "assigned to channel");
  await Promise.race([
    chat.join(channel),
    new Promise<void>((_, reject) =>
      setTimeout(() => reject("failed to join in time"), 1000)
    ),
  ]);

  if (!isBot) {
    const pubsub = new SingleUserPubSubClient({
      authProvider: {
        clientId: TWITCH_CLIENT_ID,
        tokenType: "user",
        currentScopes: [],
        getAccessToken: async (): Promise<AccessToken> => {
          return {
            accessToken: token["access_token"],
            refreshToken: token["refresh_token"],
            scope: token["scope"],
            expiresIn: token["expires_in"],
            obtainmentTimestamp:
              +token["expires_at"] - token["expires_in"] * 1000,
          };
        },
      },
    });
    raidListener = await pubsub.onCustomTopic("raid", async (message) => {
      const data = message.data as any;
      await firebase.setIfNotExists(
        `twitch:${data["type"]}-${data["raid"]["id"]}`,
        {
          channel,
          channelId: `twitch:${data["raid"]["source_id"]}`,
          ...data,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        }
      );
    });
  }

  log.info({ channel, agentId, provider }, "joined channel");

  chat.on(TwitchJs.Chat.Events.DISCONNECTED, async () => {
    log.info({ agentId, provider, channel }, "force disconnected");

    await firebase.releaseUnexpectedly(provider, channel);
  });

  // wait a random amount of time.
  // this allows for claims to be a little more uniformly distributed across agents instead
  // of being dominated by the slowest agent.
  await new Promise<void>((resolve) =>
    setTimeout(() => resolve(), 1000 * Math.random())
  );

  // mark us as the claimant.
  await firebase.claim(provider, channel, `${agentId}/${uuidv4()}`);

  log.info({ channel, agentId, provider }, "claim released");

  // when that promise completes, we should leave the channel because we are no longer assigned.
  await raidListener?.remove();
  chat.disconnect();

  log.info({ channel, agentId, provider }, "disconnected");

  delete agents[userId];
}

export async function runTwitchAgent(
  firebase: FirebaseAdapter,
  agentId: string
) {
  const provider = "twitch";

  const promises: Promise<void>[] = [];

  const channels = new Set<string>();

  const unsubscribe = firebase.onRequest(provider, (channel) => {
    if (channels.has(channel)) {
      // ignore duplicate request.
      log.info({ channel, agentId, provider }, "duplicate request");
      return;
    }
    channels.add(channel);
    promises.push(
      join(firebase, agentId, channel)
        .catch((e) => {
          log.error({ channel, agentId, provider }, e);
        })
        .finally(() => {
          channels.delete(channel);
        })
    );
  });

  return async () => {
    log.info({ agentId, provider }, "disconnecting");

    // stop listening for claims.
    unsubscribe();

    // release all matching this agent id.
    await firebase.releaseAll(provider, agentId);

    log.info({ agentId, provider }, "released all");

    // and wait for existing promises.
    await Promise.all(promises);

    log.info({ agentId, provider }, "close complete");
  };
}
