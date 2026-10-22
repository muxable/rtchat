import { beforeEach, describe, expect, it, vi } from "vitest";

const { fetchMock } = vi.hoisted(() => ({ fetchMock: vi.fn() }));
vi.mock("cross-fetch", () => ({ default: fetchMock }));

import {
  isYouTubeChannelId,
  parseYouTubeQuery,
  searchYouTubeChannel,
  youTubeEmbedUrl,
} from "../src/youtube";

const channelId = "UCabcdefghijklmnopqr12_-";
const channel = {
  id: channelId,
  snippet: {
    title: "Some Creator",
    customUrl: "@Some.Creator",
    thumbnails: {
      default: { url: "https://default" },
      medium: { url: "https://medium" },
    },
  },
};

beforeEach(() => fetchMock.mockReset());

describe("youTubeEmbedUrl", () => {
  it("embeds the channel's live stream muted", () => {
    expect(youTubeEmbedUrl(channelId)).toBe(
      `https://www.youtube.com/embed/live_stream?channel=${channelId}&autoplay=1&mute=1`,
    );
  });

  it("rejects anything that isn't a channel id", () => {
    expect(youTubeEmbedUrl("@creator")).toBeNull();
    expect(youTubeEmbedUrl(`${channelId}&x=1`)).toBeNull();
  });
});

describe("parseYouTubeQuery", () => {
  it.each(["@Some.Creator", "Some.Creator", " some.creator ", "@some_name-12"])(
    "parses handle %s",
    (query) => {
      expect(parseYouTubeQuery(query)).toEqual({
        handle: query.trim().replace(/^@/, "").toLowerCase(),
      });
    },
  );

  it.each([
    "https://www.youtube.com/@Some.Creator",
    "youtube.com/@Some.Creator/",
    "https://m.youtube.com/@Some.Creator?view=1#about",
    "https://youtube.com/%40Some.Creator",
  ])("parses handle URL %s", (query) => {
    expect(parseYouTubeQuery(query)).toEqual({ handle: "some.creator" });
  });

  it.each([
    channelId,
    ` ${channelId} `,
    `https://youtube.com/channel/${channelId}`,
    `www.youtube.com/channel/${channelId}/?view=1`,
  ])("parses channel id %s without treating it as a handle", (query) => {
    expect(parseYouTubeQuery(query)).toEqual({ channelId });
  });

  it.each([
    "",
    "@",
    "two words",
    "some/name",
    "@bad!",
    "https://example.com/@creator",
    "https://youtube.com.evil.com/@creator",
    "https://youtube.com/watch?v=123",
    "https://youtube.com/channel/UCshort",
    "https://youtube.com/@creator/extra",
    "https://youtube.com/@%ZZ",
    "https://youtube.com/@creator%2Fextra",
  ])("rejects junk %s", (query) => {
    expect(parseYouTubeQuery(query)).toBeNull();
  });

  it.each([null, 123, {}, "UCshort", channelId + "x", channelId.toLowerCase()])(
    "rejects invalid channel id %s",
    (value) => expect(isYouTubeChannelId(value)).toBe(false),
  );
  it("validates channel ids", () => {
    expect(isYouTubeChannelId(channelId)).toBe(true);
  });
});

describe("searchYouTubeChannel", () => {
  it("finds a handle with one channels.list request", async () => {
    fetchMock.mockResolvedValue({
      ok: true,
      json: async () => ({ items: [channel] }),
    });
    await expect(
      searchYouTubeChannel("key&value", "@Some.Creator"),
    ).resolves.toEqual([
      {
        provider: "youtube",
        channelId,
        login: "some.creator",
        displayName: "Some Creator",
        imageUrl: "https://default",
        isOnline: false,
      },
    ]);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const url = new URL(fetchMock.mock.calls[0][0]);
    expect(url.origin + url.pathname).toBe(
      "https://www.googleapis.com/youtube/v3/channels",
    );
    expect(Object.fromEntries(url.searchParams)).toEqual({
      part: "snippet",
      key: "key&value",
      forHandle: "@some.creator",
    });
  });

  it("resolves an id and falls back to a medium thumbnail", async () => {
    fetchMock.mockResolvedValue({
      ok: true,
      json: async () => ({
        items: [
          {
            ...channel,
            snippet: {
              ...channel.snippet,
              thumbnails: { medium: { url: "https://medium" } },
            },
          },
        ],
      }),
    });
    const results = await searchYouTubeChannel(
      "key",
      `youtube.com/channel/${channelId}`,
    );
    expect(results[0]).toMatchObject({
      channelId,
      login: "some.creator",
      imageUrl: "https://medium",
    });
    const params = new URL(fetchMock.mock.calls[0][0]).searchParams;
    expect(params.get("id")).toBe(channelId);
    expect(params.has("forHandle")).toBe(false);
  });

  it("uses the requested handle when customUrl is absent", async () => {
    fetchMock.mockResolvedValue({
      ok: true,
      json: async () => ({
        items: [
          {
            id: channelId,
            snippet: { title: "Creator" },
          },
        ],
      }),
    });
    expect(await searchYouTubeChannel("key", "@Creator")).toMatchObject([
      { login: "creator", imageUrl: "" },
    ]);
    expect(await searchYouTubeChannel("key", channelId)).toMatchObject([
      { login: channelId.toLowerCase() },
    ]);
  });

  it("skips invalid queries and missing keys", async () => {
    expect(await searchYouTubeChannel("key", "two words")).toEqual([]);
    expect(await searchYouTubeChannel("", "creator")).toEqual([]);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("returns nothing for missing channels or malformed responses", async () => {
    for (const body of [{ items: [] }, {}, { items: [{ id: "bad" }] }, null]) {
      fetchMock.mockResolvedValueOnce({ ok: true, json: async () => body });
      expect(await searchYouTubeChannel("key", "creator")).toEqual([]);
    }
  });

  it("returns nothing on API, network, and JSON errors", async () => {
    fetchMock.mockResolvedValueOnce({ ok: false, status: 403 });
    expect(await searchYouTubeChannel("key", "creator")).toEqual([]);
    fetchMock.mockRejectedValueOnce(new Error("unreachable"));
    expect(await searchYouTubeChannel("key", "creator")).toEqual([]);
    fetchMock.mockResolvedValueOnce({
      ok: true,
      json: async () => {
        throw new Error("invalid JSON");
      },
    });
    expect(await searchYouTubeChannel("key", "creator")).toEqual([]);
  });
});

describe("searchYouTubeChannel caching", () => {
  it("only spends quota once per handle, including misses", async () => {
    const store = new Map<string, any>();
    const cache = {
      get: async (key: string) => store.get(key),
      set: async (key: string, results: any) => {
        store.set(key, results);
      },
    };
    fetchMock.mockResolvedValue({
      ok: true,
      json: async () => ({ items: [] }),
    });
    expect(await searchYouTubeChannel("key", "@nobody", cache)).toEqual([]);
    expect(await searchYouTubeChannel("key", "@NoBody", cache)).toEqual([]);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
});
