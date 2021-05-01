import { ModuleOptions } from "simple-oauth2";

export const TWITCH_CLIENT_ID = "edfnh2q85za8phifif9jxt3ey6t9b9";
export const TWITCH_CLIENT_SECRET = "9ehkvvg2eal3ruf4ea7upe481gc2x6";

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
