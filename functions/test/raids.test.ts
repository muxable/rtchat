import { beforeEach, describe, expect, it, vi } from "vitest";

const { fetch, store } = vi.hoisted(() => ({
  fetch: vi.fn(),
  store: new Map<string, Record<string, any>>(),
}));

vi.mock("cross-fetch", () => ({ default: fetch }));
vi.mock("../src/oauth", () => ({
  TWITCH_CLIENT_ID: "twitch-id",
  getAccessToken: async () => "user-token",
  getAppAccessToken: async () => ({ token: { access_token: "app-token" } }),
}));

// A tiny in-memory stand-in for the parts of Firestore these functions use.
vi.mock("firebase-admin", () => {
  class Timestamp {
    constructor(private millis: number) {}
    static fromMillis(millis: number) {
      return new Timestamp(millis);
    }
    toMillis() {
      return this.millis;
    }
  }
  const docRef = (path: string): any => ({
    id: path.split("/").pop(),
    collection: (name: string) => collection(`${path}/${name}`),
    get: async () => {
      const data = store.get(path);
      return {
        exists: data !== undefined,
        data: () => data,
        get: (field: string) => data?.[field],
      };
    },
    create: async (data: Record<string, any>) => {
      if (store.has(path)) {
        throw Object.assign(new Error("already exists"), { code: 6 });
      }
      store.set(path, data);
    },
    set: async (data: Record<string, any>, options?: { merge?: boolean }) => {
      store.set(
        path,
        options?.merge ? { ...store.get(path), ...data } : { ...data }
      );
    },
  });
  const collection = (name: string) => ({
    doc: (id: string) => docRef(`${name}/${id}`),
  });
  const firestore: any = () => ({ collection });
  firestore.Timestamp = Timestamp;
  return { firestore };
});

import {
  RAID_COUNTDOWN_SECONDS,
  recordRaidCancel,
  recordRaidGo,
  toRaid,
  toRaidDocument,
  toRaidGoDocuments,
} from "../src/raids";
import { cancelRaid, raid } from "../src/twitch";

const target = { id: "456", login: "target", displayName: "Target" };
const startedAt = Date.parse("2026-10-14T01:00:00Z");
const now = Date.parse("2026-10-14T01:00:05Z");

const messages = (channelId: string) =>
  [...store.entries()]
    .filter(([path]) => path.startsWith(`channels/${channelId}/messages/`))
    .map(([path, data]) => ({ id: path.split("/").pop(), ...data }));

function response(status: number, body?: any) {
  return { status, ok: status < 300, json: async () => body };
}

beforeEach(() => {
  fetch.mockReset();
  store.clear();
  store.set("profiles/uid", { twitch: { id: "123" } });
});

describe("documents", () => {
  it("builds the raid the app's TwitchRaidingEventModel reads", () => {
    expect(toRaid(target, startedAt)).toEqual({
      id: `456-${startedAt}`,
      target_id: "456",
      target_login: "target",
      target_display_name: "Target",
      force_raid_now_seconds: 90,
    });
    expect(RAID_COUNTDOWN_SECONDS).toBe(90);
  });

  it("keys raid events by type and raid id", () => {
    const r = toRaid(target, startedAt);
    const doc = toRaidDocument("raid_update_v2", "123", r, startedAt, now);
    expect(doc.id).toBe(`raid_update_v2-456-${startedAt}`);
    expect(doc.data.type).toBe("raid_update_v2");
    expect(doc.data.channelId).toBe("twitch:123");
    expect(doc.data.raid).toEqual(r);
    expect((doc.data.timestamp as any).toMillis()).toBe(startedAt);
    expect((doc.data.expiresAt as any).toMillis()).toBe(
      now + 14 * 86400 * 1000
    );
  });

  const event = {
    from_broadcaster_user_id: "123",
    to_broadcaster_user_id: "456",
    to_broadcaster_user_login: "target",
    to_broadcaster_user_name: "Target",
    viewers: 10,
  };

  it("completes the raid started from the app", () => {
    const pending = toRaid(target, startedAt);
    const docs = toRaidGoDocuments("123", pending, event, now, now);
    expect(docs.map((d) => d.id)).toEqual([`raid_go_v2-${pending.id}`]);
    expect(docs[0].data.raid).toEqual(pending);
  });

  it("writes a start alongside raids started outside the app", () => {
    const other = toRaid({ ...target, id: "789" }, startedAt);
    for (const pending of [undefined, other]) {
      const [update, go] = toRaidGoDocuments("123", pending, event, now, now);
      expect(update.data.type).toBe("raid_update_v2");
      expect(update.data.raid).toEqual(toRaid(target, now, 0));
      expect((update.data.timestamp as any).toMillis()).toBe(now);
      // ordered after the start so the app applies it to the start.
      expect(go.data.type).toBe("raid_go_v2");
      expect(go.data.raid).toEqual(update.data.raid);
      expect((go.data.timestamp as any).toMillis()).toBe(now + 1);
    }
  });
});

