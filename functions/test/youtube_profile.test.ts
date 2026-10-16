import { beforeEach, describe, expect, it, vi } from "vitest";
const { fetchMock } = vi.hoisted(() => ({ fetchMock: vi.fn() }));
vi.mock("cross-fetch", () => ({ default: fetchMock }));
import {
  getYouTubeProfile,
  toHttpsError,
  QUOTA_EXCEEDED_MESSAGE,
} from "../src/youtube_profile";
const OWN = "UC" + "a".repeat(22);
function json(body: unknown, status = 200) {
  return {
    ok: status >= 200 && status < 300,
    status,
    text: async () => (body == null ? "" : JSON.stringify(body)),
  };
}
function route(routes: Record<string, any>) {
  fetchMock.mockImplementation(async (url: string) => {
    for (const [prefix, response] of Object.entries(routes))
      if (url.includes(prefix)) return response;
    throw new Error(`unexpected fetch ${url}`);
  });
}
beforeEach(() => {
  fetchMock.mockReset();
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
      }).code
    ).toBe("resource-exhausted");
  });

  it("maps ended chats, auth and permission errors", () => {
    const reason = (r: string) => ({ error: { errors: [{ reason: r }] } });
    expect(toHttpsError(403, reason("liveChatEnded")).code).toBe(
      "failed-precondition"
    );
    expect(toHttpsError(404, reason("liveChatNotFound")).code).toBe(
      "failed-precondition"
    );
    expect(toHttpsError(401, reason("authError")).code).toBe("unauthenticated");
    expect(toHttpsError(403, reason("forbidden")).code).toBe(
      "permission-denied"
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
      "Bearer token"
    );
  });

  it("returns null for accounts without a channel", async () => {
    route({ "/channels": json({ items: [] }) });
    await expect(getYouTubeProfile("token")).resolves.toBeNull();
  });
});
