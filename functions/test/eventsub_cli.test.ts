import {
  afterAll,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from "vitest";
import {
  cliAvailable,
  serve,
  trigger,
  verifySubscription,
} from "./support/twitch_cli";

// Drives the eventsub function with signed notifications from the Twitch CLI
// and checks what it writes to Firestore.

const { store, runUpdateFollowerAndViewerCount } = vi.hoisted(() => ({
  store: new Map<string, Record<string, any>>(),
  runUpdateFollowerAndViewerCount: vi.fn(async () => {}),
}));

vi.mock("../src/chat-status", () => ({ runUpdateFollowerAndViewerCount }));
vi.mock("../src/oauth", async (importOriginal) => ({
  // keep the real TWITCH_CLIENT_SECRET so the CLI's signatures must match it.
  ...(await importOriginal<typeof import("../src/oauth")>()),
  getAppAccessToken: async () => ({ token: { access_token: "app-token" } }),
}));

// A tiny in-memory stand-in for the parts of Firestore the handler uses.
vi.mock("firebase-admin", () => {
  class Timestamp {
    constructor(readonly millis: number) {}
    static fromMillis(millis: number) {
      return new Timestamp(millis);
    }
    toMillis() {
      return this.millis;
    }
  }
  const SERVER_TIMESTAMP = { sentinel: "serverTimestamp" };
  class Increment {
    constructor(readonly n: number) {}
  }
  const apply = (prev: Record<string, any> = {}, data: Record<string, any>) => {
    const next = { ...prev };
    for (const [key, value] of Object.entries(data)) {
      if (value === SERVER_TIMESTAMP) {
        next[key] = Timestamp.fromMillis(Date.now());
      } else if (value instanceof Increment) {
        next[key] = (next[key] ?? 0) + value.n;
      } else {
        next[key] = value;
      }
    }
    return next;
  };
  const docRef = (path: string): any => ({
    id: path.split("/").pop(),
    path,
    collection: (name: string) => collection(`${path}/${name}`),
    get: async () => {
      const data = store.get(path);
      return { exists: data !== undefined, data: () => data };
    },
    create: async (data: Record<string, any>) => {
      if (store.has(path)) {
        throw Object.assign(new Error(`${path} exists`), { code: 6 });
      }
      store.set(path, apply({}, data));
    },
    set: async (data: Record<string, any>, options?: { merge?: boolean }) => {
      store.set(path, apply(options?.merge ? store.get(path) : {}, data));
    },
    update: async (data: Record<string, any>) => {
      if (!store.has(path)) {
        throw Object.assign(new Error(`no document ${path}`), { code: 5 });
      }
      store.set(path, apply(store.get(path), data));
    },
  });
  const collection = (name: string) => ({
    doc: (id: string) => docRef(`${name}/${id}`),
  });
  const firestore: any = () => ({ collection });
  firestore.Timestamp = Timestamp;
  firestore.FieldValue = {
    serverTimestamp: () => SERVER_TIMESTAMP,
    increment: (n: number) => new Increment(n),
  };
  return { firestore, initializeApp: () => {} };
});

import { eventsub, eventsubConditions } from "../src/eventsub";

const SECRET = "twitch-secret"; // functions.config().twitch.secret in vitest.config.ts
const BROADCASTER = "1234";
const CHANNEL = `channels/twitch:${BROADCASTER}`;

// every type the handler subscribes to, at the version it subscribes with.
const TYPES = [...new Set(eventsubConditions(BROADCASTER).map((s) => s.type))];
const version = (type: string) => (type === "channel.follow" ? "2" : "1");
// the CLI flag that makes BROADCASTER the subscribed channel: shoutouts are
// created by the --from-user, everything else is received by the --to-user.
const broadcasterFlag = (type: string) =>
  type === "channel.shoutout.create" ? "-f" : "-t";

let messageCount = 0;
const nextMessageId = () => `cli-message-${++messageCount}`;

describe.runIf(cliAvailable())("eventsub driven by the twitch cli", () => {
  let server: Awaited<ReturnType<typeof serve>>;

  beforeAll(async () => {
    server = await serve(eventsub as any);
  });
  afterAll(() => server?.close());

  beforeEach(() => {
    store.clear();
    server.deliveries.length = 0;
    runUpdateFollowerAndViewerCount.mockClear();
  });

  async function send(type: string, flags: string[] = [], secret = SECRET) {
    const id = nextMessageId();
    await trigger(server.url, secret, type, [
      broadcasterFlag(type),
      BROADCASTER,
      "-I",
      id,
      "-v",
      version(type),
      ...flags,
    ]);
    expect(server.deliveries).toHaveLength(1);
    return { id, delivery: server.deliveries[0] };
  }

  it("covers every subscribed type", () => {
    expect(TYPES).toHaveLength(26);
  });

  it.each(TYPES)("stores %s as a channel message", async (type) => {
    const { id, delivery } = await send(type);

    expect(delivery.status).toBe(200);
    expect(delivery.body.subscription.type).toBe(type);
    const message = store.get(
      type === "channel.follow"
        ? `${CHANNEL}/messages/twitch:follow:${delivery.body.event.user_id}`
        : `${CHANNEL}/messages/twitch:${id}`
    );
    expect(message).toMatchObject({
      channelId: `twitch:${BROADCASTER}`,
      type,
      event: delivery.body.event,
    });
    expect(message!.timestamp.toMillis()).toBe(
      Date.parse(
        delivery.headers["twitch-eventsub-message-timestamp"] as string
      )
    );
    expect(message!.expiresAt.toMillis()).toBeGreaterThan(Date.now());
  });

  it("stores incoming raids in the raided channel", async () => {
    const { id, delivery } = await send("channel.raid");

    expect(delivery.body.subscription.condition).toEqual({
      to_broadcaster_user_id: BROADCASTER,
    });
    expect(store.get(`${CHANNEL}/messages/twitch:${id}`)?.event).toEqual(
      delivery.body.event
    );
  });

  it("marks the channel online and refreshes its counts", async () => {
    await send("stream.online");

    expect(store.get(CHANNEL)?.onlineAt.toMillis()).toBeLessThanOrEqual(
      Date.now()
    );
    expect(runUpdateFollowerAndViewerCount).toHaveBeenCalledWith(
      { token: { access_token: "app-token" } },
      [`twitch:${BROADCASTER}`]
    );
  });

  it("marks the channel offline", async () => {
    store.set(CHANNEL, { onlineAt: 1, login: "kept" });

    await send("stream.offline");

    expect(store.get(CHANNEL)).toEqual({ onlineAt: null, login: "kept" });
  });

  it("counts follows", async () => {
    store.set(CHANNEL, { followerCount: 10 });

    await send("channel.follow");

    expect(store.get(CHANNEL)?.followerCount).toBe(11);
  });

  it("records a follower once", async () => {
    store.set(CHANNEL, { followerCount: 10 });

    // Twitch sometimes sends two follows, with different message ids, for one
    // follower.
    const first = await send("channel.follow", ["-f", "5678"]);
    server.deliveries.length = 0;
    const second = await send("channel.follow", ["-f", "5678"]);

    expect(first.id).not.toBe(second.id);
    expect(second.delivery.status).toBe(200);
    expect(store.get(CHANNEL)?.followerCount).toBe(11);
    const messages = [...store.keys()].filter((key) =>
      key.startsWith(`${CHANNEL}/messages/`)
    );
    expect(messages).toEqual([`${CHANNEL}/messages/twitch:follow:5678`]);
  });

  it("ignores follows for channels it doesn't know", async () => {
    const { delivery } = await send("channel.follow");

    expect(delivery.status).toBe(200);
    expect(store.has(CHANNEL)).toBe(false);
  });

  it("updates the channel's details", async () => {
    store.set(CHANNEL, { followerCount: 10 });

    const { delivery } = await send("channel.update", [
      "-d",
      "a new title",
      "-G",
      "509658",
    ]);

    const event = delivery.body.event;
    expect(event.title).toBe("a new title");
    expect(event.category_id).toBe("509658");
    expect(store.get(CHANNEL)).toEqual({
      followerCount: 10,
      login: event.broadcaster_user_login,
      displayName: event.broadcaster_user_name,
      title: event.title,
      language: event.language,
      categoryId: event.category_id,
      categoryName: event.category_name,
    });
  });

  it("answers the subscription challenge", async () => {
    // resolves only if the CLI accepts the handshake.
    const output = await verifySubscription(
      server.url,
      SECRET,
      "stream.online"
    );

    const [delivery] = server.deliveries;
    expect(delivery.status).toBe(200);
    expect(delivery.response).toBe(delivery.body.challenge);
    expect(delivery.contentType).toMatch(/^text\/plain/);
    expect(output).not.toMatch(/✗/);
  });

  it("rejects notifications signed with the wrong secret", async () => {
    const { id, delivery } = await send(
      "stream.online",
      [],
      "not-the-twitch-secret"
    );

    expect(delivery.status).toBe(403);
    expect(store.has(`${CHANNEL}/messages/twitch:${id}`)).toBe(false);
    expect(store.has(CHANNEL)).toBe(false);
    expect(runUpdateFollowerAndViewerCount).not.toHaveBeenCalled();
  });

  it("rejects challenges signed with the wrong secret", async () => {
    // the CLI exits non-zero when the handshake fails.
    await expect(
      verifySubscription(server.url, "not-the-twitch-secret", "stream.online")
    ).rejects.toThrow();

    const [delivery] = server.deliveries;
    expect(delivery.status).toBe(403);
    expect(delivery.response).not.toBe(delivery.body.challenge);
  });
});
