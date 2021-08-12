import * as admin from "firebase-admin";
import TwitchJs, { PrivateMessage, PrivateMessageWithBits } from "twitch-js";
import { FirebaseAdapter } from "../adapters/firebase";

const ACTION_MESSAGE_REGEX = /^\u0001ACTION ([^\u0001]+)\u0001$/;
const BADGES_RAW_REGEX = /badges=([^;]+);/;
const EMOTES_RAW_REGEX = /emotes=([^;]+);/;

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
    "badges-raw": badgesRaw ? badgesRaw[1] : "",
    "emotes-raw": emotesRaw ? emotesRaw[1] : "",
  };
}

export async function runTwitchAgent(agentId: string) {
  const firebase = new FirebaseAdapter(
    admin.database(),
    admin.firestore(),
    "twitch"
  );

  const { username, token } = await firebase.getCredentials();

  const twitch = new TwitchJs({
    username,
    token: token["access_token"],
    onAuthenticationFailure: async () => {
      const { token } = await firebase.getCredentials(true);
      return token["access_token"];
    },
  });

  twitch.chat.on(TwitchJs.Chat.Events.PRIVATE_MESSAGE, (message) => {
    if (message.command !== TwitchJs.Chat.Commands.PRIVATE_MESSAGE) {
      return;
    }
    if (
      message.event !== TwitchJs.Chat.Commands.PRIVATE_MESSAGE &&
      // TODO: Stop sending cheer events and use event sub instead.
      message.event !== "CHEER"
    ) {
      return;
    }

    const actionMessage = message.message.match(ACTION_MESSAGE_REGEX);
    const isAction = Boolean(actionMessage);

    // strip off the action data.
    firebase.addMessage(
      message.tags.roomId,
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

  await twitch.chat.connect();

  const unsubscribe = firebase.onAssignment(
    "twitch",
    agentId,
    async (channel) => {
      console.log(`[twitch] Assigned to channel: ${channel}`);
      await twitch.chat.join(channel);
    },
    async (channel) => {
      console.log(`[twitch] Unassigned from channel: ${channel}`);
      await twitch.chat.part(channel);
    }
  );

  return async () => {
    console.log(`[twitch] Disconnecting from Twitch`);

    await unsubscribe();

    twitch.chat.disconnect();
  };
}
