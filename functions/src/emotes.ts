import * as functions from "firebase-functions";
import fetch from "node-fetch";
import { ClientCredentials } from "simple-oauth2";
import { TWITCH_CLIENT_ID, TWITCH_OAUTH_CONFIG } from "./oauth";

export const getUserEmotes = functions.https.onCall(async (data, context) => {
  const provider = data?.provider;
  const channelId = data?.channelId;
  if (!provider || !channelId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId"
    );
  }

  switch (provider) {
    case "twitch":
      const credentials = await new ClientCredentials(TWITCH_OAUTH_CONFIG).getToken(
        { scopes: [] }
      );

      const channelJson = await getChannelEmotes(channelId, credentials.token.access_token);
      const globalEmotes = await getGlobalEmotes(credentials.token.access_token);
      const mappedChannelEmotes = mapEmotes(channelJson.data);
      const mappedGlobalEmotes = mapEmotes(globalEmotes.data);
      return { emotes: mappedGlobalEmotes.concat(mappedChannelEmotes) };
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

function mapEmotes(emoteArray: any) {
  return emoteArray.map((emote: any) => {
    return {
      id: emote["id"],
      code: emote["name"],
      source: `https://static-cdn.jtvnw.net/emoticons/v2/${emote["id"]}/default/dark/1.0`
    }
  });

}

async function getChannelEmotes(channelId: string, accessToken: string) {
  const twitchResponse = await fetch(
    "https://api.twitch.tv/helix/chat/emotes?broadcaster_id=" +
    encodeURIComponent(channelId),
    {
      headers: {
        "Client-ID": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
    }
  );
  return await twitchResponse.json();
}

async function getGlobalEmotes(accessToken: string) {
  const twitchResponse = await fetch(
    "https://api.twitch.tv/helix/chat/emotes/global",
    {
      headers: {
        "Client-ID": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
    }
  );
  return await twitchResponse.json();
}
