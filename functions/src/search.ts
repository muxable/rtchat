import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "cross-fetch";
import { defineSecret } from "firebase-functions/params";
import { searchYouTubeChannel, YouTubeLookupCache } from "./youtube";
import { ClientCredentials } from "simple-oauth2";
import { searchKickChannel } from "./kick";
import { exactMatchesFirst } from "./search_results";
import {
  getAccessToken,
  getAppAccessToken,
  TWITCH_CLIENT_ID,
  TWITCH_OAUTH_CONFIG,
} from "./oauth";

const youtubeApiKey = defineSecret("youtube-api-key");

// Kick results are best effort: kick may not be configured or reachable.
async function kickResults(query: string) {
  try {
    const token = await getAppAccessToken("kick");
    return token
      ? await searchKickChannel(String(token.token.access_token), query)
      : [];
  } catch (err) {
    functions.logger.warn("kick search failed", err);
    return [];
  }
}

const YOUTUBE_LOOKUP_TTL_MS = 24 * 60 * 60 * 1000;

const youtubeLookupCache: YouTubeLookupCache = {
  async get(key) {
    const doc = await admin
      .firestore()
      .collection("youtube-lookups")
      .doc(encodeURIComponent(key))
      .get();
    const cachedAt = doc.get("cachedAt")?.toMillis?.() ?? 0;
    if (!doc.exists || Date.now() - cachedAt > YOUTUBE_LOOKUP_TTL_MS) {
      return undefined;
    }
    return doc.get("results");
  },
  async set(key, results) {
    await admin
      .firestore()
      .collection("youtube-lookups")
      .doc(encodeURIComponent(key))
      .set({ results, cachedAt: admin.firestore.FieldValue.serverTimestamp() });
  },
};

async function youtubeResults(query: string) {
  try {
    return await searchYouTubeChannel(
      youtubeApiKey.value(),
      query,
      youtubeLookupCache
    );
  } catch {
    return [];
  }
}

export type SearchProvider = "twitch" | "kick" | "youtube";

export interface SearchRequest {
  query: string;
  providers: SearchProvider[];
}

// The app sends {query, provider}. Older app versions send the raw query
// string and expect twitch and kick results merged, so they never get youtube.
export function parseSearchRequest(data: unknown): SearchRequest {
  if (typeof data === "string") {
    return { query: data, providers: ["twitch", "kick"] };
  }
  const { query, provider } = (data ?? {}) as any;
  if (provider !== "twitch" && provider !== "kick" && provider !== "youtube") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `unsupported provider: ${provider}`
    );
  }
  return {
    query: typeof query === "string" ? query : "",
    providers: [provider],
  };
}

// The live channels a signed-in twitch user follows, shown for an empty query.
async function followedTwitchChannels(uid: string) {
  const token = await getAccessToken(uid, "twitch");
  if (token == null) {
    return null;
  }
  const profileDoc = await admin
    .firestore()
    .collection("profiles")
    .doc(uid)
    .get();
  const twitchResponse = await fetch(
    "https://api.twitch.tv/helix/streams/followed?user_id=" +
      profileDoc.data()?.twitch?.id,
    {
      headers: {
        "Client-ID": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    }
  );
  const twitchJson = (await twitchResponse.json()) as any;
  return (twitchJson.data || []).map((channel: any) => {
    const imageUrl =
      "https://rtirl.com/pfp.png?provider=twitch&channelId=" + channel.user_id;
    return {
      provider: "twitch",
      channelId: channel.user_id,
      login: channel.user_login,
      displayName: channel.user_name,
      isOnline: channel.type == "live",
      imageUrl: imageUrl,
      categoryName: channel.game_name,
      title: channel.title,
      viewerCount: channel.viewer_count,
      language: channel.language,
    };
  });
}

async function twitchResults(query: string) {
  const credentials = await new ClientCredentials(TWITCH_OAUTH_CONFIG).getToken(
    { scopes: [] }
  );
  const twitchResponse = await fetch(
    "https://api.twitch.tv/helix/search/channels?query=" +
      encodeURIComponent(query),
    {
      headers: {
        "Client-ID": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${credentials.token.access_token}`,
        "Content-Type": "application/json",
      },
    }
  );
  const twitchJson = (await twitchResponse.json()) as any;
  return (twitchJson.data || []).map((channel: any) => {
    return {
      provider: "twitch",
      channelId: channel.id,
      login: channel.broadcaster_login,
      displayName: channel.display_name,
      isOnline: channel.is_live,
      imageUrl: channel.thumbnail_url,
      categoryName: channel.game_name,
      title: channel.title,
      language: channel.broadcaster_language,
    };
  });
}

export const search = functions
  .runWith({ secrets: ["youtube-api-key"] })
  .https.onCall(async (data, context) => {
    const { query, providers } = parseSearchRequest(data);

    if (context.auth != null && query == "" && providers.includes("twitch")) {
      const followed = await followedTwitchChannels(context.auth.uid);
      if (followed != null) {
        return followed;
      }
    }

    // kick and youtube only have exact lookups, so run them alongside twitch's search.
    const kick = providers.includes("kick") ? kickResults(query) : [];
    const youtube = providers.includes("youtube") ? youtubeResults(query) : [];
    const twitch = providers.includes("twitch")
      ? await twitchResults(query)
      : [];
    return exactMatchesFirst(
      [...twitch, ...(await kick), ...(await youtube)],
      query
    );
  });
