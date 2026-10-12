import * as crypto from "crypto";
import { describe, expect, it } from "vitest";
import { toDocuments, verifySignature } from "../src/kick_webhook";

const { publicKey, privateKey } = crypto.generateKeyPairSync("rsa", {
  modulusLength: 2048,
  publicKeyEncoding: { type: "spki", format: "pem" },
  privateKeyEncoding: { type: "pkcs8", format: "pem" },
});

function sign(id: string, ts: string, body: string) {
  return crypto
    .createSign("RSA-SHA256")
    .update(`${id}.${ts}.${body}`)
    .sign(privateKey, "base64");
}

describe("verifySignature", () => {
  const id = "01HZXJ4Q0Y8M6ZJ6V9Q3K4X7AB";
  const ts = "2026-10-12T01:02:03Z";
  const body = JSON.stringify({ message_id: "m1" });

  it("accepts deliveries signed by kick", () => {
    expect(
      verifySignature(publicKey, id, ts, Buffer.from(body), sign(id, ts, body))
    ).toBe(true);
  });

  it("rejects tampered bodies, ids, timestamps and garbage", () => {
    const signature = sign(id, ts, body);
    expect(
      verifySignature(publicKey, id, ts, Buffer.from(body + " "), signature)
    ).toBe(false);
    expect(
      verifySignature(publicKey, "other", ts, Buffer.from(body), signature)
    ).toBe(false);
    expect(
      verifySignature(publicKey, id, "2026", Buffer.from(body), signature)
    ).toBe(false);
    expect(
      verifySignature(publicKey, id, ts, Buffer.from(body), "not base64!")
    ).toBe(false);
    expect(
      verifySignature("not a key", id, ts, Buffer.from(body), signature)
    ).toBe(false);
  });
});

const broadcaster = {
  user_id: 123,
  username: "Muxfd",
  channel_slug: "muxfd",
};

function delivery(type: string, event: object) {
  return {
    messageId: "delivery-1",
    timestamp: "2026-10-12T01:00:00Z",
    type,
    version: "1",
    event: { broadcaster, ...event },
  };
}

describe("toDocuments", () => {
  const now = Date.parse("2026-10-12T01:00:00Z");

  it("keys chat messages by kick's message id", () => {
    const docs = toDocuments(
      delivery("chat.message.sent", {
        message_id: "uuid-1",
        content: "hello",
        created_at: "2026-10-12T00:59:59Z",
      }),
      now
    )!;
    expect(docs.channelId).toBe("kick:123");
    expect(docs.messages).toHaveLength(1);
    const [message] = docs.messages;
    expect(message.id).toBe("kick:uuid-1");
    expect(message.data.type).toBe("kick.chat.message.sent");
    expect(message.data.channelId).toBe("kick:123");
    expect((message.data.timestamp as any).toMillis()).toBe(
      Date.parse("2026-10-12T00:59:59Z")
    );
    expect((message.data.expiresAt as any).toMillis()).toBe(
      now + 14 * 86400 * 1000
    );
    expect((message.data.event as any).content).toBe("hello");
    expect(docs.channel).toEqual({ login: "muxfd", displayName: "Muxfd" });
  });

  it("maps stream status to provider-neutral stream events", () => {
    const online = toDocuments(
      delivery("livestream.status.updated", {
        is_live: true,
        title: "irl",
        started_at: "2026-10-12T00:00:00Z",
      }),
      now
    )!;
    expect(online.messages[0].id).toBe("kick:delivery-1");
    expect(online.messages[0].data.type).toBe("stream.online");
    expect((online.channel.onlineAt as any).toMillis()).toBe(
      Date.parse("2026-10-12T00:00:00Z")
    );
    expect(online.channel.title).toBe("irl");

    const offline = toDocuments(
      delivery("livestream.status.updated", {
        is_live: false,
        ended_at: "2026-10-12T02:00:00Z",
      }),
      now
    )!;
    expect(offline.messages[0].data.type).toBe("stream.offline");
    expect(offline.channel.onlineAt).toBeNull();
  });

  it("stores metadata on the channel without a message", () => {
    const docs = toDocuments(
      delivery("livestream.metadata.updated", {
        metadata: {
          title: "new title",
          language: "en",
          category: { id: 15, name: "IRL" },
        },
      }),
      now
    )!;
    expect(docs.messages).toEqual([]);
    expect(docs.channel).toMatchObject({
      title: "new title",
      language: "en",
      categoryId: 15,
      categoryName: "IRL",
    });
  });

  it("stores other events under a kick-prefixed type", () => {
    const docs = toDocuments(
      delivery("channel.followed", { follower: { user_id: 9 } }),
      now
    )!;
    expect(docs.messages[0]).toMatchObject({
      id: "kick:delivery-1",
      data: { type: "kick.channel.followed" },
    });
  });

  it("ignores deliveries without a broadcaster", () => {
    expect(
      toDocuments({ ...delivery("chat.message.sent", {}), event: {} }, now)
    ).toBeNull();
  });
});
