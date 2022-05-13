import { AccessToken, AuthProvider } from "@twurple/auth";
import { ChatClient, LogLevel } from "@twurple/chat";
import { BasicPubSubClient, SingleUserPubSubClient } from "@twurple/pubsub";
import * as admin from "firebase-admin";
import fetch from "node-fetch";
import { ClientCredentials, Token } from "simple-oauth2";
import {
  FirebaseAdapter,
  getTwitchOAuthConfig,
  TWITCH_CLIENT_ID,
} from "../adapters/firebase";
import { log } from "../log";

const ACTION_MESSAGE_REGEX = /^\u0001ACTION ([^\u0001]+)\u0001$/;

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

function toAccessToken(token: Token): AccessToken {
  return {
    accessToken: token["access_token"],
    refreshToken: token["refresh_token"],
    scope: token["scope"],
    expiresIn: token["expires_in"],
    obtainmentTimestamp: +token["expires_at"] - token["expires_in"] * 1000,
  };
}

async function getAuthProvider(
  firebase: FirebaseAdapter,
  channel: string
): Promise<AuthProvider & { username: string; userId: string }> {
  const profile = await firebase.getProfile(channel);
  const credentials = profile
    ? await firebase.getCredentials(profile.id)
    : null;
  if (!profile || !credentials) {
    const bot = await firebase.getBot();
    const credentials = await firebase.getCredentials(bot.userId);
    if (!credentials) {
      throw new Error("missing bot credentials");
    }
    return {
      ...bot,
      clientId: TWITCH_CLIENT_ID,
      tokenType: "user",
      currentScopes: credentials["scope"],
      async getAccessToken(scopes?: string[]): Promise<AccessToken> {
        return toAccessToken(credentials);
      },
      async refresh(): Promise<AccessToken | null> {
        const credentials = await firebase.getCredentials(bot.userId);
        return credentials ? toAccessToken(credentials) : null;
      },
    };
  }
  return {
    username: channel,
    userId: profile.id,
    clientId: TWITCH_CLIENT_ID,
    tokenType: "user",
    currentScopes: credentials["scope"],
    async getAccessToken(scopes?: string[]): Promise<AccessToken> {
      return toAccessToken(credentials);
    },
    async refresh(): Promise<AccessToken | null> {
      const credentials = await firebase.getCredentials(profile.id);
      return credentials ? toAccessToken(credentials) : null;
    },
  };
}

function bunyanLogger(level: LogLevel, message: string) {
  switch (level) {
    case LogLevel.CRITICAL:
      log.fatal(message);
      break;
    case LogLevel.ERROR:
      log.error(message);
      break;
    case LogLevel.WARNING:
      log.warn(message);
      break;
    case LogLevel.INFO:
      log.info(message);
      break;
    case LogLevel.DEBUG:
      log.debug(message);
      break;
    case LogLevel.TRACE:
      log.trace(message);
      break;
    default:
      throw new Error("unexpected log level");
  }
}

