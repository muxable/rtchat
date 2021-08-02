import * as admin from "firebase-admin";
import { AuthorizationCode, ModuleOptions } from "simple-oauth2";
import * as tmi from "tmi.js";
import { v4 as uuidv4 } from "uuid";

const TWITCH_CLIENT_ID = process.env["TWITCH_CLIENT_ID"];
const TWITCH_CLIENT_SECRET = process.env["TWITCH_CLIENT_SECRET"];
const TWITCH_BOT_USER_ID = process.env["TWITCH_BOT_USER_ID"];

export const TWITCH_OAUTH_CONFIG = {
  client: {
    id: TWITCH_CLIENT_ID,
    secret: TWITCH_CLIENT_SECRET,
  },
  auth: {
    tokenHost: "https://id.twitch.tv",
    tokenPath: "/oauth2/token",
    authorizePath: "/oauth2/authorize",
  },
  options: {
    bodyFormat: "json",
    authorizationMethod: "body",
  },
} as ModuleOptions<"client_id">;

export async function getAccessToken(userId: string, provider: string) {
  // fetch the token from the database.
  const ref = admin.firestore().collection("tokens").doc(userId);
  const encoded = (await ref.get()).get(provider);
  if (!encoded) {
    throw new Error("token not found");
  }
  const client = new AuthorizationCode(TWITCH_OAUTH_CONFIG);
  let accessToken = client.createToken(JSON.parse(encoded));
  while (accessToken.expired(300)) {
    try {
      accessToken = await accessToken.refresh();
    } catch (err) {
      if (err.data?.payload?.message === "Invalid refresh token") {
        throw new Error("invalid refresh token");
      }
      throw err;
    }
  }
  await ref.update({ [provider]: JSON.stringify(accessToken.token) });
  return accessToken.token["access_token"] as string;
}

export async function buildClient() {
  const id = uuidv4();

  const token = await getAccessToken(TWITCH_BOT_USER_ID, "twitch");

  console.log("authenticating using token", token);

  const client = new tmi.Client({
    connection: { reconnect: true },
    channels: [],
    identity: {
      username: "realtimechat",
      password: `oauth:${token}`,
    },
  });

  client.on("message", async (channel, tags, message) => {
    const timestamp = admin.firestore.Timestamp.fromMillis(
      Number(tags["tmi-sent-ts"])
    );

    await admin
      .firestore()
      .collection("messages")
      .doc(`twitch:${tags.id}`)
      .set({
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

      await admin
        .firestore()
        .collection("messages")
        .doc(`twitch:${tags.id}`)
        .set({
          channel,
          channelId: `twitch:${tags["room-id"]}`,
          type: "messagedeleted",
          timestamp,
          tags,
          messageId: tags["target-msg-id"],
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

    await admin
      .firestore()
      .collection("messages")
      .doc(`twitch:${tags.id}`)
      .set({
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

  await client.connect();

  return client;
}
