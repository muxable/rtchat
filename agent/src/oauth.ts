import * as admin from "firebase-admin";
import { AuthorizationCode, ModuleOptions } from "simple-oauth2";

const TWITCH_CLIENT_ID = process.env["TWITCH_CLIENT_ID"];
const TWITCH_CLIENT_SECRET = process.env["TWITCH_CLIENT_SECRET"];
const TWITCH_BOT_USER_ID = process.env["TWITCH_BOT_USER_ID"];

export const TWITCH_OAUTH_CONFIG = {
  client: {
    id: TWITCH_CLIENT_ID,
    secret: TWITCH_CLIENT_SECRET,
  },
  auth: {
    tokenHost: "https://id.twitch.tv",
    tokenPath: "/oauth2/token",
    authorizePath: "/oauth2/authorize",
  },
  options: {
    bodyFormat: "json",
    authorizationMethod: "body",
  },
} as ModuleOptions<"client_id">;

function getBotUserId(provider: string) {
  switch (provider) {
    case "twitch":
      return TWITCH_BOT_USER_ID;
  }
}

export async function getAccessToken(provider: string) {
  const userId = getBotUserId(provider);
  if (!userId) {
    throw new Error("invalid provider");
  }

  // fetch the token from the database.
  const ref = admin.firestore().collection("tokens").doc(userId);
  const encoded = (await ref.get()).get(provider);
  if (!encoded) {
    throw new Error("token not found");
  }
  const client = new AuthorizationCode(TWITCH_OAUTH_CONFIG);
  let accessToken = client.createToken(JSON.parse(encoded));
  while (accessToken.expired(300)) {
    try {
      accessToken = await accessToken.refresh();
    } catch (err) {
      if (err.data?.payload?.message === "Invalid refresh token") {
        throw new Error("invalid refresh token");
      }
      throw err;
    }
  }
  await ref.update({ [provider]: JSON.stringify(accessToken.token) });
  return accessToken.token;
}
