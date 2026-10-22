import fetch from "cross-fetch";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { getAccessToken } from "./oauth";

// Chat actions on YouTube, taken on behalf of the signed-in user with their
// Google token (youtube.force-ssl). Quota per call: insert and delete cost 20
// units, bans 200, and the live chat lookup 1.
// https://developers.google.com/youtube/v3/live/docs

export const YOUTUBE_API = "https://www.googleapis.com/youtube/v3";

export const YOUTUBE_SCOPES = [
  "https://www.googleapis.com/auth/youtube.force-ssl",
];

const CHANNEL_ID_PATTERN = /^UC[A-Za-z0-9_-]{22}$/;
const VIDEO_ID_PATTERN = /^[A-Za-z0-9_-]{11}$/;

// Shown by the app as is.
export const QUOTA_EXCEEDED_MESSAGE =
  "YouTube's daily quota for sending and moderating chat is used up. It resets at midnight Pacific time.";

const LIVE_CHAT_GONE = new Set([
  "liveChatEnded",
  "liveChatNotFound",
  "liveChatDisabled",
]);

// Maps a YouTube Data API error response to an error the app can show.
export function toHttpsError(status: number, body: any) {
  const reason: string | undefined =
    body?.error?.errors?.[0]?.reason ?? body?.error?.status;
  const details = { provider: "youtube", reason: reason ?? null, status };
  switch (reason) {
    case "quotaExceeded":
    case "dailyLimitExceeded":
      return new functions.https.HttpsError(
        "resource-exhausted",
        QUOTA_EXCEEDED_MESSAGE,
        details,
      );
    case "rateLimitExceeded":
    case "userRateLimitExceeded":
      return new functions.https.HttpsError(
        "resource-exhausted",
        "YouTube is rate limiting chat actions. Try again in a moment.",
        details,
      );
  }
  if (reason && LIVE_CHAT_GONE.has(reason)) {
    return new functions.https.HttpsError(
      "failed-precondition",
      "This YouTube live chat isn't active.",
      details,
    );
  }
  if (status === 401) {
    return new functions.https.HttpsError(
      "unauthenticated",
      "YouTube sign-in expired. Sign in with YouTube again.",
      details,
    );
  }
  if (status === 403) {
    return new functions.https.HttpsError(
      "permission-denied",
      "YouTube didn't allow this action.",
      details,
    );
  }
  if (status === 404) {
    return new functions.https.HttpsError(
      "not-found",
      "Not found on YouTube.",
      details,
    );
  }
  return new functions.https.HttpsError(
    status >= 500 ? "unavailable" : "internal",
    "YouTube request failed.",
    details,
  );
}

export async function youtubeApi(
  accessToken: string,
  path: string,
  init: RequestInit = {},
) {
  const response = await fetch(`${YOUTUBE_API}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
      ...(init.body ? { "Content-Type": "application/json" } : {}),
      ...init.headers,
    },
  });
  const text = await response.text();
  let body: any = null;
  try {
    body = text ? JSON.parse(text) : null;
  } catch {
    body = null;
  }
  if (!response.ok) {
    throw toHttpsError(response.status, body);
  }
  return body;
}

export interface YouTubeProfile {
  id: string;
  displayName: string;
  login: string;
  profilePictureUrl: string | null;
  email: null;
}

// The signed-in user's own channel, stored at profiles/{uid}.youtube. Accounts
// without a YouTube channel can't chat, so they get null.
export async function getYouTubeProfile(
  accessToken: string,
): Promise<YouTubeProfile | null> {
  const response = await youtubeApi(
    accessToken,
    "/channels?part=snippet&mine=true",
  );
  const channel = response?.items?.[0];
  if (!channel?.id) {
    return null;
  }
  const snippet = channel.snippet ?? {};
  return {
    id: channel.id,
    displayName: snippet.title ?? channel.id,
    login: snippet.customUrl ?? channel.id,
    profilePictureUrl:
      snippet.thumbnails?.medium?.url ??
      snippet.thumbnails?.default?.url ??
      null,
    email: null,
  };
}

async function userToken(uid: string) {
  const token = await getAccessToken(uid, "youtube");
  if (!token) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "youtube account not linked",
    );
  }
  return token;
}

export function isYouTubeChannelId(value: unknown): value is string {
  return typeof value === "string" && CHANNEL_ID_PATTERN.test(value);
}

function requireChannelId(channelId: unknown, name = "channel") {
  if (!isYouTubeChannelId(channelId)) {
    throw new functions.https.HttpsError("invalid-argument", `invalid ${name}`);
  }
  return channelId;
}

// Message documents are keyed "youtube:<LiveChatMessage id>".
export function toYouTubeMessageId(messageId: string) {
  return messageId.replace(/^youtube:/, "");
}

// The video a channel is live on, read from the canonical link of its /live
// page like the agent does. This costs no quota.
export async function findLiveVideoId(channelId: string) {
  const response = await fetch(
    `https://www.youtube.com/channel/${encodeURIComponent(channelId)}/live`,
    { headers: { "Accept-Language": "en" } },
  );
  if (!response.ok) {
    return null;
  }
  const html = await response.text();
  const match =
    /<link[^>]+rel="canonical"[^>]+href="https:\/\/www\.youtube\.com\/watch\?v=([A-Za-z0-9_-]{11})"/.exec(
      html,
    );
  return match ? match[1] : null;
}

const LIVE_CHAT_TTL_MS = 5 * 60 * 1000;
const liveChatIds = new Map<string, { id: string; expiresAt: number }>();

