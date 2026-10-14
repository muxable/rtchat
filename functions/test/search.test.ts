import { beforeEach, describe, expect, it, vi } from "vitest";

const { fetch } = vi.hoisted(() => ({ fetch: vi.fn() }));

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
vi.mock("firebase-admin", () => ({
  firestore: () => ({
    collection: () => ({
      doc: () => ({
        get: async () => ({ data: () => ({ twitch: { id: "1234" } }) }),
      }),
    }),
  }),
}));

import { parseSearchRequest, search } from "../src/search";

const json = (body: any) => ({
  ok: true,
  status: 200,
  json: async () => body,
  text: async () => JSON.stringify(body),
});

beforeEach(() => {
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

  it("rejects unknown providers", () => {
    expect(() =>
      parseSearchRequest({ query: "xqc", provider: "youtube" })
    ).toThrow();
  });
});

describe("search", () => {
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
