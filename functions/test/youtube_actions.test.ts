import { beforeEach, describe, expect, it, vi } from "vitest";

const { fetchMock, userToken, profile } = vi.hoisted(() => ({
  fetchMock: vi.fn(),
  userToken: vi.fn(),
  profile: { youtube: undefined as { id: string } | undefined },
}));

vi.mock("cross-fetch", () => ({ default: fetchMock }));
vi.mock("../src/oauth", () => ({ getAccessToken: userToken }));
vi.mock("firebase-admin", () => ({
  firestore: () => ({
    collection: () => ({
      doc: () => ({
        get: async () => ({
          get: (key: "youtube") => profile[key],
        }),
      }),
    }),
  }),
}));

import {
  banYouTubeUser,
  clearLiveChatCache,
  deleteYouTubeMessage,
  findLiveVideoId,
  getYouTubeProfile,
  parseVideoId,
  QUOTA_EXCEEDED_MESSAGE,
  sendYouTubeMessage,
  toHttpsError,
} from "../src/youtube_actions";

const OWN = "UC" + "a".repeat(22);
const OTHER = "UC" + "b".repeat(22);
const VIEWER = "UC" + "c".repeat(22);
const VIDEO = "dQw4w9WgXcQ";

function json(body: unknown, status = 200) {
  return {
    ok: status >= 200 && status < 300,
    status,
    text: async () => (body == null ? "" : JSON.stringify(body)),
  };
}

function html(body: string, status = 200) {
  return { ok: status === 200, status, text: async () => body };
}

function apiError(status: number, reason: string) {
  return json(
    { error: { code: status, message: reason, errors: [{ reason }] } },
    status,
  );
}

const liveBroadcasts = json({
  items: [{ snippet: { channelId: OWN, liveChatId: "own-chat" } }],
});

// fetchMock answers by URL so tests read as a list of api responses.
function route(routes: Record<string, any>) {
  fetchMock.mockImplementation(async (url: string) => {
    for (const [prefix, response] of Object.entries(routes)) {
      if (url.includes(prefix)) {
        return typeof response === "function" ? response(url) : response;
      }
    }
    throw new Error(`unexpected fetch ${url}`);
  });
}

const calls = (part: string) =>
  fetchMock.mock.calls.filter(([url]) => String(url).includes(part));
const body = (part: string, i = 0) => JSON.parse(calls(part)[i][1].body);

beforeEach(() => {
  fetchMock.mockReset();
  userToken.mockReset().mockResolvedValue("user-token");
  profile.youtube = { id: OWN };
  clearLiveChatCache();
});

describe("toHttpsError", () => {
  it("maps quota errors to resource-exhausted with a readable message", () => {
    const err = toHttpsError(403, {
      error: { errors: [{ reason: "quotaExceeded", domain: "youtube.quota" }] },
    });
    expect(err.code).toBe("resource-exhausted");
    expect(err.message).toBe(QUOTA_EXCEEDED_MESSAGE);
    expect(err.details).toEqual({
      provider: "youtube",
      reason: "quotaExceeded",
      status: 403,
    });
    expect(
      toHttpsError(403, {
        error: { errors: [{ reason: "rateLimitExceeded" }] },
      }).code,
    ).toBe("resource-exhausted");
  });

  it("maps ended chats, auth and permission errors", () => {
    const reason = (r: string) => ({ error: { errors: [{ reason: r }] } });
    expect(toHttpsError(403, reason("liveChatEnded")).code).toBe(
      "failed-precondition",
    );
    expect(toHttpsError(404, reason("liveChatNotFound")).code).toBe(
      "failed-precondition",
    );
    expect(toHttpsError(401, reason("authError")).code).toBe("unauthenticated");
    expect(toHttpsError(403, reason("forbidden")).code).toBe(
      "permission-denied",
    );
    expect(toHttpsError(404, null).code).toBe("not-found");
    expect(toHttpsError(503, null).code).toBe("unavailable");
    expect(toHttpsError(400, null).code).toBe("internal");
  });
});

