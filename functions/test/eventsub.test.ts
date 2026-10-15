import { describe, expect, it, vi } from "vitest";

vi.mock("../src/chat-status", () => ({
  runUpdateFollowerAndViewerCount: vi.fn(),
}));

import { eventsubConditions, outgoingRaidFrom } from "../src/eventsub";

describe("eventsubConditions", () => {
  it("subscribes to raids into and out of the channel", () => {
    const raids = eventsubConditions("123").filter(
      (s) => s.type === "channel.raid"
    );
    expect(raids.map((s) => s.condition)).toEqual([
      { to_broadcaster_user_id: "123" },
      { from_broadcaster_user_id: "123" },
    ]);
  });

  it("keeps the other subscriptions keyed by broadcaster", () => {
    const conditions = Object.fromEntries(
      eventsubConditions("123")
        .filter((s) => s.type !== "channel.raid")
        .map((s) => [s.type, s.condition])
    );
    expect(conditions["stream.online"]).toEqual({
      broadcaster_user_id: "123",
    });
    expect(conditions["channel.follow"]).toEqual({
      broadcaster_user_id: "123",
      moderator_user_id: "123",
    });
  });
});

describe("outgoingRaidFrom", () => {
  it("routes raids out of the channel to the raiding channel", () => {
    expect(
      outgoingRaidFrom({
        type: "channel.raid",
        condition: {
          from_broadcaster_user_id: "123",
          to_broadcaster_user_id: "",
        },
      })
    ).toBe("123");
  });

  it("leaves incoming raids and other events alone", () => {
    expect(
      outgoingRaidFrom({
        type: "channel.raid",
        condition: {
          from_broadcaster_user_id: "",
          to_broadcaster_user_id: "456",
        },
      })
    ).toBeNull();
    expect(
      outgoingRaidFrom({
        type: "channel.raid",
        condition: { to_broadcaster_user_id: "456" },
      })
    ).toBeNull();
    expect(
      outgoingRaidFrom({
        type: "stream.online",
        condition: { broadcaster_user_id: "123" },
      })
    ).toBeNull();
    expect(outgoingRaidFrom(undefined)).toBeNull();
  });
});
