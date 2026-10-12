import * as crypto from "crypto";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "cross-fetch";
import { KICK_API } from "./kick";

// Kick delivers events by webhook: https://docs.kick.com/events/webhook-security

let publicKey: Promise<string> | null = null;

async function fetchPublicKey() {
  const response = await fetch(`${KICK_API}/public-key`);
  if (!response.ok) {
    throw new Error(`failed to fetch kick public key: ${response.status}`);
  }
  const body = await response.json();
  return body.data.public_key as string;
}

// Kick may rotate its key, so it's cached but refetched when verification
// fails rather than hardcoded.
async function getPublicKey(refresh = false) {
  if (!publicKey || refresh) {
    publicKey = fetchPublicKey().catch((err) => {
      publicKey = null;
      throw err;
    });
  }
  return publicKey;
}

// Kick signs `${message id}.${timestamp}.${raw body}` with RSA PKCS#1 v1.5 and
// SHA-256, base64-encoded in the Kick-Event-Signature header.
export function verifySignature(
  publicKeyPem: string,
  messageId: string,
  timestamp: string,
  rawBody: Buffer,
  signature: string
) {
  try {
    return crypto
      .createVerify("RSA-SHA256")
      .update(`${messageId}.${timestamp}.`)
      .update(rawBody)
      .verify(publicKeyPem, signature, "base64");
  } catch {
    return false;
  }
}

export interface KickDelivery {
  messageId: string;
  timestamp: string;
  type: string;
  version: string;
  event: any;
}

export interface MessageDoc {
  // the document id within channels/{channelId}/messages
  id: string;
  data: Record<string, unknown>;
}

const TWO_WEEKS = 1000 * 86400 * 14;

// Maps a delivery to the message documents and channel fields it produces.
// Chat messages are keyed by Kick's message id so replies and deletions can
// reference them; other events by the delivery id. Both make redelivery
// (at-least-once) idempotent.
export function toDocuments(delivery: KickDelivery, now = Date.now()) {
  const { event } = delivery;
  const broadcasterId = event?.broadcaster?.user_id;
  if (broadcasterId === undefined || broadcasterId === null) {
    return null;
  }
  const channelId = `kick:${broadcasterId}`;
  const envelope = (type: string, at?: string) => ({
    channelId,
    type,
    timestamp: admin.firestore.Timestamp.fromMillis(
      Date.parse(at ?? delivery.timestamp)
    ),
    expiresAt: admin.firestore.Timestamp.fromMillis(now + TWO_WEEKS),
    event,
  });

  const messages: MessageDoc[] = [];
  const channel: Record<string, unknown> = {};

  switch (delivery.type) {
    case "chat.message.sent":
      messages.push({
        id: `kick:${event.message_id}`,
        data: envelope("kick.chat.message.sent", event.created_at),
      });
      break;
    case "livestream.status.updated":
      // the client treats stream.online/stream.offline the same for every
      // provider (uptime, online indicators).
      messages.push({
        id: `kick:${delivery.messageId}`,
        data: envelope(
          event.is_live ? "stream.online" : "stream.offline",
          event.is_live ? event.started_at : event.ended_at
        ),
      });
      channel.onlineAt = event.is_live
        ? admin.firestore.Timestamp.fromMillis(Date.parse(event.started_at))
        : null;
      if (event.title) {
        channel.title = event.title;
      }
      break;
    case "livestream.metadata.updated":
      channel.title = event.metadata?.title ?? null;
      channel.language = event.metadata?.language ?? null;
      channel.categoryId = event.metadata?.category?.id ?? null;
      channel.categoryName = event.metadata?.category?.name ?? null;
      break;
    default:
      messages.push({
        id: `kick:${delivery.messageId}`,
        data: envelope(`kick.${delivery.type}`, event.created_at),
      });
  }
  if (event.broadcaster?.channel_slug) {
    channel.login = event.broadcaster.channel_slug;
    channel.displayName = event.broadcaster.username;
  }
  return { channelId, messages, channel };
}

export const kickWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send();
    return;
  }
  const header = (name: string) => String(req.headers[name] ?? "");
  const delivery: KickDelivery = {
    messageId: header("kick-event-message-id"),
    timestamp: header("kick-event-message-timestamp"),
    type: header("kick-event-type"),
    version: header("kick-event-version"),
    event: req.body,
  };
  const signature = header("kick-event-signature");
  if (!delivery.messageId || !delivery.timestamp || !signature) {
    res.status(400).send();
    return;
  }

  const verify = async (refresh: boolean) =>
    verifySignature(
      await getPublicKey(refresh),
      delivery.messageId,
      delivery.timestamp,
      req.rawBody,
      signature
    );
  if (!(await verify(false)) && !(await verify(true))) {
    functions.logger.warn("kick webhook signature mismatch", {
      messageId: delivery.messageId,
    });
    res.status(403).send();
    return;
  }

  const documents = toDocuments(delivery);
  if (!documents) {
    functions.logger.warn("kick webhook without broadcaster", delivery);
    res.status(200).send();
    return;
  }

  const channelRef = admin
    .firestore()
    .collection("channels")
    .doc(documents.channelId);
  for (const message of documents.messages) {
    try {
      await channelRef
        .collection("messages")
        .doc(message.id)
        .create(message.data);
    } catch (err: any) {
      // ALREADY_EXISTS: a redelivery of an event we've stored.
      if (err?.code !== 6) {
        throw err;
      }
    }
  }
  if (Object.keys(documents.channel).length > 0) {
    await channelRef.set(documents.channel, { merge: true });
  }
  res.status(200).send();
});
