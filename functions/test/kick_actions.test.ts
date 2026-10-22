import { beforeEach, describe, expect, it, vi } from "vitest";

const { kickApi, userToken } = vi.hoisted(() => ({
  kickApi: vi.fn(),
  userToken: vi.fn(),
}));

vi.mock("../src/kick", () => ({ kickApi }));
vi.mock("../src/oauth", () => ({
  getAccessToken: userToken,
  getAppAccessToken: async () => ({ token: { access_token: "app-token" } }),
}));

import {
  banKickUser,
  deleteKickMessage,
  resolveKickUserId,
  sendKickMessage,
  toKickTimeoutMinutes,
  unbanKickUser,
} from "../src/kick_actions";

beforeEach(() => {
  kickApi.mockReset();
  userToken.mockReset().mockResolvedValue("user-token");
});

const body = (call: number) => JSON.parse(kickApi.mock.calls[call][2].body);

describe("toKickTimeoutMinutes", () => {
  it("rounds seconds up to whole minutes within kick's range", () => {
    expect(toKickTimeoutMinutes(1)).toBe(1);
    expect(toKickTimeoutMinutes(60)).toBe(1);
    expect(toKickTimeoutMinutes(90)).toBe(2);
    expect(toKickTimeoutMinutes(600)).toBe(10);
    expect(toKickTimeoutMinutes(30 * 86400)).toBe(10080);
  });
});

describe("chat", () => {
  it("sends as the user and returns the document id", async () => {
    kickApi.mockResolvedValue({ data: { is_sent: true, message_id: "abc" } });
    await expect(sendKickMessage("uid", "123", "hello")).resolves.toBe(
      "kick:abc",
    );
    expect(userToken).toHaveBeenCalledWith("uid", "kick");
    expect(kickApi.mock.calls[0][0]).toBe("user-token");
    expect(kickApi.mock.calls[0][1]).toBe("/chat");
    expect(body(0)).toEqual({
      content: "hello",
      type: "user",
      broadcaster_user_id: 123,
    });
  });

  it("replies to messages by kick id", async () => {
    kickApi.mockResolvedValue({ data: {} });
    await sendKickMessage("uid", "123", "hi", "kick:parent-id");
    expect(body(0).reply_to_message_id).toBe("parent-id");
  });

  it("deletes messages by kick id", async () => {
    kickApi.mockResolvedValue(null);
    await deleteKickMessage("uid", "kick:m-1");
    expect(kickApi).toHaveBeenCalledWith("user-token", "/chat/m-1", {
      method: "DELETE",
    });
  });

  it("requires a linked kick account", async () => {
    userToken.mockResolvedValue(null);
    await expect(sendKickMessage("uid", "1", "hi")).rejects.toThrow(
      /not linked/,
    );
  });
});

describe("moderation", () => {
  it("bans permanently or times out in minutes", async () => {
    kickApi.mockResolvedValue({ data: {} });
    await banKickUser("uid", "1", "2");
    expect(kickApi.mock.calls[0][1]).toBe("/moderation/bans");
    expect(body(0)).toEqual({ broadcaster_user_id: 1, user_id: 2 });

    await banKickUser("uid", "1", "2", {
      durationSeconds: 300,
      reason: "timed out by streamer",
    });
    expect(body(1)).toEqual({
      broadcaster_user_id: 1,
      user_id: 2,
      duration: 5,
      reason: "timed out by streamer",
    });
  });

  it("unbans with a json body", async () => {
    kickApi.mockResolvedValue({ data: {} });
    await unbanKickUser("uid", "1", "2");
    expect(kickApi.mock.calls[0][2].method).toBe("DELETE");
    expect(body(0)).toEqual({ broadcaster_user_id: 1, user_id: 2 });
  });

  it("resolves logins to user ids via channel slugs", async () => {
    kickApi.mockResolvedValue({ data: [{ broadcaster_user_id: 42 }] });
    await expect(resolveKickUserId("some_user")).resolves.toBe("42");
    expect(kickApi).toHaveBeenCalledWith(
      "app-token",
      "/channels?slug=some_user",
    );
    kickApi.mockResolvedValue({ data: [] });
    await expect(resolveKickUserId("nobody")).rejects.toThrow(/not found/);
  });
});
