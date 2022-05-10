import * as admin from "firebase-admin";
import { concatMap, Observable } from "rxjs";
import { AuthorizationCode, ModuleOptions } from "simple-oauth2";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { log } from "../log";

export const TWITCH_CLIENT_ID =
  process.env["TWITCH_CLIENT_ID"] || "edfnh2q85za8phifif9jxt3ey6t9b9";

export async function getTwitchOAuthConfig(): Promise<
  ModuleOptions<"client_id">
> {
  const client = new SecretManagerServiceClient();
  const id = TWITCH_CLIENT_ID;
  let secret = process.env["TWITCH_CLIENT_SECRET"];
  if (!secret) {
    // pull from secret manager.
    const [version] = await client.accessSecretVersion({
      name: "projects/rtchat-47692/secrets/twitch-client-secret/versions/latest",
    });
    secret = version.payload?.data?.toString();
  }
  if (!secret) {
    throw new Error("twitch client secret missing");
  }
  return {
    client: { id, secret },
    auth: {
      tokenHost: "https://id.twitch.tv",
      tokenPath: "/oauth2/token",
      authorizePath: "/oauth2/authorize",
    },
    options: {
      bodyFormat: "json",
      authorizationMethod: "body",
    },
  };
}

export function parseTimestamp(
  timestamp: string | undefined
): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromMillis(Number(timestamp));
}

function getBotUserId(provider: "twitch") {
  switch (provider) {
    case "twitch":
      return (
        process.env["TWITCH_BOT_USER_ID"] || "JSdHKOEgwcZijVsuXXdftmizt6E3"
      );
  }
}

export class FirebaseAdapter {
  constructor(
    private firebase: admin.database.Database,
    private firestore: admin.firestore.Firestore,
    private provider: "twitch"
  ) {
    firestore.settings({ ignoreUndefinedProperties: true });
  }

  getMessage(key: string) {
    return this.firestore.collection("messages").doc(key);
  }

  setIfNotExists(key: string, value: any) {
    return this.firestore.runTransaction(async (transaction) => {
      const ref = this.firestore.collection("messages").doc(key);
      const doc = await transaction.get(ref);
      if (doc.exists) {
        return;
      }
      transaction.set(ref, value);
    });
  }

  async getBot() {
    const userId = getBotUserId(this.provider);
    const username = (
      await this.firestore.collection("profiles").doc(userId).get()
    ).get(this.provider)["login"] as string;
    return { userId, username };
  }

  async getProfile(channel: string) {
    const results = await this.firestore
      .collection("profiles")
      .where(`${this.provider}.login`, "==", channel)
      .get();
    if (results.size > 1) {
      log.error(
        { provider: this.provider, channel },
        "duplicate profiles found"
      );
    }
    return results.empty ? null : results.docs[0];
  }

  async getCredentials(userId: string) {
    // fetch the token from the database.
    const ref = this.firestore.collection("tokens").doc(userId);
    const encoded = (await ref.get()).get(this.provider);
    if (!encoded) {
      return null;
    }
    const client = new AuthorizationCode(await getTwitchOAuthConfig());
    let accessToken = client.createToken(JSON.parse(encoded));
    while (accessToken.expired(3600)) {
      try {
        accessToken = await accessToken.refresh();
      } catch (err: any) {
        if (err?.data?.payload?.message === "Invalid refresh token") {
          return null;
        }
        throw err;
      }
    }
    await ref.update({ [this.provider]: JSON.stringify(accessToken.token) });
    return accessToken.token;
  }

  async clearCredentials(userId: string) {
    await this.firestore
      .collection("tokens")
      .doc(userId)
      .update({ [this.provider]: null });
  }

  // Notifies for open join requests.
  onRequest(provider: string, callback: (channel: string) => void) {
    const listener = (snapshot: admin.database.DataSnapshot) => {
      const channel = snapshot.key;
      if (channel) {
        callback(channel);
      }
    };
    const ref = this.firebase
      .ref("requests")
      .child(provider);
    ref.on("child_added", listener);
    return () => ref.off("child_added", listener);
  }

  // This function claims the agent for the given id and returns when the agent is released.
  async claim(provider: string, channel: string, agentId: string) {
    // set the assignment
    const assignRef = this.firebase
      .ref("connections")
      .child(provider)
      .child(channel)
      .child(agentId);
    await assignRef.set(true);
    const dc = assignRef.onDisconnect();
    dc.set(null);
    // wait for assignment change
    await new Promise<void>((resolve) => {
      const listener = (snapshot: admin.database.DataSnapshot) => {
        if (!snapshot.val()) {
          resolve();
          assignRef.off("value", listener);
          dc.cancel();
        }
      };
      assignRef.on("value", listener);
    });
  }

  // Issues a new request for a given provider and channel.
  async releaseUnexpectedly(provider: string, channel: string) {
    await this.firebase.ref("requests").child(provider).child(channel).set("");
  }

  // Finds all the channels owned by this agent and issues new join requests for them.
  async releaseAll(provider: string, agentId: string) {
    const ref = this.firebase.ref("assignments").child(provider);
    const results = await ref
      .orderByValue()
      .startAt(agentId)
      .endAt(`${agentId}\uFFFF`)
      .once("value");
    const channels = results.val();
    if (!channels) {
      return;
    }
    for (const key of Object.keys(channels)) {
      channels[key] = "";
    }
    await this.firebase.ref("requests").child(provider).update(channels);
  }
}
