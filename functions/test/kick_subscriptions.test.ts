import { beforeEach, describe, expect, it, vi } from "vitest";

const { kickApi, store } = vi.hoisted(() => ({
  kickApi: vi.fn(),
  store: new Map<string, Record<string, any>>(),
}));

vi.mock("../src/kick", () => ({ kickApi }));
vi.mock("../src/oauth", () => ({
  getAppAccessToken: async () => ({ token: { access_token: "app-token" } }),
}));

// A tiny in-memory stand-in for the parts of Firestore these functions use.
vi.mock("firebase-admin", () => {
  const SERVER_TIME = { serverTime: true };
  class Timestamp {
    constructor(private millis: number) {}
    static fromMillis(millis: number) {
      return new Timestamp(millis);
    }
    toMillis() {
      return this.millis;
    }
  }
  const resolve = (value: any) =>
    value === SERVER_TIME ? Timestamp.fromMillis(Date.now()) : value;
  const docRef = (path: string) => ({
    id: path.split("/").pop(),
    get: async () => {
      const data = store.get(path);
      return {
        id: path.split("/").pop(),
        exists: data !== undefined,
        data: () => data,
        get: (field: string) => data?.[field],
      };
    },
    set: async (data: Record<string, any>) => {
      store.set(
        path,
        Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, resolve(v)]),
        ),
      );
    },
    update: async (data: Record<string, any>) => {
      const current = store.get(path) ?? {};
      for (const [k, v] of Object.entries(data)) current[k] = resolve(v);
      store.set(path, current);
    },
    delete: async () => {
      store.delete(path);
    },
  });
  const collection = (name: string) => ({
    doc: (id: string) => docRef(`${name}/${id}`),
    count: () => ({
      get: async () => ({
        data: () => ({
          count: [...store.keys()].filter((k) => k.startsWith(`${name}/`))
            .length,
        }),
      }),
    }),
    where: (field: string, op: string, value: Timestamp) => ({
      get: async () => {
        const docs = [...store.entries()]
          .filter(([k]) => k.startsWith(`${name}/`))
          .filter(([, data]) =>
            op === "<"
              ? data[field].toMillis() < value.toMillis()
              : data[field].toMillis() > value.toMillis(),
          )
          .map(([k]) => ({ id: k.split("/").pop() }));
        return { docs, empty: docs.length === 0 };
      },
    }),
  });
  const firestore: any = () => ({ collection });
  firestore.FieldValue = { serverTimestamp: () => SERVER_TIME };
  firestore.Timestamp = Timestamp;
  return { firestore };
});

import {
  chunk,
  ensureKickSubscriptions,
  KICK_EVENTS,
  missingEvents,
  removeIdleKickSubscriptions,
  toChannelMetadata,
} from "../src/kick_subscriptions";

function subscribed(events: string[]) {
  return events.map((event, i) => ({ id: `sub-${i}`, event, version: 1 }));
}

beforeEach(() => {
  kickApi.mockReset();
  store.clear();
  vi.useRealTimers();
});

describe("helpers", () => {
  it("finds events that aren't subscribed yet", () => {
    expect(missingEvents([])).toEqual(KICK_EVENTS);
    expect(missingEvents(subscribed(KICK_EVENTS.map((e) => e.name)))).toEqual(
      [],
    );
    expect(
      missingEvents([{ id: "x", event: "chat.message.sent", version: 2 }]),
    ).toContainEqual({ name: "chat.message.sent", version: 1 });
  });

  it("chunks requests to kick's 50 item limit", () => {
    const ids = Array.from({ length: 120 }, (_, i) => i);
    expect(chunk(ids, 50).map((c) => c.length)).toEqual([50, 50, 20]);
  });

  it("maps channel metadata", () => {
    expect(
      toChannelMetadata({
        broadcaster_user_id: 1,
        slug: "muxfd",
        stream_title: "irl",
        category: { id: 15, name: "IRL" },
        stream: {
          is_live: true,
          viewer_count: 42,
          language: "en",
          start_time: "2025-01-14T16:08:06Z",
        },
      }),
    ).toEqual({
      login: "muxfd",
      title: "irl",
      language: "en",
      categoryId: 15,
      categoryName: "IRL",
      viewerCount: 42,
      onlineAt: new Date("2025-01-14T16:08:06Z"),
    });
    const offline = toChannelMetadata({
      slug: "x",
      stream: { is_live: false, start_time: "0001-01-01T00:00:00Z" },
    });
    expect(offline.viewerCount).toBe(0);
    expect(offline.onlineAt).toBeNull();
  });
});

describe("ensureKickSubscriptions", () => {
  it("subscribes a new channel to every event", async () => {
    kickApi.mockResolvedValueOnce({ data: [] }).mockResolvedValueOnce({
      data: KICK_EVENTS.map((e, i) => ({
        name: e.name,
        version: 1,
        subscription_id: `new-${i}`,
      })),
    });
    await ensureKickSubscriptions("123");

    const [listPath] = kickApi.mock.calls[0].slice(1);
    expect(listPath).toBe("/events/subscriptions?broadcaster_user_id=123");
    const [, path, init] = kickApi.mock.calls[1];
    expect(path).toBe("/events/subscriptions");
    expect(JSON.parse(init.body)).toEqual({
      broadcaster_user_id: 123,
      events: KICK_EVENTS,
      method: "webhook",
    });
    expect(store.get("webhooks/kick:123")!.subscriptionIds).toHaveLength(
      KICK_EVENTS.length,
    );
  });

  it("only touches lastActiveAt when recently checked", async () => {
    kickApi.mockResolvedValueOnce({
      data: subscribed(KICK_EVENTS.map((e) => e.name)),
    });
    await ensureKickSubscriptions("123");
    expect(kickApi).toHaveBeenCalledTimes(1); // listed, nothing missing

    await ensureKickSubscriptions("123");
    expect(kickApi).toHaveBeenCalledTimes(1);
  });

  it("re-creates subscriptions kick dropped", async () => {
    store.set("webhooks/kick:123", {
      subscriptionIds: ["old"],
      checkedAt: { toMillis: () => 0 },
      lastActiveAt: { toMillis: () => 0 },
    });
    kickApi
      .mockResolvedValueOnce({ data: subscribed(["chat.message.sent"]) })
      .mockResolvedValueOnce({
        data: [{ name: "channel.followed", version: 1, subscription_id: "f" }],
      });
    await ensureKickSubscriptions("123");
    const body = JSON.parse(kickApi.mock.calls[1][2].body);
    expect(body.events).toHaveLength(KICK_EVENTS.length - 1);
    expect(body.events).not.toContainEqual({
      name: "chat.message.sent",
      version: 1,
    });
  });
});

describe("removeIdleKickSubscriptions", () => {
  it("unsubscribes channels idle for a week", async () => {
    const day = 86400 * 1000;
    store.set("webhooks/kick:111", {
      subscriptionIds: ["a", "b"],
      lastActiveAt: { toMillis: () => Date.now() - 8 * day },
    });
    store.set("webhooks/kick:222", {
      subscriptionIds: ["c"],
      lastActiveAt: { toMillis: () => Date.now() - day },
    });
    kickApi.mockResolvedValue(null);
    await removeIdleKickSubscriptions();
    expect(kickApi).toHaveBeenCalledWith(
      "app-token",
      "/events/subscriptions?id=a&id=b",
      { method: "DELETE" },
    );
    expect(store.has("webhooks/kick:111")).toBe(false);
    expect(store.has("webhooks/kick:222")).toBe(true);
  });
});
