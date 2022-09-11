import {
  AccessToken,
  AuthProvider,
  RefreshingAuthProvider,
} from "@twurple/auth";
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
    "https://api.twitch.tv/helix/users?login=" + username.replace("#", ""),
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

function fromAccessToken(token: AccessToken): Token {
  return {
    access_token: token.accessToken,
    refresh_token: token.refreshToken,
    scope: token.scope,
    expires_in: token.expiresIn,
    expires_at:
      token.expiresIn == null
        ? null
        : new Date(token.obtainmentTimestamp + token.expiresIn * 1000),
  };
}

async function getChannelId(uid: string, provider: string) {
  const usernameDoc = await admin
    .firestore()
    .collection("profiles")
    .doc(uid)
    .get();

  return `${provider}:${usernameDoc.get(provider)["id"]}`;
}

async function getAuthProvider(
  firebase: FirebaseAdapter,
  channel: string
): Promise<{
  username: string;
  userId: string;
  providerId: string;
  provider: AuthProvider;
}> {
  const config = await getTwitchOAuthConfig();
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
      provider: new RefreshingAuthProvider(
        {
          clientId: config.client.id,
          clientSecret: config.client.secret,
          onRefresh: (token) =>
            firebase.setToken(bot.userId, fromAccessToken(token)),
        },
        toAccessToken(credentials)
      ),
    };
  }
  return {
    username: channel,
    userId: profile.id,
    providerId: profile.get("twitch.id"),
    provider: new RefreshingAuthProvider(
      {
        clientId: config.client.id,
        clientSecret: config.client.secret,
        onRefresh: (token) =>
          firebase.setToken(profile.id, fromAccessToken(token)),
      },
      toAccessToken(credentials)
    ),
  };
}

function bunyanLogger(context: any) {
  return function (level: LogLevel, message: string) {
    switch (level) {
      case LogLevel.CRITICAL:
        log.fatal(context, message);
        break;
      case LogLevel.ERROR:
        log.error(context, message);
        break;
      case LogLevel.WARNING:
        log.warn(context, message);
        break;
      case LogLevel.INFO:
        log.info(context, message);
        break;
      case LogLevel.DEBUG:
        log.debug(context, message);
        break;
      case LogLevel.TRACE:
        log.trace(context, message);
        break;
      default:
        throw new Error("unexpected log level");
    }
  };
}

const pubSubClients: [BasicPubSubClient, number][] = [];

function incrBasicPubSub(context: any) {
  const matchingClient = pubSubClients.find((ps) => ps[1] < 50);
  if (matchingClient) {
    matchingClient[1]++;
    return matchingClient[0];
  }
  const ps = new BasicPubSubClient({
    logger: {
      custom: bunyanLogger(context),
      minLevel: LogLevel.ERROR,
    },
  });
  pubSubClients.push([ps, 1]);
  return ps;
}

function decrBasicPubSub(ps: BasicPubSubClient) {
  const matchingClient = pubSubClients.find(([p]) => p === ps);
  if (!matchingClient) {
    throw new Error("unexpected pubsub client");
  }
  matchingClient[1]--;
}

const abortPromise = new Promise((_, reject) => {
  for (const signal of ["SIGINT", "SIGTERM"]) {
    process.once(signal, reject);
  }
});

