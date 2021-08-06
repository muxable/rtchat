import * as tmi from "tmi.js";
import * as admin from "firebase-admin";

function parseTimestamp(
  timestamp: string | undefined
): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromMillis(Number(timestamp));
}

export class FirebaseAdapter {
  constructor(
    private firebase: admin.database.Database,
    private firestore: admin.firestore.Firestore
  ) {}

  private getMessage(key: string) {
    return this.firestore.collection("messages").doc(key);
  }

  async addMessage(channel: string, tags: tmi.ChatUserstate, message: string) {
    await this.getMessage(`twitch:${tags.id}`).set({
      channel,
      channelId: `twitch:${tags["room-id"]}`,
      type: "message",
      timestamp: parseTimestamp(tags["tmi-sent-ts"]),
      tags,
      message,
    });
  }

  async deleteMessage(channel: string, tags: any) {
    await this.getMessage(`twitch:${tags.id}`).set({
      channel,
      channelId: `twitch:${tags["room-id"]}`,
      type: "messagedeleted",
      timestamp: parseTimestamp(tags["tmi-sent-ts"]),
      tags,
      messageId: tags["target-msg-id"],
    });
  }

  async addRaid(channel: string, username: string, viewers: number, tags: any) {
    await this.getMessage(`twitch:${tags.id}`).set({
      channel,
      channelId: `twitch:${tags["room-id"]}`,
      type: "raided",
      timestamp: parseTimestamp(tags["tmi-sent-ts"]),
      tags,
      username,
      viewers,
    });
  }

  // returns true if the lock was aqcuired properly.
  async lock(provider: string, channel: string, agentId: string) {
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
    const lockRef = this.firebase.ref("locks").child(provider).child(channel);
    return new Promise<boolean>((resolve) => {
      lockRef.transaction(
        (current) => {
          if (current === agentId) {
            return null;
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
}
