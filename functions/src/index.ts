import * as functions from "firebase-functions";
import { alchemyWebhook, setRealTimeCashAddress } from "./alchemy_webhook";
import { app as authApp } from "./auth";
import { updateFollowerAndViewerCount } from "./chat-status";
import {
  banKickUser,
  deleteKickMessage,
  resolveKickUserId,
  sendKickMessage,
  unbanKickUser,
} from "./kick_actions";
import { updateKickChannelMetadata } from "./kick_subscriptions";
import { kickWebhook } from "./kick_webhook";
import { eventsub } from "./eventsub";
import { getAccessToken, YOUTUBE_OAUTH_SECRETS } from "./oauth";
import { proxy, proxyCallable } from "./proxy";
import { search } from "./search";
import { subscribe, unsubscribe } from "./subscriptions";
import * as twitch from "./twitch";
import { WebSocket } from "ws";
import {
  banYouTubeUser,
  deleteYouTubeMessage,
  parseVideoId,
  sendYouTubeMessage,
} from "./youtube_actions";

// functions that act with a user's youtube token need the google oauth client
// to refresh it.
const withYouTube = functions.runWith({
  secrets: YOUTUBE_OAUTH_SECRETS,
});

// sends over a one-off irc connection: slow, and silent about failures. only
// used for tokens from before user:write:chat was requested.
async function sendOverIrc(uid: string, channelId: string, message: string) {
  const targetChannel = await twitch.getTwitchLogin(channelId);
  if (!targetChannel) {
    return;
  }
  const token = await getAccessToken(uid, "twitch");
  if (!token) {
    throw new functions.https.HttpsError("internal", "auth error");
  }
  const userChannel = await twitch.getTwitchLogin(
    await twitch.getChannelId(uid, "twitch"),
  );
  const ws = new WebSocket("wss://irc-ws.chat.twitch.tv:443");
  await new Promise<void>((resolve) => {
    ws.on("open", () => resolve());
  });
  ws.send("CAP REQ :twitch.tv/commands");
  ws.send(`PASS oauth:${token}`);
  ws.send(`NICK ${userChannel}`);
  ws.send(`PRIVMSG #${targetChannel} :${message}`);
  ws.close();
}

export const send = withYouTube.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const message = data?.message;
  if (!provider || !channelId || !message) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, message",
    );
  }

  switch (provider) {
    case "twitch": {
      const replyTo = data?.replyToMessageId?.replace(/^twitch:/, "");
      const result = await twitch.sendChatMessage(
        context.auth.uid,
        channelId,
        message,
        replyTo,
      );
      if (result.unauthorized) {
        await sendOverIrc(context.auth.uid, channelId, message);
        return;
      }
      // the app shows any returned value as an error.
      return result.error;
    }
    case "kick":
      // like twitch, return nothing on success: the app shows any returned
      // value as an error.
      await sendKickMessage(
        context.auth.uid,
        channelId,
        message,
        data?.replyToMessageId,
      );
      return;
    case "youtube":
      // youtube has no replies. return nothing on success, like the others.
      await sendYouTubeMessage(
        context.auth.uid,
        channelId,
        message,
        parseVideoId(data?.videoId),
      );
      return;
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const ban = withYouTube.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const username = data?.username;
  const userId = data?.userId;
  if (!provider || !channelId || (!username && !userId)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, username",
    );
  }

  switch (provider) {
    case "twitch":
      const banUserId = userId ? userId : await twitch.getTwitchId(username);
      return await twitch.ban(context.auth.uid, channelId, banUserId);
    case "kick":
      return await banKickUser(
        context.auth.uid,
        channelId,
        userId ?? (await resolveKickUserId(username)),
      );
    case "youtube":
      // youtube users are banned by channel id; there are no logins.
      await banYouTubeUser(context.auth.uid, channelId, userId, {
        videoId: parseVideoId(data?.videoId),
      });
      return;
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const unban = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const username = data?.username;
  const userId = data?.userId;
  if (!provider || !channelId || (!username && !userId)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, username",
    );
  }

  switch (provider) {
    case "twitch":
      const banUserId = userId ? userId : await twitch.getTwitchId(username);
      return await twitch.unban(context.auth.uid, channelId, banUserId);
    case "kick":
      return await unbanKickUser(
        context.auth.uid,
        channelId,
        userId ?? (await resolveKickUserId(username)),
      );
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const timeout = withYouTube.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const username = data?.username;
  const userId = data?.userId;
  const length = data?.length;
  const reason = data?.reason;
  if (!provider || !channelId || (!username && !userId) || !length || !reason) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, username, length, reason",
    );
  }

  switch (provider) {
    case "twitch":
      const banUserId = userId ? userId : await twitch.getTwitchId(username);
      return await twitch.timeout(
        context.auth.uid,
        channelId,
        banUserId,
        length,
        reason,
      );
    case "kick":
      return await banKickUser(
        context.auth.uid,
        channelId,
        userId ?? (await resolveKickUserId(username)),
        { durationSeconds: length, reason },
      );
    case "youtube":
      // youtube bans have no reason.
      await banYouTubeUser(context.auth.uid, channelId, userId, {
        durationSeconds: length,
        videoId: parseVideoId(data?.videoId),
      });
      return;
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const deleteMessage = withYouTube.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const messageId = data?.messageId;
  if (!provider || !channelId || !messageId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, messageId",
    );
  }

  switch (provider) {
    case "twitch":
      // chat message documents are keyed "twitch:<message id>".
      return await twitch.deleteMessage(
        context.auth.uid,
        channelId,
        messageId.replace(/^twitch:/, ""),
      );
    case "kick":
      return await deleteKickMessage(context.auth.uid, messageId);
    case "youtube":
      return await deleteYouTubeMessage(context.auth.uid, messageId);
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const clear = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  if (!provider || !channelId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId",
    );
  }

  switch (provider) {
    case "twitch":
      return await twitch.clearChat(context.auth.uid, channelId);
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const raid = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const fromChannelId = data?.fromChannelId;
  const toChannelId = data?.toChannelId;
  if (!provider || !fromChannelId || !toChannelId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, fromChannelId, toChannelId",
    );
  }

  switch (provider) {
    case "twitch":
      return await twitch.raid(context.auth.uid, fromChannelId, toChannelId);
  }
});

export const cancelRaid = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  if (!provider || !channelId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId",
    );
  }

  switch (provider) {
    case "twitch":
      return await twitch.cancelRaid(context.auth.uid, channelId);
  }
});

export {
  subscribe,
  unsubscribe,
  eventsub,
  kickWebhook,
  updateKickChannelMetadata,
  search,
  setRealTimeCashAddress,
  alchemyWebhook,
  updateFollowerAndViewerCount,
};
// moved to the agent; forwards clients that still call the function URL.
export const getBadges = proxyCallable("getBadges");
export const getEmotes = proxyCallable("getEmotes");
export const getStatistics = proxyCallable("getStatistics");
export const embedRedirect = proxy("embedRedirect", "/embedRedirect");
export const metadata = proxy("metadata", "/metadata");
export const getViewerList = proxyCallable("getViewerList");

export const auth = withYouTube.https.onRequest(authApp);
