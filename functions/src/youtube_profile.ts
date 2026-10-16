import fetch from "cross-fetch";
import * as functions from "firebase-functions";

// YouTube profile lookup retained by the OAuth callback.
// https://developers.google.com/youtube/v3/docs/channels/list

export const YOUTUBE_API = "https://www.googleapis.com/youtube/v3";

export const YOUTUBE_SCOPES = [
  "https://www.googleapis.com/auth/youtube.force-ssl",
];

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
        details
      );
    case "rateLimitExceeded":
    case "userRateLimitExceeded":
      return new functions.https.HttpsError(
        "resource-exhausted",
        "YouTube is rate limiting chat actions. Try again in a moment.",
        details
      );
  }
  if (reason && LIVE_CHAT_GONE.has(reason)) {
    return new functions.https.HttpsError(
      "failed-precondition",
      "This YouTube live chat isn't active.",
      details
    );
  }
  if (status === 401) {
    return new functions.https.HttpsError(
      "unauthenticated",
      "YouTube sign-in expired. Sign in with YouTube again.",
      details
    );
  }
  if (status === 403) {
    return new functions.https.HttpsError(
      "permission-denied",
      "YouTube didn't allow this action.",
      details
    );
  }
  if (status === 404) {
    return new functions.https.HttpsError(
      "not-found",
      "Not found on YouTube.",
      details
    );
  }
  return new functions.https.HttpsError(
    status >= 500 ? "unavailable" : "internal",
    "YouTube request failed.",
    details
  );
}

export async function youtubeApi(
  accessToken: string,
  path: string,
  init: RequestInit = {}
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
  accessToken: string
): Promise<YouTubeProfile | null> {
  const response = await youtubeApi(
    accessToken,
    "/channels?part=snippet&mine=true"
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
