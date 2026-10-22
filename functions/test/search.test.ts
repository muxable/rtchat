import { beforeEach, describe, expect, it, vi } from "vitest";

const { fetch, secretValue } = vi.hoisted(() => ({
  fetch: vi.fn(),
  secretValue: vi.fn(),
}));

vi.mock("cross-fetch", () => ({ default: fetch }));
vi.mock("simple-oauth2", () => ({
  ClientCredentials: class {
    async getToken() {
      return { token: { access_token: "twitch-app-token" } };
    }
  },
}));
vi.mock("../src/oauth", () => ({
  TWITCH_CLIENT_ID: "twitch-id",
  TWITCH_OAUTH_CONFIG: {},
  getAccessToken: async () => "user-token",
  getAppAccessToken: async () => ({ token: { access_token: "kick-token" } }),
}));
vi.mock("firebase-functions/params", () => ({
  defineSecret: () => ({ value: secretValue }),
}));
vi.mock("firebase-admin", () => ({
  firestore: Object.assign(
    () => ({
      collection: () => ({
        doc: () => ({
          // a profile, and a youtube lookup cache miss.
          get: async () => ({
            exists: false,
            get: () => undefined,
            data: () => ({ twitch: { id: "1234" } }),
          }),
          set: async () => {},
        }),
      }),
    }),
    { FieldValue: { serverTimestamp: () => "now" } },
  ),
}));

import { parseSearchRequest, search } from "../src/search";

const json = (body: any) => ({
  ok: true,
  status: 200,
  json: async () => body,
  text: async () => JSON.stringify(body),
});

const youtubeChannelId = "UCabcdefghijklmnopqr12_-";

beforeEach(() => {
  secretValue.mockReset();
  secretValue.mockReturnValue("youtube-key");
  fetch.mockReset();
  fetch.mockImplementation(async (url: string) => {
    if (url.startsWith("https://api.twitch.tv/helix/search/channels")) {
      return json({
        data: [
          {
            id: "1",
            broadcaster_login: "xqcshadow",
            display_name: "xQcShadow",
          },
          { id: "2", broadcaster_login: "xqc", display_name: "xQc" },
        ],
      });
    }
    if (url.startsWith("https://api.twitch.tv/helix/streams/followed")) {
      return json({
        data: [{ user_id: "9", user_login: "muxfd", user_name: "muxfd" }],
      });
    }
    if (url.startsWith("https://api.kick.com/public/v1/channels?slug=xqc")) {
      return json({ data: [{ broadcaster_user_id: 77, slug: "xqc" }] });
    }
    if (url.startsWith("https://api.kick.com/public/v1/users")) {
      return json({ data: [{ name: "xQc" }] });
    }
    if (url.startsWith("https://www.googleapis.com/youtube/v3/channels")) {
      expect(new URL(url).searchParams.get("key")).toBe("youtube-key");
      return json({
        items: [
          {
            id: youtubeChannelId,
            snippet: { title: "xQc", customUrl: "@xqc" },
          },
        ],
      });
    }
    return json({ data: [] });
  });
});

const run = (data: any, auth?: { uid: string }) =>
  (search as any).run(data, auth ? { auth } : {});

const calledHosts = () =>
  fetch.mock.calls.map(([url]) => new URL(url as string).host);

describe("parseSearchRequest", () => {
  it("treats a raw string as a legacy search of twitch and kick", () => {
    expect(parseSearchRequest("xqc")).toEqual({
      query: "xqc",
      providers: ["twitch", "kick"],
    });
  });

  it("searches only the requested provider", () => {
    expect(parseSearchRequest({ query: "xqc", provider: "kick" })).toEqual({
      query: "xqc",
      providers: ["kick"],
    });
    expect(parseSearchRequest({ query: "xqc", provider: "twitch" })).toEqual({
      query: "xqc",
      providers: ["twitch"],
    });
  });

  it("searches youtube only when asked", () => {
    expect(parseSearchRequest({ query: "xqc", provider: "youtube" })).toEqual({
      query: "xqc",
      providers: ["youtube"],
    });
  });

  it("rejects unknown providers", () => {
    expect(() =>
      parseSearchRequest({ query: "xqc", provider: "trovo" }),
    ).toThrow();
  });
});

describe("search", () => {
  it("binds the youtube secret", () => {
    expect(
      (search as any).__endpoint.secretEnvironmentVariables,
    ).toContainEqual({ key: "youtube-api-key" });
  });

  it("returns only youtube results for provider youtube", async () => {
    const results = await run({ query: "@xqc", provider: "youtube" });
    expect(results.map((r: any) => [r.provider, r.channelId])).toEqual([
      ["youtube", youtubeChannelId],
    ]);
    expect(calledHosts()).toEqual(["www.googleapis.com"]);
  });

  it("returns nothing when youtube fails", async () => {
    secretValue.mockImplementation(() => {
      throw new Error("missing secret");
    });
    expect(await run({ query: "xqc", provider: "youtube" })).toEqual([]);
  });

  it("never searches youtube for other providers or legacy payloads", async () => {
    await run({ query: "xqc", provider: "twitch" });
    await run({ query: "xqc", provider: "kick" });
    await run("xqc");
    expect(calledHosts()).not.toContain("www.googleapis.com");
  });

  it("returns only twitch results for provider twitch", async () => {
    const results = await run({ query: "xqc", provider: "twitch" });
    expect(results.map((r: any) => [r.provider, r.login])).toEqual([
      ["twitch", "xqc"],
      ["twitch", "xqcshadow"],
    ]);
    expect(calledHosts()).not.toContain("api.kick.com");
  });

  it("returns only kick results for provider kick", async () => {
    const results = await run({ query: "xqc", provider: "kick" });
    expect(results.map((r: any) => [r.provider, r.login])).toEqual([
      ["kick", "xqc"],
    ]);
    expect(calledHosts()).not.toContain("api.twitch.tv");
  });

  it("merges twitch and kick for a legacy string payload", async () => {
    const results = await run("xqc");
    expect(results.map((r: any) => [r.provider, r.login])).toEqual([
      ["twitch", "xqc"],
      ["kick", "xqc"],
      ["twitch", "xqcshadow"],
    ]);
  });

  it("returns followed twitch channels for an empty twitch query", async () => {
    const results = await run({ query: "", provider: "twitch" }, { uid: "u" });
    expect(results.map((r: any) => r.login)).toEqual(["muxfd"]);
  });

  it("still returns followed channels for an empty legacy query", async () => {
    const results = await run("", { uid: "u" });
    expect(results.map((r: any) => r.login)).toEqual(["muxfd"]);
  });

  it("returns nothing for an empty kick query", async () => {
    const results = await run({ query: "", provider: "kick" }, { uid: "u" });
    expect(results).toEqual([]);
    expect(calledHosts()).not.toContain("api.twitch.tv");
  });
});
