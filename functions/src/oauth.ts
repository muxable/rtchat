import * as crypto from "crypto";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { defineSecret } from "firebase-functions/params";
import {
  AccessToken,
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

export const STREAMLABS_CLIENT_ID = functions.config().streamlabs.id;
export const STREAMLABS_CLIENT_SECRET = functions.config().streamlabs.secret;

export const STREAMLABS_OAUTH_CONFIG = {
  client: {
    id: STREAMLABS_CLIENT_ID,
    secret: STREAMLABS_CLIENT_SECRET,
  },
  auth: {
    tokenHost: "https://www.streamlabs.com/api/v1.0",
    tokenPath: "/api/v1.0/token",
    authorizePath: "/api/v1.0/authorize",
  },
  options: {
    bodyFormat: "json",
    authorizationMethod: "body",
  },
} as ModuleOptions<"client_id">;

export const STREAMELEMENTS_CLIENT_ID = functions.config().streamelements.id;
export const STREAMELEMENTS_CLIENT_SECRET =
  functions.config().streamelements.secret;

export const STREAMELEMENTS_OAUTH_CONFIG = {
  client: {
    id: STREAMELEMENTS_CLIENT_ID,
    secret: STREAMELEMENTS_CLIENT_SECRET,
  },
  auth: {
    tokenHost: "https://api.streamelements.com",
    tokenPath: "/oauth2/token",
    authorizePath: "/oauth2/authorize",
    revokePath: "/oauth2/revoke",
  },
  options: {
    bodyFormat: "json",
    authorizationMethod: "body",
  },
} as ModuleOptions<"client_id">;

// Kick is optional until the app is registered, so a missing config must not
// break deploys of the other functions.
export const KICK_CLIENT_ID: string | undefined = functions.config().kick?.id;
export const KICK_CLIENT_SECRET: string | undefined =
  functions.config().kick?.secret;

export const KICK_OAUTH_CONFIG = {
  client: {
    id: KICK_CLIENT_ID,
    secret: KICK_CLIENT_SECRET,
  },
  auth: {
    tokenHost: "https://id.kick.com",
    tokenPath: "/oauth/token",
    authorizePath: "/oauth/authorize",
    revokePath: "/oauth/revoke",
  },
  options: {
    bodyFormat: "form",
    authorizationMethod: "body",
  },
} as ModuleOptions<"client_id">;

// Google OAuth for YouTube. The client id and secret live only in Secret
// Manager, so the config is built when a function that declares
// YOUTUBE_OAUTH_SECRETS runs, never at load time.
export const YOUTUBE_OAUTH_CLIENT_ID = defineSecret("youtube-oauth-client-id");
export const YOUTUBE_OAUTH_CLIENT_SECRET = defineSecret(
  "youtube-oauth-client-secret"
);
export const YOUTUBE_OAUTH_SECRETS = [
  YOUTUBE_OAUTH_CLIENT_ID,
  YOUTUBE_OAUTH_CLIENT_SECRET,
];

export function youtubeOAuthConfig(id: string, secret: string) {
  return {
    client: { id, secret },
    auth: {
      tokenHost: "https://oauth2.googleapis.com",
      tokenPath: "/token",
      revokePath: "/revoke",
      authorizeHost: "https://accounts.google.com",
      authorizePath: "/o/oauth2/v2/auth",
    },
    options: {
      bodyFormat: "form",
      authorizationMethod: "body",
    },
  } as ModuleOptions<"client_id">;
}

export function oauthConfig(provider: string) {
  switch (provider) {
    case "twitch":
      return TWITCH_OAUTH_CONFIG;
    case "kick":
      if (!KICK_CLIENT_ID || !KICK_CLIENT_SECRET) {
        throw new Error("kick oauth is not configured");
      }
      return KICK_OAUTH_CONFIG;
    case "youtube": {
      const id = YOUTUBE_OAUTH_CLIENT_ID.value();
      const secret = YOUTUBE_OAUTH_CLIENT_SECRET.value();
      if (!id || !secret) {
        throw new Error("youtube oauth is not configured");
      }
      return youtubeOAuthConfig(id, secret);
    }
    case "streamlabs":
      return STREAMLABS_OAUTH_CONFIG;
    case "streamelements":
      return STREAMELEMENTS_OAUTH_CONFIG;
  }
  throw new Error(`unknown oauth provider: ${provider}`);
}

// Whether the `state` returned to an OAuth callback matches the one issued by
// the redirect, which protects the login flow against CSRF.
export function isValidState(expected: string | undefined, actual: unknown) {
  if (!expected || typeof actual !== "string") {
    return false;
  }
  const a = Buffer.from(expected);
  const b = Buffer.from(actual);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

// Whether a refresh failed because the grant was revoked or expired, as
// opposed to a transient error.
export function isInvalidRefreshError(err: any) {
  const payload = err?.data?.payload;
  return (
    payload?.message === "Invalid refresh token" || // twitch
    payload?.error === "invalid_grant" // rfc 6749, used by kick and google
  );
}

// Google only returns a refresh token with the first grant, so a refresh
// response without one keeps the previous refresh token.
export function withRefreshToken(
  previous: { refresh_token?: unknown },
  refreshed: Record<string, unknown>
) {
  return refreshed.refresh_token || !previous.refresh_token
    ? refreshed
    : { ...refreshed, refresh_token: previous.refresh_token };
}

export async function getAccessToken(userId: string, provider: string) {
  // fetch the token from the database.
  const ref = admin.firestore().collection("tokens").doc(userId);
  const encoded = (await ref.get()).get(provider);
  if (!encoded) {
    return null;
  }
  const client = new AuthorizationCode(oauthConfig(provider));
  let accessToken = client.createToken(JSON.parse(encoded));
  while (accessToken.expired(300)) {
    try {
      // providers like kick rotate refresh tokens, so the refreshed token
      // (including its new refresh token) is persisted below.
      const refreshed = await accessToken.refresh();
      accessToken = client.createToken(
        withRefreshToken(accessToken.token, refreshed.token)
      );
    } catch (err: any) {
      if (isInvalidRefreshError(err)) {
        await admin
          .firestore()
          .collection("tokens")
          .doc(userId)
          .update({ [provider]: admin.firestore.FieldValue.delete() });
        // this will sign the user out.
        await admin
          .firestore()
          .collection("profiles")
          .doc(userId)
          .update({ [provider]: admin.firestore.FieldValue.delete() });
        return null;
      }
      throw err;
    }
  }
  await ref.update({ [provider]: JSON.stringify(accessToken.token) });
  return accessToken.token["access_token"] as string;
}

const appTokens = new Map<string, AccessToken>();

export async function getAppAccessToken(provider: string) {
  switch (provider) {
    case "twitch":
      return new ClientCredentials(TWITCH_OAUTH_CONFIG).getToken({
        scopes: [],
      });
    case "kick": {
      const cached = appTokens.get(provider);
      if (cached && !cached.expired(300)) {
        return cached;
      }
      const token = await new ClientCredentials(oauthConfig(provider)).getToken(
        {}
      );
      appTokens.set(provider, token);
      return token;
    }
  }
  return null;
}
