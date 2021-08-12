import * as admin from "firebase-admin";
import TwitchJs, { UserStateTags } from "twitch-js";
import { FirebaseAdapter } from "../adapters/firebase";

function tmiJsTagsShim(tags: UserStateTags) {
  return {
    "user-id": tags.userId,
    "display-name": tags.displayName,
    "room-id": tags.roomId,
    "emote-only": tags.emoteOnly,
    ...tags,
  };
}

export async function runTwitchAgent(agentId: string) {
  const firebase = new FirebaseAdapter(
    admin.database(),
    admin.firestore(),
    "twitcH"
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
    firebase.addMessage(
      message.tags.roomId,
      message.tags.id,
      message.message,
      message.timestamp,
      tmiJsTagsShim(message.tags)
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
      await twitch.chat.join(channel);
    },
    async (channel) => {
      await twitch.chat.part(channel);
    }
  );

  return () => {
    unsubscribe();

    twitch.chat.disconnect();
  };
}
