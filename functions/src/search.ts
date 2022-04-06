import * as functions from "firebase-functions";
import fetch from "node-fetch";
import { ClientCredentials } from "simple-oauth2";
import { TWITCH_CLIENT_ID, TWITCH_OAUTH_CONFIG } from "./oauth";

export const search = functions.https.onCall(async (data, context) => {
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
  const twitchJson = await twitchResponse.json();
  return [
    ...twitchJson.data.map((channel: any) => {
      return {
        provider: "twitch",
        channelId: channel.id,
        displayName: channel.display_name,
        isOnline: channel.is_live,
        imageUrl: channel.thumbnail_url,
        title: channel.title,
      };
    }),
  ];
});
