import { ModuleOptions } from "simple-oauth2";

export const TWITCH_CLIENT_ID = "edfnh2q85za8phifif9jxt3ey6t9b9";
export const TWITCH_CLIENT_SECRET = "yn6jfzl3xturs91jdbljws5ouksqfj";

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
