import { beforeEach, describe, expect, it, vi } from "vitest";

const { fetchMock } = vi.hoisted(() => ({ fetchMock: vi.fn() }));
vi.mock("cross-fetch", () => ({ default: fetchMock }));
vi.mock("../src/oauth", () => ({
  getAccessToken: async () => "user-token",
  TWITCH_CLIENT_ID: "client-id",
}));
vi.mock("firebase-admin", () => ({
  firestore: () => ({
    collection: () => ({
      doc: () => ({
        get: async () => ({
          exists: true,
          get: (field: string) =>
            field === "twitch" ? { id: "sender" } : undefined,
        }),
      }),
    }),
  }),
}));

import { clearChat, sendChatMessage } from "../src/twitch";

function respond(status: number, body: unknown = {}) {
  fetchMock.mockResolvedValue({
    status,
    ok: status < 300,
    json: async () => body,
  });
}

beforeEach(() => fetchMock.mockReset());

describe("sendChatMessage", () => {
  it("sends through helix as the signed-in user", async () => {
    respond(200, { data: [{ message_id: "m1", is_sent: true }] });
    expect(
      await sendChatMessage("uid", "broadcaster", "hello", "parent"),
    ).toEqual({
      sent: true,
    });
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("https://api.twitch.tv/helix/chat/messages");
    expect(init.method).toBe("POST");
    expect(JSON.parse(init.body)).toEqual({
      broadcaster_id: "broadcaster",
      sender_id: "sender",
      message: "hello",
      reply_parent_message_id: "parent",
    });
  });

  it("returns twitch's reason when the message is dropped", async () => {
    respond(200, {
      data: [
        {
          message_id: "",
          is_sent: false,
          drop_reason: {
            code: "msg_duplicate",
            message: "Your message is identical.",
          },
        },
      ],
    });
    expect(await sendChatMessage("uid", "broadcaster", "hello")).toEqual({
      sent: false,
      error: "Your message is identical.",
    });
  });

  it("reports tokens that can't use the api", async () => {
    respond(401, { message: "Missing scope: user:write:chat" });
    expect(await sendChatMessage("uid", "broadcaster", "hello")).toEqual({
      sent: false,
      unauthorized: true,
    });
  });
});

describe("clearChat", () => {
  it("clears the whole chat through helix", async () => {
    respond(204);
    expect(await clearChat("uid", "broadcaster")).toBeNull();
    expect(fetchMock).toHaveBeenCalledWith(
      "https://api.twitch.tv/helix/moderation/chat?broadcaster_id=broadcaster&moderator_id=sender",
      expect.objectContaining({ method: "DELETE" }),
    );
  });
});