export function clearLiveChatCache() {
  liveChatIds.clear();
}

async function ownChannelId(uid: string) {
  const profile = await admin.firestore().collection("profiles").doc(uid).get();
  return profile.get("youtube")?.id as string | undefined;
}

// The active live chat of a channel. The signed-in user's own channel is found
// with liveBroadcasts.list (broadcastStatus=active is scoped to the authorized
// user, so it can't be combined with mine=true); other channels through their
// live video's liveStreamingDetails.activeLiveChatId. Both cost 1 unit.
export async function findLiveChatId(
  uid: string,
  accessToken: string,
  channelId: string,
  videoId?: string,
) {
  const cached = liveChatIds.get(channelId);
  if (!videoId && cached && cached.expiresAt > Date.now()) {
    return cached.id;
  }
  let liveChatId: string | undefined;
  if (!videoId && (await ownChannelId(uid)) === channelId) {
    const response = await youtubeApi(
      accessToken,
      "/liveBroadcasts?part=snippet&broadcastStatus=active&broadcastType=all&maxResults=50",
    );
    liveChatId = (response?.items ?? []).find(
      (item: any) =>
        item?.snippet?.liveChatId &&
        (!item.snippet.channelId || item.snippet.channelId === channelId),
    )?.snippet?.liveChatId;
  }
  if (!liveChatId) {
    const video = videoId ?? (await findLiveVideoId(channelId));
    if (video) {
      const response = await youtubeApi(
        accessToken,
        `/videos?part=liveStreamingDetails,snippet&id=${encodeURIComponent(
          video,
        )}`,
      );
      const item = response?.items?.[0];
      if (!item?.snippet?.channelId || item.snippet.channelId === channelId) {
        liveChatId = item?.liveStreamingDetails?.activeLiveChatId;
      }
    }
  }
  if (!liveChatId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "This YouTube channel isn't live.",
      { provider: "youtube", reason: "notLive" },
    );
  }
  liveChatIds.set(channelId, {
    id: liveChatId,
    expiresAt: Date.now() + LIVE_CHAT_TTL_MS,
  });
  return liveChatId;
}

// Runs an action against a channel's live chat, forgetting the cached chat id
// if YouTube says it's gone so the next call looks it up again.
async function withLiveChat<T>(
  uid: string,
  channelId: string,
  videoId: string | undefined,
  action: (token: string, liveChatId: string) => Promise<T>,
) {
  const token = await userToken(uid);
  const liveChatId = await findLiveChatId(uid, token, channelId, videoId);
  try {
    return await action(token, liveChatId);
  } catch (err: any) {
    if (err?.details?.reason && LIVE_CHAT_GONE.has(err.details.reason)) {
      liveChatIds.delete(channelId);
    }
    throw err;
  }
}

export function parseVideoId(videoId: unknown) {
  if (videoId == null) {
    return undefined;
  }
  if (typeof videoId !== "string" || !VIDEO_ID_PATTERN.test(videoId)) {
    throw new functions.https.HttpsError("invalid-argument", "invalid videoId");
  }
  return videoId;
}

// YouTube chat messages are at most 200 characters.
export const MAX_MESSAGE_LENGTH = 200;

export async function sendYouTubeMessage(
  uid: string,
  channelId: string,
  message: string,
  videoId?: string,
) {
  requireChannelId(channelId);
  if ([...message].length > MAX_MESSAGE_LENGTH) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `YouTube messages can be at most ${MAX_MESSAGE_LENGTH} characters.`,
    );
  }
  const response = await withLiveChat(
    uid,
    channelId,
    videoId,
    (token, liveChatId) =>
      youtubeApi(token, "/liveChat/messages?part=snippet", {
        method: "POST",
        body: JSON.stringify({
          snippet: {
            liveChatId,
            type: "textMessageEvent",
            textMessageDetails: { messageText: message },
          },
        }),
      }),
  );
  return response?.id ? `youtube:${response.id}` : null;
}

export async function deleteYouTubeMessage(uid: string, messageId: string) {
  const id = toYouTubeMessageId(messageId);
  if (!id) {
    throw new functions.https.HttpsError("invalid-argument", "invalid message");
  }
  await youtubeApi(
    await userToken(uid),
    `/liveChat/messages?id=${encodeURIComponent(id)}`,
    { method: "DELETE" },
  );
}

// Bans a user from the channel's live chat, or times them out for
// durationSeconds. Returns the ban's id, which liveChatBans.delete takes.
export async function banYouTubeUser(
  uid: string,
  channelId: string,
  userChannelId: string,
  options: { durationSeconds?: number; videoId?: string } = {},
) {
  requireChannelId(channelId);
  requireChannelId(userChannelId, "user");
  const duration = options.durationSeconds
    ? Math.max(1, Math.ceil(Number(options.durationSeconds)))
    : undefined;
  if (duration !== undefined && !Number.isFinite(duration)) {
    throw new functions.https.HttpsError("invalid-argument", "invalid length");
  }
  const response = await withLiveChat(
    uid,
    channelId,
    options.videoId,
    (token, liveChatId) =>
      youtubeApi(token, "/liveChat/bans?part=snippet", {
        method: "POST",
        body: JSON.stringify({
          snippet: {
            liveChatId,
            type: duration ? "temporary" : "permanent",
            ...(duration ? { banDurationSeconds: duration } : {}),
            bannedUserDetails: { channelId: userChannelId },
          },
        }),
      }),
  );
  return (response?.id as string | undefined) ?? null;
}
