import { beforeEach, describe, expect, it, vi } from "vitest";

const { fetchMock } = vi.hoisted(() => ({ fetchMock: vi.fn() }));
vi.mock("cross-fetch", () => ({ default: fetchMock }));

import {
  codeChallenge,
  createCodeVerifier,
  getKickProfile,
  getKickSlug,
  isKickSlug,
  kickApi,
  searchKickChannel,
  toKickProfile,
  toSearchResult,
} from "../src/kick";

function jsonResponse(status: number, body: unknown) {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: async () => body,
    text: async () => JSON.stringify(body),
  };
}

beforeEach(() => fetchMock.mockReset());

describe("pkce", () => {
  it("matches the RFC 7636 example", () => {
    expect(codeChallenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")).toBe(
      "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
    );
  });

  it("creates url-safe verifiers of a valid length", () => {
    const verifier = createCodeVerifier();
    expect(verifier).toMatch(/^[A-Za-z0-9_-]{43,128}$/);
    expect(createCodeVerifier()).not.toBe(verifier);
  });
});

describe("toKickProfile", () => {
  it("combines the user and their channel", () => {
    expect(
      toKickProfile(
        {
          user_id: 123,
          name: "Muxfd",
          email: "m@example.com",
          profile_picture: "https://files.kick.com/p.png",
        },
        { broadcaster_user_id: 123, slug: "muxfd" }
      )
    ).toEqual({
      id: "123",
      slug: "muxfd",
      displayName: "Muxfd",
      profilePictureUrl: "https://files.kick.com/p.png",
      email: "m@example.com",
    });
  });

  it("falls back when optional fields are missing", () => {
    expect(toKickProfile({ user_id: 5, name: "SomeOne" }, undefined)).toEqual({
      id: "5",
      slug: "someone",
      displayName: "SomeOne",
      profilePictureUrl: null,
      email: null,
    });
  });
});

describe("kickApi", () => {
  it("sends the bearer token and parses json", async () => {
    fetchMock.mockResolvedValue(jsonResponse(200, { data: [1] }));
    await expect(kickApi("tok", "/users")).resolves.toEqual({ data: [1] });
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("https://api.kick.com/public/v1/users");
    expect(init.headers.Authorization).toBe("Bearer tok");
  });

  it("returns null for 204 and throws on errors", async () => {
    fetchMock.mockResolvedValueOnce(jsonResponse(204, null));
    await expect(
      kickApi("tok", "/chat/1", { method: "DELETE" })
    ).resolves.toBeNull();
    fetchMock.mockResolvedValueOnce(jsonResponse(401, { message: "nope" }));
    await expect(kickApi("tok", "/users")).rejects.toThrow(/401/);
  });

  it("looks up the profile for a token", async () => {
    fetchMock
      .mockResolvedValueOnce(
        jsonResponse(200, { data: [{ user_id: 7, name: "Kicker" }] })
      )
      .mockResolvedValueOnce(
        jsonResponse(200, {
          data: [{ broadcaster_user_id: 7, slug: "kicker" }],
        })
      );
    await expect(getKickProfile("tok")).resolves.toMatchObject({
      id: "7",
      slug: "kicker",
    });
  });
});

describe("search", () => {
  it("only looks up plausible slugs", async () => {
    expect(isKickSlug("xQc")).toBe(true);
    expect(isKickSlug(" muxfd ")).toBe(true);
    expect(isKickSlug("two words")).toBe(false);
    expect(isKickSlug("a")).toBe(false);
    await expect(searchKickChannel("app", "two words")).resolves.toEqual([]);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("finds a channel by slug with its owner's picture", async () => {
    fetchMock
      .mockResolvedValueOnce(
        jsonResponse(200, {
          data: [
            {
              broadcaster_user_id: 7,
              slug: "muxfd",
              stream_title: "irl",
              category: { name: "IRL" },
              stream: { is_live: true, viewer_count: 12, language: "en" },
            },
          ],
        })
      )
      .mockResolvedValueOnce(
        jsonResponse(200, {
          data: [{ user_id: 7, name: "MuxFD", profile_picture: "https://p" }],
        })
      );
    const results = await searchKickChannel("app", "MuxFD");
    expect(fetchMock.mock.calls[0][0]).toBe(
      "https://api.kick.com/public/v1/channels?slug=muxfd"
    );
    expect(results).toEqual([
      {
        provider: "kick",
        channelId: "7",
        login: "muxfd",
        displayName: "MuxFD",
        isOnline: true,
        imageUrl: "https://p",
        categoryName: "IRL",
        title: "irl",
        viewerCount: 12,
        language: "en",
      },
    ]);
  });

  it("returns nothing for unknown slugs", async () => {
    fetchMock.mockResolvedValueOnce(jsonResponse(200, { data: [] }));
    await expect(searchKickChannel("app", "nobody")).resolves.toEqual([]);
  });

  it("maps channel ids to slugs for the embed", async () => {
    fetchMock.mockResolvedValueOnce(
      jsonResponse(200, { data: [{ broadcaster_user_id: 7, slug: "muxfd" }] })
    );
    await expect(getKickSlug("app", "7")).resolves.toBe("muxfd");
    expect(toSearchResult({ broadcaster_user_id: 1, slug: "x" }).imageUrl).toBe(
      "https://rtirl.com/pfp.png?provider=kick&channelId=1"
    );
  });
});
