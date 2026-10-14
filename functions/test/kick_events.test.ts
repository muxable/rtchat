import * as fs from "fs";
import * as path from "path";
import { describe, expect, it } from "vitest";
import { toDocuments } from "../src/kick_webhook";

function fixture(name: string) {
  return JSON.parse(
    fs.readFileSync(
      path.join(__dirname, "fixtures/kick", `${name}.json`),
      "utf8"
    )
  );
}

function deliver(type: string, fixtureName = type) {
  return toDocuments(
    {
      messageId: "01DELIVERY",
      timestamp: "2026-10-12T00:00:00Z",
      type,
      version: "1",
      event: fixture(fixtureName),
    },
    Date.parse("2026-10-12T00:00:00Z")
  )!;
}

const millis = (value: unknown) => (value as any).toMillis();

describe("kick events", () => {
  it.each([
    ["channel.subscription.new", "2025-01-14T16:08:06Z"],
    ["channel.subscription.renewal", "2025-01-14T16:08:06Z"],
    ["channel.subscription.gifts", "2025-01-14T16:08:06Z"],
    ["kicks.gifted", "2025-10-20T04:00:08.634Z"],
  ])("stores %s at its created_at time", (type, createdAt) => {
    const docs = deliver(type);
    expect(docs.channelId).toBe("kick:123456789");
    expect(docs.messages).toHaveLength(1);
    expect(docs.messages[0].id).toBe("kick:01DELIVERY");
    expect(docs.messages[0].data.type).toBe(`kick.${type}`);
    expect(millis(docs.messages[0].data.timestamp)).toBe(Date.parse(createdAt));
  });

  it("keeps anonymous gifters anonymous", () => {
    const docs = deliver(
      "channel.subscription.gifts",
      "channel.subscription.gifts.anonymous"
    );
    expect((docs.messages[0].data.event as any).gifter).toMatchObject({
      is_anonymous: true,
      username: null,
    });
  });

  it("stores follows, timestamped at delivery", () => {
    const docs = deliver("channel.followed");
    expect(docs.messages[0].data.type).toBe("kick.channel.followed");
    expect(millis(docs.messages[0].data.timestamp)).toBe(
      Date.parse("2026-10-12T00:00:00Z")
    );
    // kick doesn't expose follower totals, so there's nothing to count from.
    expect(docs.channel.followerCount).toBeUndefined();
  });

  it("stores bans and timeouts at the moderation time", () => {
    for (const name of ["moderation.banned", "moderation.banned.permanent"]) {
      const docs = deliver("moderation.banned", name);
      expect(docs.messages[0].data.type).toBe("kick.moderation.banned");
      expect(millis(docs.messages[0].data.timestamp)).toBe(
        Date.parse("2025-01-14T16:08:05Z")
      );
    }
    expect(
      (
        deliver("moderation.banned", "moderation.banned.permanent").messages[0]
          .data.event as any
      ).metadata.expires_at
    ).toBeNull();
  });

  it("stores redemptions at their redemption time", () => {
    const docs = deliver("channel.reward.redemption.updated");
    expect(docs.channelId).toBe("kick:333");
    expect(millis(docs.messages[0].data.timestamp)).toBe(
      Date.parse("2025-12-02T22:54:19.323Z")
    );
    expect(docs.channel).toMatchObject({ login: "gigachad" });
  });

  it("maps documented stream status payloads", () => {
    const online = deliver(
      "livestream.status.updated",
      "livestream.status.updated.online"
    );
    expect(online.messages[0].data.type).toBe("stream.online");
    expect(millis(online.channel.onlineAt)).toBe(
      Date.parse("2025-01-01T11:00:00+11:00")
    );
    const offline = deliver(
      "livestream.status.updated",
      "livestream.status.updated.offline"
    );
    expect(offline.messages[0].data.type).toBe("stream.offline");
    expect(millis(offline.messages[0].data.timestamp)).toBe(
      Date.parse("2025-01-01T15:00:00+11:00")
    );
  });

  it("maps the documented chat payload", () => {
    const docs = deliver("chat.message.sent");
    expect(docs.messages[0].id).toBe("kick:unique_message_id_123");
    expect(millis(docs.messages[0].data.timestamp)).toBe(
      Date.parse("2025-01-14T16:08:06Z")
    );
  });
});
