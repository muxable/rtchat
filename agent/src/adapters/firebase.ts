import * as tmi from "tmi.js";
import * as admin from "firebase-admin";
import { AuthorizationCode, ModuleOptions } from "simple-oauth2";
import {
  ClearMessageMessage,
  Messages,
  PrivateMessage,
  PrivateMessage,
  UserStateTags,
} from "twitch-js";

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

export function parseTimestamp(
  timestamp: string | undefined
): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromMillis(Number(timestamp));
}

function getBotUserId(provider: string) {
  switch (provider) {
    case "twitch":
      return TWITCH_BOT_USER_ID;
  }
}

export class FirebaseAdapter {
  constructor(
    private firebase: admin.database.Database,
    private firestore: admin.firestore.Firestore
  ) {}

  private getMessage(key: string) {
    return this.firestore.collection("messages").doc(key);
  }

  async getCredentials(provider: string, forceRefresh = false) {
    const userId = getBotUserId(provider);
    if (!userId) {
      throw new Error("invalid provider");
    }

    const username = (
      await this.firestore.collection("profiles").doc(userId).get()
    ).get(provider)["login"] as string;

    // fetch the token from the database.
    const ref = this.firestore.collection("tokens").doc(userId);
    const encoded = (await ref.get()).get(provider);
    if (!encoded) {
      throw new Error("token not found");
    }
    const client = new AuthorizationCode(TWITCH_OAUTH_CONFIG);
    let accessToken = client.createToken(JSON.parse(encoded));
    while (accessToken.expired(3600) || forceRefresh) {
      try {
        forceRefresh = false;
        accessToken = await accessToken.refresh();
      } catch (err) {
        if (err.data?.payload?.message === "Invalid refresh token") {
          throw new Error("invalid refresh token");
        }
        throw err;
      }
    }
    await ref.update({ [provider]: JSON.stringify(accessToken.token) });
    return {
      token: accessToken.token,
      username,
    };
  }

  async addMessage(message: PrivateMessage) {
    await this.getMessage(`twitch:${message.tags.id}`).set({
      channel: message.channel,
      channelId: `twitch:${message.tags.roomId}`,
      type: "message",
      timestamp: parseTimestamp(message.tags.tmiSentTs),
      tags: message.tags,
      message,
    });
  }

  async deleteMessage(message: ClearMessageMessage) {
    const messageId = message.tags.targetMsgId;

    if (!messageId) {
      console.error("received empty message id", message);
      return;
    }

    const original = await this.getMessage(`twitch:${messageId}`).get();

    if (!original.exists) {
      return;
    }

    await this.getMessage(`twitch:x-${messageId}`).set({
      channel: message.channel,
      channelId: original.get("channelId"),
      type: "messagedeleted",
      timestamp: admin.firestore.Timestamp.fromDate(message.timestamp),
      tags: message.tags,
      messageId,
    });
  }

  // returns true if the lock was aqcuired properly.
  async lock(provider: string, channel: string, agentId: string) {
    console.log("locking", provider, channel, agentId);
    const lockRef = this.firebase.ref("locks").child(provider).child(channel);
    return new Promise<boolean>((resolve) => {
      lockRef.transaction(
        (current) => {
          if (!current) {
            return agentId;
          }
        },
        (error, committed) => {
          if (error) {
            console.error(error);
          }
          resolve(committed);
        }
      );
    });
  }

  // returns true if the lock was released properly.
  async unlock(provider: string, channel: string, agentId: string) {
    console.log("unlocking", provider, channel, agentId);
    await this.firebase.ref("locks").child(provider).child(channel).set(null);
    return true;
  }
}
