import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "cross-fetch";
import { ClientCredentials } from "simple-oauth2";
import { searchKickChannel } from "./kick";
import { exactMatchesFirst } from "./search_results";
import {
  getAccessToken,
  getAppAccessToken,
  TWITCH_CLIENT_ID,
  TWITCH_OAUTH_CONFIG,
} from "./oauth";

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

export type SearchProvider = "twitch" | "kick";

export interface SearchRequest {
  query: string;
  providers: SearchProvider[];
}

// The app sends {query, provider}. Older app versions send the raw query
// string and expect twitch and kick results merged.
export function parseSearchRequest(data: unknown): SearchRequest {
  if (typeof data === "string") {
    return { query: data, providers: ["twitch", "kick"] };
  }
  const { query, provider } = (data ?? {}) as any;
  if (provider !== "twitch" && provider !== "kick") {
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

export const search = functions.https.onCall(async (data, context) => {
  const { query, providers } = parseSearchRequest(data);

  if (context.auth != null && query == "" && providers.includes("twitch")) {
    const followed = await followedTwitchChannels(context.auth.uid);
    if (followed != null) {
      return followed;
    }
  }

  // kick only has exact slug lookups, so run them alongside twitch's search.
  const kick = providers.includes("kick") ? kickResults(query) : [];
  const twitch = providers.includes("twitch") ? await twitchResults(query) : [];
  return exactMatchesFirst([...twitch, ...(await kick)], query);
});
