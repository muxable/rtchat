import { beforeEach, describe, expect, it, vi } from "vitest";

const { store, serverTime, getTwitchLogin, ensureKickSubscriptions } =
  vi.hoisted(() => ({
    store: new Map<string, unknown>(),
    serverTime: { serverTime: true },
    getTwitchLogin: vi.fn(),
    ensureKickSubscriptions: vi.fn(),
  }));
vi.mock("firebase-admin", () => {
  const firestore = Object.assign(
    () => ({
      collection: (name: string) => ({
        doc: (id: string) => ({
          set: async (data: unknown) => {
            store.set(`${name}/${id}`, data);
          },
        }),
      }),
    }),
    { FieldValue: { serverTimestamp: () => serverTime } },
  );
  return { firestore };
});
vi.mock("../src/twitch", () => ({ getTwitchLogin }));
vi.mock("../src/eventsub", () => ({ checkEventSubSubscriptions: vi.fn() }));
vi.mock("../src/kick_subscriptions", () => ({
  ensureKickSubscriptions,
  removeIdleKickSubscriptions: vi.fn(),
}));

import { subscribe } from "../src/subscriptions";

const channelId = "UCabcdefghijklmnopqr12_-";

beforeEach(() => {
  store.clear();
  vi.resetAllMocks();
});

describe("YouTube subscribe", () => {
  it.each([{}, { auth: { uid: "user" } }])(
    "writes an assignment with context %j",
    async (context) => {
      expect(
        await subscribe.run({ provider: "youtube", channelId }, context as any),
      ).toBe(channelId);
      expect([...store.entries()]).toEqual([
        [`assignments/youtube:${channelId}`, { subscribedAt: serverTime }],
      ]);
      expect(getTwitchLogin).not.toHaveBeenCalled();
      expect(ensureKickSubscriptions).not.toHaveBeenCalled();
    },
  );

  it.each([
    "UCshort",
    channelId + "x",
    channelId.toLowerCase(),
    "@creator",
    " UCabcdefghijklmnopqr12_-",
    "UCabcdefghijklmnopqr12_!",
    123,
    { id: channelId },
    [channelId],
  ])("rejects invalid id %j without writing", async (invalid) => {
    await expect(
      subscribe.run({ provider: "youtube", channelId: invalid }, {}),
    ).rejects.toMatchObject({ code: "invalid-argument" });
    expect(store.size).toBe(0);
  });
});
