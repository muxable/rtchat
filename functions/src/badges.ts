import fetch from "cross-fetch";
import * as functions from "firebase-functions";
import { getAppAccessToken, TWITCH_CLIENT_ID } from "./oauth";

async function getChannelBadges(channelId: string, accessToken: string) {
  const twitchResponse = await fetch(
    "https://api.twitch.tv/helix/chat/badges?broadcaster_id=" +
      encodeURIComponent(channelId),
    {
      headers: {
        "Client-ID": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
    }
  );
  return ((await twitchResponse.json()) as any)["data"];
}

async function getGlobalBadges(accessToken: string) {
  const twitchResponse = await fetch(
    "https://api.twitch.tv/helix/chat/badges/global",
    {
      headers: {
        "Client-ID": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
    }
  );
  return ((await twitchResponse.json()) as any)["data"];
}

export const getBadges = functions.https.onCall(async (data, context) => {
  const provider = data?.provider;
  const channelId = data?.channelId;
  if (!provider) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider"
    );
  }
  switch (provider) {
    case "twitch":
      const token = await getAppAccessToken("twitch");
      if (!token) {
        throw new functions.https.HttpsError(
          "internal",
          "failed to get twitch access token"
        );
      }
      if (channelId) {
        const badges = await getChannelBadges(
          channelId,
          token.token.access_token
        );
        return badges;
      } else {
        const badges = await getGlobalBadges(token.token.access_token);
        return badges;
      }
  }
  return [];
});
