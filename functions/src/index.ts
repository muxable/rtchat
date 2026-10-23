import * as functions from "firebase-functions";
import { app as authApp } from "./auth";
import { updateFollowerAndViewerCount } from "./chat-status";
import { updateKickChannelMetadata } from "./kick_subscriptions";
import { YOUTUBE_OAUTH_SECRETS } from "./oauth";
import { proxy, proxyCallable } from "./proxy";
import { subscribe, unsubscribe } from "./subscriptions";

// functions that act with a user's youtube token need the google oauth client
// to refresh it.
const withYouTube = functions.runWith({
  secrets: YOUTUBE_OAUTH_SECRETS,
});

export const send = proxyCallable("send");

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
  updateKickChannelMetadata,
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
export const kickWebhook = proxy("kickWebhook", "/kick/webhook");
export const alchemyWebhook = proxy("alchemyWebhook", "/alchemy/webhook");
export const eventsub = proxy("eventsub", "/twitch/eventsub");

export const auth = withYouTube.https.onRequest(authApp);
