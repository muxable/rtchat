import * as admin from "firebase-admin";
import TwitchJs, { PrivateMessage, PrivateMessageWithBits } from "twitch-js";
import { FirebaseAdapter } from "../adapters/firebase";
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

export async function runTwitchAgent(agentId: string) {
  const provider = "twitch";

  const firebase = new FirebaseAdapter(
    admin.database(),
    admin.firestore(),
    provider
  );

  const { username, token } = await firebase.getCredentials();

  const twitch = new TwitchJs({
    username,
    token: token["access_token"],
    onAuthenticationFailure: async () => {
      const { token } = await firebase.getCredentials(true);
      log.warn({ agentId, provider }, "authentication failure");
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
    firebase.addMessage(
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
    firebase.deleteMessage(
      message.tags.targetMsgId,
      message.timestamp,
      message.tags
    );
  });

  twitch.chat.on(TwitchJs.Chat.Events.HOSTED_WITH_VIEWERS, (message) => {
    firebase.addHost(
      message.channel,
      message.timestamp,
      message.numberOfViewers || 0
    );
  });

  await twitch.chat.connect();

  const unsubscribe = firebase.onAssignment(
    provider,
    agentId,
    async (channel) => {
      log.info({ channel, agentId, provider }, "assigned to channel");
      await Promise.race([
        twitch.chat.join(channel),
        new Promise<void>((_, reject) =>
          setTimeout(() => reject("failed to join in time"), 5000)
        ),
      ]);
      log.info({ channel, agentId, provider }, "joined channel");
    },
    async (channel) => {
      log.info({ channel, agentId, provider }, "unassigned from channel");
      await Promise.race([
        twitch.chat.part(channel),
        new Promise<void>((_, reject) =>
          setTimeout(() => reject("failed to part in time"), 5000)
        ),
      ]);
      log.info({ channel, agentId, provider }, "parted channel");
    }
  );

  twitch.chat.on(TwitchJs.Chat.Events.DISCONNECTED, async () => {
    log.info({ agentId, provider }, "disconnected");

    await unsubscribe();
  });

  return async () => {
    log.info({ agentId, provider }, "disconnecting");

    await unsubscribe();

    twitch.chat.disconnect();
  };
}