async function join(
  firebase: FirebaseAdapter,
  agentId: string,
  channel: string,
  anonymous = false
): Promise<void> {
  const authProvider = anonymous
    ? undefined
    : await getAuthProvider(firebase, channel);

  const chat = new ChatClient({
    authProvider: authProvider?.provider,
    isAlwaysMod: authProvider?.username === channel,
    logger: {
      custom: bunyanLogger({ agentId, channel, provider }),
      minLevel: LogLevel.WARNING,
    },
  });

  const registerPromise = new Promise<void>((resolve) =>
    chat.onRegister(() => resolve())
  );

  const messagePromise = new Promise<void>((resolve) => {
    chat.onMessage(async (channel, user, message, msg) => {
      const actionMessage = message.match(ACTION_MESSAGE_REGEX);
      const isAction = Boolean(actionMessage);
      if (!msg.channelId) {
        return;
      }
      resolve();
      log.info(
        {
          agentId,
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
      await firebase.getMessage(`twitch:${msg.id}`).set({
        channelId: `twitch:${msg.channelId}`,
        channel,
        type: "message",
        timestamp: admin.firestore.Timestamp.fromDate(msg.date),
        reply: tags["reply-parent-msg-id"]
          ? {
              messageId: `twitch:${tags["reply-parent-msg-id"]}`,
              displayName: tags["reply-parent-display-name"],
              userLogin: tags["reply-parent-user-login"],
              userId: tags["reply-parent-user-id"],
              message: tags["reply-parent-msg-body"],
            }
          : null,
        author: {
          userId: tags["user-id"],
          displayName: tags["display-name"],
          login: tags["username"],
        },
        // we have to shim some tags because the frontend still needs some of these.
        tags: {
          "user-id": tags["user-id"],
          "display-name": tags["display-name"],
          username: user,
          "room-id": tags["room-id"],
          color: tags["color"],
          "message-type": isAction ? "action" : "chat",
          "badges-raw": tags["badges"],
          badges: {
            vip: badges.find((badge) => badge[0] === "vip") !== null,
            moderator:
              badges.find((badge) => badge[0] === "moderator") !== null,
          },
          "emotes-raw": tags["emotes"],
        },
        message,
        annotations: {
          isFirstTimeChatter: tags["first-msg"] === "1",
          isAction,
        },
      });
    });
  });

  chat.onAnnouncement(async (channel, user, announcement, msg) => {
    if (!msg.channelId) {
      return;
    }
    const message = msg.message.value;
    log.info(
      {
        channelId: msg.channelId,
        channel,
        agentId,
        provider,
        messageId: msg.id,
        message,
      },
      "adding message"
    );
    const tags = Object.fromEntries(msg.tags);
    const badges = tags["badges"]
      .split(",")
      .map((badge) => badge.split("/") as [string, string]);
    await firebase.getMessage(`twitch:${msg.id}`).set({
      channelId: `twitch:${msg.channelId}`,
      channel,
      type: "message",
      timestamp: admin.firestore.Timestamp.fromDate(msg.date),
      reply: tags["reply-parent-msg-id"]
        ? {
            messageId: `twitch:${tags["reply-parent-msg-id"]}`,
            displayName: tags["reply-parent-display-name"],
            userLogin: tags["reply-parent-user-login"],
            userId: tags["reply-parent-user-id"],
            message: tags["reply-parent-msg-body"],
          }
        : null,
      author: {
        userId: tags["user-id"],
        displayName: tags["display-name"],
        login: tags["username"],
      },
      // we have to shim some tags because the frontend still needs some of these.
      tags: {
        "user-id": tags["user-id"],
        "display-name": tags["display-name"],
        username: user,
        "room-id": tags["room-id"],
        color: tags["color"],
        "message-type": "chat",
        "badges-raw": tags["badges"],
        badges: {
          vip: badges.find((badge) => badge[0] === "vip") !== null,
          moderator: badges.find((badge) => badge[0] === "moderator") !== null,
        },
        "emotes-raw": tags["emotes"],
      },
      message,
      annotations: {
        announcement: { color: announcement.color },
        isFirstTimeChatter: tags["first-msg"] === "1",
      },
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
      timestamp: admin.firestore.Timestamp.fromDate(msg.date),
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

  chat.onR9k(async (channel, enabled) => {
    const userId = await getTwitchUserId(channel);
    await firebase.getMetadata(`twitch:${userId}`).set({ isR9k: enabled }, {merge: true});
  });

  chat.onEmoteOnly(async (channel, enabled) => {
    const userId = await getTwitchUserId(channel);
    await firebase
      .getMetadata(`twitch:${userId}`)
      .set({ isEmoteOnly: enabled }, { merge: true });
  });

  chat.onFollowersOnly(async (channel, enabled) => {
    const userId = await getTwitchUserId(channel);
    await firebase
      .getMetadata(`twitch:${userId}`)
      .set({ isFollowersOnly: enabled }, { merge: true });
  });

  chat.onSubsOnly(async (channel, enabled) => {
    const userId = await getTwitchUserId(channel);
    await firebase
      .getMetadata(`twitch:${userId}`)
      .set({ isSubsOnly: enabled }, { merge: true });
  });

  chat.onSlow(async (channel, enabled, seconds) => {
    const userId = await getTwitchUserId(channel);
    await firebase
      .getMetadata(`twitch:${userId}`)
      .set(
        { isSlowMode: enabled, slowModeSeconds: seconds },
        { merge: true }
      );
  });

  log.info({ channel, agentId, provider }, "assigned to channel");
  try {
    await chat.connect();
    await registerPromise; // this is a bit awkward but the join will race if we don't wait.
    await chat.join(channel);
  } catch (error) {
    if (!anonymous) {
      log.warn(
        { channel, agentId, provider, error },
        "failed to join, trying to join anonymously"
      );
      return join(firebase, agentId, channel, true);
    } else {
      log.error(
        { channel, agentId, provider, error },
        "permanently failed to join"
      );
    }
  }

  log.info({ channel, agentId, provider }, "joined channel");

  chat.onDisconnect(async (manually) => {
    if (!manually) {
      log.info({ agentId, provider, channel }, "force disconnected");
      await firebase.forceRelease(provider, channel, agentId);
    }
  });

  if (authProvider?.username === channel) {
    const send = new ChatClient({
      authProvider: authProvider?.provider,
      isAlwaysMod: authProvider.username === channel,
      logger: {
        custom: bunyanLogger({ agentId, channel, provider }),
        minLevel: LogLevel.WARNING,
      },
    });
    await send.connect();

    const pubSubClient = incrBasicPubSub({ agentId });

    const pubsub = new SingleUserPubSubClient({
      authProvider: authProvider?.provider,
      pubSubClient,
      logger: {
        custom: bunyanLogger({ agentId, channel, provider }),
        minLevel: LogLevel.WARNING,
      },
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

    // also listen to message send requests.
    const messageListener = admin
      .firestore()
      .collection("actions")
      .where("channelId", "==", `twitch:${authProvider.providerId}`)
      .where("sentAt", "==", null)
      .orderBy("createdAt", "desc")
      .onSnapshot(async (snapshot) => {
        for (const change of snapshot.docChanges()) {
          if (change.type != "added") {
            continue;
          }
          // verify that the user id matches the channel id.
          const userId = change.doc.get("userId");
          if (userId) {
            const channelId = await getChannelId(userId, "twitch");
            if (channelId != `twitch:${authProvider.providerId}`) {
              continue;
            }
          }
          const targetChannel = change.doc.get("targetChannel");
          const message = change.doc.get("message");
          if (!targetChannel || !message) {
            continue;
          }
          try {
            await admin.firestore().runTransaction(async (transaction) => {
              const doc = await transaction.get(change.doc.ref);
              if (doc.get("sentAt")) {
                return;
              }
              transaction.update(change.doc.ref, {
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            });
          } catch (error) {
            // transaction failed, probably because it was already sent.
            continue;
          }
          try {
            await send.say(targetChannel, message);
            await change.doc.ref.update({ isComplete: true });
          } catch (e: any) {
            log.error(
              { error: e, targetChannel, message },
              "error sending message"
            );
            await change.doc.ref.update({
              isComplete: true,
              error: e.message,
            });
          }
        }
      });

    // wait for at least one message before asserting a connection.
    try {
      log.info({ channel, agentId, provider }, "waiting for first message");
      await Promise.race([messagePromise, abortPromise]);
      log.info({ channel, agentId, provider }, "got first message");

      await firebase.claim(provider, channel, agentId);
    } catch (error) {
      log.error(
        { channel, agentId, provider, error },
        "failed to claim channel"
      );
    }

    messageListener();

    await raidListener.remove();

    decrBasicPubSub(pubSubClient);

    await send.quit();
  } else {
    // wait for at least one message before asserting a connection.
    try {
      log.info({ channel, agentId, provider }, "waiting for first message");
      await Promise.race([messagePromise, abortPromise]);
      log.info({ channel, agentId, provider }, "got first message");

      await firebase.claim(provider, channel, agentId);
    } catch (error) {
      log.error(
        { channel, agentId, provider, error },
        "failed to claim channel"
      );
    }
  }

  await chat.quit();

  log.info({ channel, agentId, provider }, "disconnected");
}

export async function runTwitchAgent(
  firebase: FirebaseAdapter,
  agentId: string
) {
  const provider = "twitch";

  const channels = new Map<string, Promise<void>>();

  let next = 0;

  const unsubscribe = firebase.onRequest(agentId, provider, async (channel) => {
    if (channels.has(channel)) {
      return;
    }

    const rateLimiter = new Promise<void>((resolve) => {
      const now = Date.now();
      if (next <= now) {
        next = now + 1000;
        resolve();
      } else {
        next += 1000;
        setTimeout(() => resolve(), next - now);
      }
    });

    const promise = rateLimiter
      .then(() => join(firebase, agentId, channel))
      .catch((e) => log.error({ channel, agentId, provider }, e))
      .finally(() => channels.delete(channel));
    channels.set(channel, promise);
  });

  return async () => {
    log.info({ agentId, provider }, "disconnecting");

    // stop listening for claims.
    unsubscribe();

    // request someone to take over.
    await firebase.releaseAll(provider, new Set(channels.keys()), agentId);

    log.info(
      { agentId, provider, waitingForChannels: [...channels.keys()] },
      "released all"
    );

    // and wait for existing promises.
    await Promise.all(channels.values());

    log.info({ agentId, provider }, "close complete");
  };
}
