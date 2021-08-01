import * as admin from "firebase-admin";
import * as tmi from "tmi.js";
import { v4 as uuidv4 } from "uuid";

export function buildClient() {
  const id = uuidv4();

  const messages = admin.firestore().collection("messages");

  const client = new tmi.Client({
    connection: { reconnect: true },
    channels: [],
  });

  client.connect();

  client.on("message", async (channel, tags, message) => {
    const timestamp = admin.firestore.Timestamp.fromMillis(
      Number(tags["tmi-sent-ts"])
    );

    await messages.doc(`twitch:${tags.id}`).set({
      channel,
      channelId: `twitch:${tags["room-id"]}`,
      type: "message",
      timestamp,
      tags,
      message,
    });
  });

  client.on(
    "messagedeleted",
    async (channel, username, deletedMessage, tags: any) => {
      const timestamp = admin.firestore.Timestamp.fromMillis(
        Number(tags["tmi-sent-ts"])
      );

      const messageId = tags["target-msg-id"];

      const original = await messages.doc(`twitch:${messageId}`).get();

      if (!original.exists) {
        return;
      }

      await messages.doc(`twitch:-${messageId}`).set({
        channelId: original.get("channelId"),
        type: "messagedeleted",
        timestamp,
        tags,
        messageId,
      });
    }
  );

  client.on("raided", (async (
    channel: string,
    username: string,
    viewers: number,
    tags: any
  ) => {
    const timestamp = admin.firestore.Timestamp.fromMillis(
      Number(tags["tmi-sent-ts"])
    );

    await messages.doc(`twitch:${tags.id}`).set({
      channel,
      channelId: `twitch:${tags["room-id"]}`,
      type: "raided",
      timestamp,
      tags,
      username,
      viewers,
    });
  }) as any);

  client.on("connected", () => console.log(`client ${id} connected`));
  client.on("connecting", () => console.log(`client ${id} connecting`));
  client.on("disconnected", () => console.log(`client ${id} disconnected`));
  client.on("reconnect", () => console.log(`client ${id} reconnecting`));

  return client;
}