async function join(
  firebase: FirebaseAdapter,
  agentId: string,
  channel: string
) {
  const authProvider = await getAuthProvider(firebase, channel);

  const chat = new ChatClient({
    authProvider,
    isAlwaysMod: authProvider.username === channel,
    logger: { custom: bunyanLogger, minLevel: LogLevel.WARNING },
  });

  chat.onDisconnect(async (manually) => {
    if (!manually) {
      log.info({ agentId, provider, channel }, "force disconnected");
      await firebase.forceRelease(provider, channel, agentId);
    }
  });

  const registerPromise = new Promise<void>((resolve) =>
    chat.onRegister(() => resolve())
  );

  chat.onMessage(async (channel, user, message, msg) => {
    const actionMessage = message.match(ACTION_MESSAGE_REGEX);
    const isAction = Boolean(actionMessage);
    if (!msg.channelId) {
      return;
    }
    log.info(
      {
        channelId: msg.channelId,
        channel,
        messageId: msg.id,
        message,
      },
      "adding message"
    );
    const tags = Object.fromEntries(msg.tags);
    const badges = tags["badges"]
      .split(",")
      .map((badge) => badge.split("/") as [string, string]);
    const reply = tags["reply-parent-msg-id"]
      ? {
          messageId: tags["reply-parent-msg-id"],
          displayName: tags["reply-parent-display-name"],
          userLogin: tags["reply-parent-user-login"],
          userId: tags["reply-parent-user-id"],
          message: tags["reply-parent-msg-body"],
        }
      : null;
    await firebase.getMessage(`twitch:${msg.id}`).set({
      channelId: `twitch:${msg.channelId}`,
      channel,
      type: "message",
      timestamp: admin.firestore.Timestamp.fromDate(msg.date),
      reply,
      // we have to shim some tags because the frontend still needs some of these.
      tags: {
        "user-id": tags["user-id"],
        "display-name": tags["display-name"],
        username: user,
        "room-id": tags["room-id"],
        color: tags["color"],
        "message-type": isAction ? "action" : "chat",
        "badges-raw": tags["badges"],
        "first-msg": tags["first-msg"],
        badges: {
          vip: badges.find((badge) => badge[0] === "vip") !== null,
          moderator: badges.find((badge) => badge[0] === "moderator") !== null,
        },
        "emotes-raw": tags["emotes"],
      },
      message,
    });
  });

  chat.onMessageRemove(async (channel, messageId, msg) => {
    const original = await firebase.getMessage(`twitch:${messageId}`).get();
    if (!original.exists) {
      log.error({ messageId, timestamp: msg.date }, "no message to delete");
      return;
    }
    await firebase.getMessage(`twitch:x-${messageId}`).set({
      channel,
      channelId: original.get("channelId"),
      type: "messagedeleted",
      timestamp: admin.firestore.Timestamp.fromDate(msg.date),
      messageId: `twitch:${messageId}`,
    });
  });

  chat.onChatClear(async (channel, msg) => {
    await firebase.getMessage(`twitch:clear-${msg.date.toISOString()}`).set({
      channel,
      channelId: `twitch:${msg.channelId}`,
      type: "clear",
    });
  });

  chat.onHosted(async (channel, hosterChannel, auto, viewers) => {
    // host messages don't have an associated timestamp so the best we can do is use the current date stamp.
    const timestamp = new Date();
    await firebase.getMessage(`twitch:host-${timestamp.toISOString()}`).set({
      channel: `#${channel}`,
      channelId: `twitch:${await getTwitchUserId(channel)}`,
      type: "host",
      displayName: hosterChannel,
      hosterChannelId: `twitch:${await getTwitchUserId(hosterChannel)}`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      viewers: viewers || 0, // includes the original I guess.
    });
  });

  log.info({ channel, agentId, provider }, "assigned to channel");
  await chat.connect();
  await registerPromise; // this is a bit awkward but the join will race if we don't wait.
  await chat.join(channel);
  log.info({ channel, agentId, provider }, "joined channel");

  if (authProvider.username === channel) {
    const basicpubsub = new BasicPubSubClient({
      logger: { custom: bunyanLogger, minLevel: LogLevel.WARNING },
    });
    basicpubsub.onDisconnect(async (manually) => {
      if (!manually) {
        log.info({ agentId, provider, channel }, "force disconnected");
        await firebase.forceRelease(provider, channel, agentId);
      }
    });
    const pubsub = new SingleUserPubSubClient({
      authProvider,
      pubSubClient: basicpubsub,
    });
    const raidListener = await pubsub.onCustomTopic("raid", async (message) => {
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

    await firebase.claim(provider, channel, agentId);

    await raidListener.remove();
  } else {
    await firebase.claim(provider, channel, agentId);
  }

  await chat.quit();

  log.info({ channel, agentId, provider }, "disconnected");
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
    await firebase.releaseAll(provider, channels, agentId);

    log.info({ agentId, provider }, "released all");

    // and wait for existing promises.
    await Promise.all(promises);

    log.info({ agentId, provider }, "close complete");
  };
}
