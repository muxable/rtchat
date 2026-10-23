import * as functions from "firebase-functions";
import { alchemyWebhook } from "./alchemy_webhook";
import { app as authApp } from "./auth";
import { updateFollowerAndViewerCount } from "./chat-status";
import { sendKickMessage } from "./kick_actions";
import { updateKickChannelMetadata } from "./kick_subscriptions";
import { kickWebhook } from "./kick_webhook";
import { eventsub } from "./eventsub";
import { getAccessToken, YOUTUBE_OAUTH_SECRETS } from "./oauth";
import { proxy, proxyCallable } from "./proxy";
import { subscribe, unsubscribe } from "./subscriptions";
import * as twitch from "./twitch";
import { WebSocket } from "ws";
import { parseVideoId, sendYouTubeMessage } from "./youtube_actions";

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

export const ban = proxyCallable("ban");

export const unban = proxyCallable("unban");

export const timeout = proxyCallable("timeout");

export const deleteMessage = proxyCallable("deleteMessage");

export const clear = proxyCallable("clear");

export const raid = proxyCallable("raid");

export const cancelRaid = proxyCallable("cancelRaid");

export {
  subscribe,
  unsubscribe,
  eventsub,
  kickWebhook,
  updateKickChannelMetadata,
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
export const search = proxyCallable("search");
export const setRealTimeCashAddress = proxyCallable("setRealTimeCashAddress");

export const auth = withYouTube.https.onRequest(authApp);