describe("getYouTubeProfile", () => {
  it("reads the signed-in user's channel", async () => {
    route({
      "/channels?part=snippet&mine=true": json({
        items: [
          {
            id: OWN,
            snippet: {
              title: "Some Streamer",
              customUrl: "@somestreamer",
              thumbnails: { default: { url: "https://yt3/a.jpg" } },
            },
          },
        ],
      }),
    });
    await expect(getYouTubeProfile("token")).resolves.toEqual({
      id: OWN,
      displayName: "Some Streamer",
      login: "@somestreamer",
      profilePictureUrl: "https://yt3/a.jpg",
      email: null,
    });
    expect(fetchMock.mock.calls[0][1].headers.Authorization).toBe(
      "Bearer token",
    );
  });

  it("returns null for accounts without a channel", async () => {
    route({ "/channels": json({ items: [] }) });
    await expect(getYouTubeProfile("token")).resolves.toBeNull();
  });
});

describe("findLiveVideoId", () => {
  it("reads the canonical watch link of the /live page", async () => {
    route({
      [`/channel/${OTHER}/live`]: html(
        `<html><head><link rel="canonical" href="https://www.youtube.com/watch?v=${VIDEO}"></head></html>`,
      ),
    });
    await expect(findLiveVideoId(OTHER)).resolves.toBe(VIDEO);
  });

  it("returns null when the channel isn't live", async () => {
    route({
      "/live": html(
        `<link rel="canonical" href="https://www.youtube.com/channel/${OTHER}">`,
      ),
    });
    await expect(findLiveVideoId(OTHER)).resolves.toBeNull();
  });
});

describe("sendYouTubeMessage", () => {
  it("sends to the user's own active broadcast", async () => {
    route({
      "/liveBroadcasts": liveBroadcasts,
      "/liveChat/messages": json({ id: "msg-1" }),
    });
    await expect(sendYouTubeMessage("uid", OWN, "hello")).resolves.toBe(
      "youtube:msg-1",
    );
    expect(userToken).toHaveBeenCalledWith("uid", "youtube");
    expect(calls("/liveBroadcasts")[0][0]).toContain("broadcastStatus=active");
    expect(calls("/liveChat/messages")[0][1].method).toBe("POST");
    expect(body("/liveChat/messages")).toEqual({
      snippet: {
        liveChatId: "own-chat",
        type: "textMessageEvent",
        textMessageDetails: { messageText: "hello" },
      },
    });
  });

  it("finds another channel's chat through its live video", async () => {
    route({
      [`/channel/${OTHER}/live`]: html(
        `<link rel="canonical" href="https://www.youtube.com/watch?v=${VIDEO}">`,
      ),
      "/videos?": json({
        items: [
          {
            snippet: { channelId: OTHER },
            liveStreamingDetails: { activeLiveChatId: "other-chat" },
          },
        ],
      }),
      "/liveChat/messages": json({ id: "msg-2" }),
    });
    await sendYouTubeMessage("uid", OTHER, "hi");
    expect(calls("/liveBroadcasts")).toHaveLength(0);
    expect(calls("/videos?")[0][0]).toContain(`id=${VIDEO}`);
    expect(body("/liveChat/messages").snippet.liveChatId).toBe("other-chat");
  });

  it("uses a given video id without scraping", async () => {
    route({
      "/videos?": json({
        items: [{ liveStreamingDetails: { activeLiveChatId: "video-chat" } }],
      }),
      "/liveChat/messages": json({ id: "m" }),
    });
    await sendYouTubeMessage("uid", OTHER, "hi", VIDEO);
    expect(calls("youtube.com/channel")).toHaveLength(0);
    expect(body("/liveChat/messages").snippet.liveChatId).toBe("video-chat");
  });

  it("caches the live chat id until youtube says the chat ended", async () => {
    let ended = false;
    route({
      "/liveBroadcasts": liveBroadcasts,
      "/liveChat/messages": () =>
        ended ? apiError(403, "liveChatEnded") : json({ id: "m" }),
    });
    await sendYouTubeMessage("uid", OWN, "one");
    await sendYouTubeMessage("uid", OWN, "two");
    expect(calls("/liveBroadcasts")).toHaveLength(1);

    ended = true;
    await expect(sendYouTubeMessage("uid", OWN, "three")).rejects.toMatchObject(
      { code: "failed-precondition" },
    );
    ended = false;
    await sendYouTubeMessage("uid", OWN, "four");
    expect(calls("/liveBroadcasts")).toHaveLength(2);
  });

  it("surfaces quota exhaustion", async () => {
    route({
      "/liveBroadcasts": liveBroadcasts,
      "/liveChat/messages": apiError(403, "quotaExceeded"),
    });
    await expect(sendYouTubeMessage("uid", OWN, "hi")).rejects.toMatchObject({
      code: "resource-exhausted",
      message: QUOTA_EXCEEDED_MESSAGE,
    });
  });

  it("fails clearly when the channel isn't live", async () => {
    route({
      "/liveBroadcasts": json({ items: [] }),
      [`/channel/${OWN}/live`]: html(""),
    });
    await expect(sendYouTubeMessage("uid", OWN, "hi")).rejects.toMatchObject({
      code: "failed-precondition",
      message: "This YouTube channel isn't live.",
    });
  });

  it("validates input and requires a linked account", async () => {
    await expect(sendYouTubeMessage("uid", "nope", "hi")).rejects.toThrow(
      /invalid channel/,
    );
    await expect(
      sendYouTubeMessage("uid", OWN, "x".repeat(201)),
    ).rejects.toThrow(/at most 200/);
    userToken.mockResolvedValue(null);
    await expect(sendYouTubeMessage("uid", OWN, "hi")).rejects.toThrow(
      /not linked/,
    );
    expect(fetchMock).not.toHaveBeenCalled();
  });
});

