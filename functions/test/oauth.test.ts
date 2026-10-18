import { afterEach, describe, expect, it, vi } from "vitest";
import * as path from "path";

// functions.config() caches its values; reset them to test missing config.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const runtimeConfig = require(path.join(
  __dirname,
  "../node_modules/firebase-functions/lib/v1/config.js"
));
import {
  isInvalidRefreshError,
  isValidState,
  KICK_OAUTH_CONFIG,
  oauthConfig,
  TWITCH_OAUTH_CONFIG,
  withRefreshToken,
} from "../src/oauth";

describe("isValidState", () => {
  it("accepts the state issued by the redirect", () => {
    expect(isValidState("abc123", "abc123")).toBe(true);
  });

  it("rejects a missing or mismatched state", () => {
    expect(isValidState(undefined, "abc123")).toBe(false);
    expect(isValidState("abc123", undefined)).toBe(false);
    expect(isValidState("abc123", "abc124")).toBe(false);
    expect(isValidState("abc123", "abc1234")).toBe(false);
    expect(isValidState("abc123", ["abc123"])).toBe(false);
  });
});

describe("oauthConfig", () => {
  afterEach(() => {
    vi.unstubAllEnvs();
    vi.resetModules();
    runtimeConfig.resetCache();
  });

  it("returns each provider's config", () => {
    expect(oauthConfig("twitch")).toBe(TWITCH_OAUTH_CONFIG);
    expect(oauthConfig("kick")).toBe(KICK_OAUTH_CONFIG);
    expect(KICK_OAUTH_CONFIG.auth.tokenHost).toBe("https://id.kick.com");
    expect(KICK_OAUTH_CONFIG.client.id).toBe("kick-id");
  });

  it("rejects unknown providers", () => {
    expect(() => oauthConfig("myspace")).toThrow(/unknown oauth provider/);
  });

  it("builds google's config from the youtube secrets at runtime", () => {
    vi.stubEnv("youtube-oauth-client-id", "yt-id");
    vi.stubEnv("youtube-oauth-client-secret", "yt-secret");
    const config = oauthConfig("youtube");
    expect(config.client).toEqual({ id: "yt-id", secret: "yt-secret" });
    expect(config.auth.tokenHost).toBe("https://oauth2.googleapis.com");
    expect(config.auth.authorizeHost).toBe("https://accounts.google.com");
  });

  it("refuses youtube without its secrets", () => {
    expect(() => oauthConfig("youtube")).toThrow(/not configured/);
  });

  it("loads without kick config but refuses to use it", async () => {
    const config = JSON.parse(process.env.CLOUD_RUNTIME_CONFIG!);
    delete config.kick;
    vi.stubEnv("CLOUD_RUNTIME_CONFIG", JSON.stringify(config));
    runtimeConfig.resetCache();
    vi.resetModules();
    const oauth = await import("../src/oauth");
    expect(oauth.oauthConfig("twitch")).toBe(oauth.TWITCH_OAUTH_CONFIG);
    expect(() => oauth.oauthConfig("kick")).toThrow(/not configured/);
  });
});

describe("withRefreshToken", () => {
  it("keeps the old refresh token when google doesn't return one", () => {
    expect(
      withRefreshToken(
        { refresh_token: "old" },
        { access_token: "new", expires_in: 3599 }
      )
    ).toEqual({ access_token: "new", expires_in: 3599, refresh_token: "old" });
  });

  it("uses rotated refresh tokens", () => {
    expect(
      withRefreshToken(
        { refresh_token: "old" },
        { access_token: "a", refresh_token: "new" }
      ).refresh_token
    ).toBe("new");
  });
});

describe("isInvalidRefreshError", () => {
  it("detects revoked twitch and kick refresh tokens", () => {
    expect(
      isInvalidRefreshError({
        data: { payload: { message: "Invalid refresh token" } },
      })
    ).toBe(true);
    expect(
      isInvalidRefreshError({ data: { payload: { error: "invalid_grant" } } })
    ).toBe(true);
  });

  it("ignores transient errors", () => {
    expect(isInvalidRefreshError(new Error("ECONNRESET"))).toBe(false);
    expect(
      isInvalidRefreshError({ data: { payload: { error: "server_error" } } })
    ).toBe(false);
  });
});
