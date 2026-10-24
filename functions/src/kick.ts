import * as crypto from "crypto";
import fetch from "cross-fetch";

// Kick's public API: https://docs.kick.com/
export const KICK_API = "https://api.kick.com/public/v1";

export const KICK_SCOPES = [
  "user:read",
  "channel:read",
  "chat:write",
  "events:subscribe",
  "moderation:ban",
  "moderation:chat_message:manage",
];

// PKCE (RFC 7636), which Kick requires for the authorization code flow.
export function createCodeVerifier() {
  return crypto.randomBytes(32).toString("base64url");
}

export function codeChallenge(verifier: string) {
  return crypto.createHash("sha256").update(verifier).digest("base64url");
}

export interface KickProfile {
  id: string;
  slug: string;
  displayName: string;
  profilePictureUrl: string | null;
  email: string | null;
}

// Combines the authorized user (GET /users) and their channel (GET /channels)
// into the shape stored at profiles/{uid}.kick. A Kick user's id is also their
// channel's broadcaster_user_id.
export function toKickProfile(user: any, channel: any): KickProfile {
  return {
    id: String(user.user_id),
    slug: channel?.slug ?? String(user.name).toLowerCase(),
    displayName: user.name,
    profilePictureUrl: user.profile_picture || null,
    email: user.email || null,
  };
}

export async function kickApi(
  accessToken: string,
  path: string,
  init: RequestInit = {},
) {
  const response = await fetch(`${KICK_API}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
      ...(init.body ? { "Content-Type": "application/json" } : {}),
      ...init.headers,
    },
  });
  if (!response.ok) {
    throw new Error(
      `kick api ${init.method ?? "GET"} ${path}: ${
        response.status
      } ${await response.text()}`,
    );
  }
  return response.status === 204 ? null : await response.json();
}

// Looks up the user an access token belongs to.
export async function getKickProfile(accessToken: string) {
  const users = await kickApi(accessToken, "/users");
  const channels = await kickApi(accessToken, "/channels");
  return toKickProfile(users.data[0], channels.data?.[0]);
}

// Kick has no fuzzy channel search, only exact slug lookups.
const SLUG_PATTERN = /^[a-z0-9_-]{2,25}$/;

export function isKickSlug(query: string) {
  return SLUG_PATTERN.test(query.trim().toLowerCase());
}

// Maps a Kick channel (and its owner, for the picture) to the shape the search
// callable returns.
export function toSearchResult(channel: any, user?: any) {
  return {
    provider: "kick",
    channelId: String(channel.broadcaster_user_id),
    login: channel.slug,
    displayName: user?.name ?? channel.slug,
    isOnline: channel.stream?.is_live ?? false,
    imageUrl:
      user?.profile_picture ||
      `https://rtirl.com/pfp.png?provider=kick&channelId=${channel.broadcaster_user_id}`,
    categoryName: channel.category?.name ?? null,
    title: channel.stream_title ?? null,
    viewerCount: channel.stream?.viewer_count ?? 0,
    language: channel.stream?.language ?? null,
  };
}

export async function searchKickChannel(appToken: string, query: string) {
  if (!isKickSlug(query)) {
    return [];
  }
  const slug = query.trim().toLowerCase();
  const channels = await kickApi(
    appToken,
    `/channels?slug=${encodeURIComponent(slug)}`,
  );
  const channel = channels?.data?.[0];
  if (!channel) {
    return [];
  }
  const users = await kickApi(
    appToken,
    `/users?id=${channel.broadcaster_user_id}`,
  ).catch(() => null);
  return [toSearchResult(channel, users?.data?.[0])];
}

export async function getKickSlug(appToken: string, broadcasterId: string) {
  const channels = await kickApi(
    appToken,
    `/channels?broadcaster_user_id=${encodeURIComponent(broadcasterId)}`,
  );
  return (channels?.data?.[0]?.slug as string | undefined) ?? null;
}