describe("raid", () => {
  it("writes the countdown when twitch starts the raid", async () => {
    fetch
      .mockResolvedValueOnce(
        response(200, {
          data: [{ created_at: "2026-10-14T01:00:00Z", is_mature: false }],
        })
      )
      .mockResolvedValueOnce(
        response(200, {
          data: [{ id: "456", login: "target", display_name: "Target" }],
        })
      );

    await raid("uid", "123", "456");
    expect(fetch.mock.calls[0][0]).toBe(
      "https://api.twitch.tv/helix/raids?from_broadcaster_id=123&to_broadcaster_id=456"
    );
    expect(fetch.mock.calls[1][0]).toBe(
      "https://api.twitch.tv/helix/users?id=456"
    );
    const docs = messages("twitch:123");
    expect(docs).toHaveLength(1);
    expect(docs[0].id).toBe(`raid_update_v2-456-${startedAt}`);
    expect(docs[0].raid).toEqual(toRaid(target, startedAt));
    expect(store.get("channels/twitch:123")?.outgoingRaid).toEqual(
      toRaid(target, startedAt)
    );
  });

  it("doesn't write anything when twitch rejects the raid", async () => {
    fetch.mockResolvedValueOnce(
      response(409, { status: 409, message: "already raiding" })
    );
    await expect(raid("uid", "123", "456")).resolves.toEqual({
      status: 409,
      message: "already raiding",
    });
    expect(store.has("channels/twitch:123")).toBe(false);
  });
});

describe("completion", () => {
  it("marks the pending raid as gone and clears it", async () => {
    store.set("channels/twitch:123", {
      outgoingRaid: toRaid(target, startedAt),
    });
    const event = {
      from_broadcaster_user_id: "123",
      to_broadcaster_user_id: "456",
      to_broadcaster_user_login: "target",
      to_broadcaster_user_name: "Target",
    };
    await recordRaidGo(event, now, "m1");
    // twitch redelivers notifications.
    await recordRaidGo(event, now + 1000, "m1");
    expect(messages("twitch:123").map((d) => d.id)).toEqual([
      `raid_go_v2-456-${startedAt}`,
    ]);
    expect(store.get("channels/twitch:123")?.outgoingRaid).toBeNull();
    expect(messages("twitch:456")).toEqual([]);
  });

  it("completes raids started outside the app once", async () => {
    const event = {
      from_broadcaster_user_id: "123",
      to_broadcaster_user_id: "456",
      to_broadcaster_user_login: "target",
      to_broadcaster_user_name: "Target",
    };
    await recordRaidGo(event, now, "m1");
    await recordRaidGo(event, now + 1000, "m1");
    expect(messages("twitch:123").map((d) => d.id)).toEqual([
      `raid_update_v2-456-${now}`,
      `raid_go_v2-456-${now}`,
    ]);
  });
});

describe("cancelRaid", () => {
  it("writes the cancellation when twitch cancels the raid", async () => {
    store.set("channels/twitch:123", {
      outgoingRaid: toRaid(target, startedAt),
    });
    fetch.mockResolvedValueOnce(response(204));
    await cancelRaid("uid", "123");
    expect(fetch.mock.calls[0][0]).toBe(
      "https://api.twitch.tv/helix/raids?broadcaster_id=123"
    );
    expect(fetch.mock.calls[0][1].method).toBe("DELETE");
    const docs = messages("twitch:123");
    expect(docs.map((d) => d.id)).toEqual([`raid_cancel_v2-456-${startedAt}`]);
    expect(docs[0].raid).toEqual(toRaid(target, startedAt));
    expect(store.get("channels/twitch:123")?.outgoingRaid).toBeNull();
  });

  it("doesn't write anything when twitch rejects the cancel", async () => {
    store.set("channels/twitch:123", {
      outgoingRaid: toRaid(target, startedAt),
    });
    fetch.mockResolvedValueOnce(response(404, { status: 404 }));
    await cancelRaid("uid", "123");
    expect(messages("twitch:123")).toEqual([]);
  });

  it("ignores cancels without a pending raid", async () => {
    await recordRaidCancel("123", now);
    expect(messages("twitch:123")).toEqual([]);
  });
});
