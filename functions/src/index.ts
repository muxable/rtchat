import * as functions from "firebase-functions/v1";
import { app as authApp } from "./auth";
import { YOUTUBE_OAUTH_SECRETS } from "./oauth";
import { proxy, proxyCallable } from "./proxy";

// Everything but OAuth runs on the agent. These forward clients and provider
// callbacks that still use the function URLs (#1551).
export const send = proxyCallable("send");
export const ban = proxyCallable("ban");
export const unban = proxyCallable("unban");
export const timeout = proxyCallable("timeout");
export const deleteMessage = proxyCallable("deleteMessage");
export const clear = proxyCallable("clear");
export const raid = proxyCallable("raid");
export const cancelRaid = proxyCallable("cancelRaid");
export const subscribe = proxyCallable("subscribe");
export const setRealTimeCashAddress = proxyCallable("setRealTimeCashAddress");
export const search = proxyCallable("search");
export const getEmotes = proxyCallable("getEmotes");
export const getBadges = proxyCallable("getBadges");
export const getViewerList = proxyCallable("getViewerList");
export const getStatistics = proxyCallable("getStatistics");
export const embedRedirect = proxy("embedRedirect", "/embedRedirect");
export const metadata = proxy("metadata", "/metadata");
export const eventsub = proxy("eventsub", "/twitch/eventsub");
export const kickWebhook = proxy("kickWebhook", "/kick/webhook");
export const alchemyWebhook = proxy("alchemyWebhook", "/alchemy/webhook");

// signing in to youtube needs the google oauth client.
export const auth = functions
  .runWith({ secrets: YOUTUBE_OAUTH_SECRETS })
  .https.onRequest(authApp);
