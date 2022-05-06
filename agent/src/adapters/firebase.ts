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

/**
 * Computes the difference between two sets.
 */
function diff<T>(a: Set<T>, b: Set<T>) {
  return Array.from(a).filter((x) => !b.has(x));
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

  async getAgent(channel: string) {
    const profile = await this.getProfile(channel);
    if (!profile) {
      return { isBot: true, ...(await this.getBot()) };
    }
    return {
      userId: profile.id,
      username: profile.get(this.provider)["login"] as string,
      isBot: false,
    };
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

  async getCredentials(userId: string, forceRefresh = false) {
    // fetch the token from the database.
    const ref = this.firestore.collection("tokens").doc(userId);
    const encoded = (await ref.get()).get(this.provider);
    if (!encoded) {
      throw new Error("token not found");
    }
    const client = new AuthorizationCode(await getTwitchOAuthConfig());
    let accessToken = client.createToken(JSON.parse(encoded));
    while (accessToken.expired(3600) || forceRefresh) {
      try {
        forceRefresh = false;
        accessToken = await accessToken.refresh();
      } catch (err: any) {
        if (err?.data?.payload?.message === "Invalid refresh token") {
          throw new Error("invalid refresh token");
        }
        throw err;
      }
    }
    await ref.update({ [this.provider]: JSON.stringify(accessToken.token) });
    return accessToken.token;
  }

  // Notifies for open join requests.
  onRequest(
    provider: string,
    agentId: string,
    callback: (channel: string) => void
  ) {
    const listener = (snapshot: admin.database.DataSnapshot) => {
      const requests = snapshot.val();
      if (!requests) {
        return;
      }
      for (const channel of Object.keys(requests)) {
        callback(channel);
      }
    };
    this.firebase.ref("requests").child(provider).on("value", listener);
    return () => {
      this.firebase.ref("requests").child(provider).off("value", listener);
    };
  }

  // This function claims the agent for the given id and returns when the agent is released.
  async claim(provider: string, channel: string, claimId: string) {
    // set the assignment
    const assignRef = this.firebase
      .ref("assignments")
      .child(provider)
      .child(channel);
    await assignRef.set(claimId);
    // clear the request
    const requestRef = this.firebase
      .ref("requests")
      .child(provider)
      .child(channel);
    await requestRef.set(null);
    const dc = requestRef.onDisconnect();
    dc.set("");
    // wait for assignment change
    await new Promise<void>((resolve) => {
      const listener = (snapshot: admin.database.DataSnapshot) => {
        if (snapshot.val() !== claimId) {
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