describe("deleteYouTubeMessage", () => {
  it("deletes by youtube message id", async () => {
    route({ "/liveChat/messages": json(null, 204) });
    await deleteYouTubeMessage("uid", "youtube:LCC.abc");
    expect(calls("/liveChat/messages")[0][0]).toBe(
      "https://www.googleapis.com/youtube/v3/liveChat/messages?id=LCC.abc",
    );
    expect(calls("/liveChat/messages")[0][1].method).toBe("DELETE");
  });

  it("maps quota errors", async () => {
    route({ "/liveChat/messages": apiError(403, "quotaExceeded") });
    await expect(
      deleteYouTubeMessage("uid", "youtube:x"),
    ).rejects.toMatchObject({ code: "resource-exhausted" });
  });
});

describe("banYouTubeUser", () => {
  it("bans permanently or temporarily", async () => {
    route({
      "/liveBroadcasts": liveBroadcasts,
      "/liveChat/bans": json({ id: "ban-1" }),
    });
    await expect(banYouTubeUser("uid", OWN, VIEWER)).resolves.toBe("ban-1");
    expect(calls("/liveChat/bans")[0][0]).toContain("part=snippet");
    expect(body("/liveChat/bans")).toEqual({
      snippet: {
        liveChatId: "own-chat",
        type: "permanent",
        bannedUserDetails: { channelId: VIEWER },
      },
    });

    await banYouTubeUser("uid", OWN, VIEWER, { durationSeconds: 300 });
    expect(body("/liveChat/bans", 1)).toEqual({
      snippet: {
        liveChatId: "own-chat",
        type: "temporary",
        banDurationSeconds: 300,
        bannedUserDetails: { channelId: VIEWER },
      },
    });
  });

  it("needs youtube channel ids", async () => {
    await expect(banYouTubeUser("uid", OWN, "someone")).rejects.toThrow(
      /invalid user/,
    );
  });
});

describe("parseVideoId", () => {
  it("accepts video ids and nothing else", () => {
    expect(parseVideoId(undefined)).toBeUndefined();
    expect(parseVideoId(VIDEO)).toBe(VIDEO);
    expect(() => parseVideoId("../x")).toThrow(/invalid videoId/);
  });
});
