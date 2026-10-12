import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "cross-fetch";
import { ClientCredentials } from "simple-oauth2";
import { searchKickChannel } from "./kick";
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

export const search = functions.https.onCall(async (data, context) => {
  if (context.auth != null && data == "") {
    // return the list of followed users instead.
    const token = await getAccessToken(context.auth.uid, "twitch");

    if (token != null) {
      const profileDoc = await admin
        .firestore()
        .collection("profiles")
        .doc(context.auth.uid)
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
      return [
        ...(twitchJson.data || []).map((channel: any) => {
          const imageUrl =
            "https://rtirl.com/pfp.png?provider=twitch&channelId=" +
            channel.user_id;
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
        }),
      ];
    }
  }

  // look up an exact kick channel while twitch searches.
  const kick = kickResults(String(data));
  const credentials = await new ClientCredentials(TWITCH_OAUTH_CONFIG).getToken(
    { scopes: [] }
  );
  const twitchResponse = await fetch(
    "https://api.twitch.tv/helix/search/channels?query=" +
      encodeURIComponent(data),
    {
      headers: {
        "Client-ID": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${credentials.token.access_token}`,
        "Content-Type": "application/json",
      },
    }
  );
  const twitchJson = (await twitchResponse.json()) as any;
  return [
    ...(twitchJson.data || []).map((channel: any) => {
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
    }),
    ...(await kick),
  ];
});
