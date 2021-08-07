import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  AuthorizationCode,
  ClientCredentials,
  ModuleOptions,
} from "simple-oauth2";

export const TWITCH_CLIENT_ID = functions.config().twitch.id;
export const TWITCH_CLIENT_SECRET = functions.config().twitch.secret;

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

export async function getAccessToken(userId: string, provider: string) {
  // fetch the token from the database.
  const ref = admin.firestore().collection("tokens").doc(userId);
  const encoded = (await ref.get()).get(provider);
  if (!encoded) {
    await unlink(userId, provider);
    return null;
  }
  const client = new AuthorizationCode(TWITCH_OAUTH_CONFIG);
  let accessToken = client.createToken(JSON.parse(encoded));
  while (accessToken.expired(300)) {
    try {
      accessToken = await accessToken.refresh();
    } catch (err) {
      if (err.data?.payload?.message === "Invalid refresh token") {
        await unlink(userId, provider);
        return null;
      }
      throw err;
    }
  }
  await ref.update({ [provider]: JSON.stringify(accessToken.token) });
  return accessToken.token["access_token"] as string;
}

export async function getAppAccessToken(provider: string) {
  switch (provider) {
    case "twitch":
      return new ClientCredentials(TWITCH_OAUTH_CONFIG).getToken({ scope: [] });
  }
  return null;
}

async function unlink(userId: string, provider: string) {
  const snapshot = await admin
    .database()
    .ref("userIds")
    .orderByValue()
    .equalTo(userId)
    .get();
  for (const key of Object.keys(snapshot.val())) {
    await admin.database().ref("userIds").child(key).set(null);
  }
  await admin
    .firestore()
    .collection("tokens")
    .doc(userId)
    .update({ [provider]: null });
  await admin
    .firestore()
    .collection("profiles")
    .doc(userId)
    .update({ [provider]: null });
}
