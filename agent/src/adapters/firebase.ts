import * as admin from "firebase-admin";
import { AuthorizationCode, ModuleOptions } from "simple-oauth2";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { log } from "../log";
import crypto from "crypto";

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

// This function returns the canonical agent id.
//
// The canonical agent id is defined as the agent id whose sha1 hash
// exceeds the sha1 hash of the key. If no such agent id exists, the
// lowest agent id is returned.
function findCanonicalAgentId(key: string, agentIds: string[]) {
  const keyHash = crypto.createHash("sha1").update(key).digest();
  const agents = agentIds
    .map((agentId) => {
      const hash = crypto.createHash("sha1").update(agentId).digest();
      return { agentId, hash };
    })
    // in principle we can avoid sorting. in practice it's not worth it
    // because the code is much simpler if we sort.
    .sort((a, b) => Buffer.compare(a.hash, b.hash));

  // find the first agent where the sha1 hash is greater than the key hash
  const agent = agents.findIndex(
    (agent) => Buffer.compare(agent.hash, keyHash) > 0
  );
  return agents[agent === -1 ? 0 : agent].agentId;
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
    while (accessToken.expired(1200 + 1200 * Math.random())) {
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

  // Notifies for open join requests.
  onRequest(provider: string, callback: (channel: string) => void) {
    // attempt to join any existing channels. this will help load shed
    // existing agents because the canonical operator is uniformly distributed.
    // if we don't do this, older agents will slowly accrue channels.
    this.firebase
      .ref("connections")
      .child(provider)
      .get()
      .then((snapshot) => {
        for (const channel of Object.keys(snapshot.val() || {})) {
          callback(channel);
        }
      });
    const listener = (snapshot: admin.database.DataSnapshot) => {
      const channel = snapshot.key;
      if (channel) {
        callback(channel);
      }
    };
    const ref = this.firebase.ref("requests").child(provider);
    ref.on("child_added", listener);
    return () => ref.off("child_added", listener);
  }

  // This function claims the agent for the given id and returns when the agent is released.
  async claim(provider: string, channel: string, agentId: string) {
    log.info({ provider, channel, agentId }, "claiming agent");
    // set the assignment
    const connectionsRef = this.firebase
      .ref("connections")
      .child(provider)
      .child(channel);
    const requestRef = this.firebase
      .ref("requests")
      .child(provider)
      .child(channel);
    // mark us as connected
    await connectionsRef.child(agentId).set(true);
    // clear the request
    await requestRef.remove();
    // add a disconnect handler, clear our connection
    const connectionDc = connectionsRef.child(agentId).onDisconnect();
    await connectionDc.remove();
    // and issue a new request (we don't know if we are canonical)
    const requestDc = requestRef.onDisconnect();
    await requestDc.set(admin.database.ServerValue.TIMESTAMP);
    // wait for assignment change
    await new Promise<void>((resolve) => {
      const listener = (snapshot: admin.database.DataSnapshot) => {
        const agentIds = Object.keys(snapshot.val() || {});
        const isIncluded = agentIds.includes(agentId);
        if (!isIncluded) {
          log.info(
            { provider, channel, agentId },
            "released agent from external source"
          );
          connectionsRef.off("value", listener);
          resolve();
          return;
        }
        // only consider agent ids that volunteer as candidates.
        // this allows for soft disconnects to pass the canonical agent.
        const candidateIds = agentIds.filter(
          (agentId) => snapshot.val()[agentId]
        );
        const isCanonical =
          candidateIds.length == 0 ||
          findCanonicalAgentId(`${provider}:${channel}`, candidateIds) ===
            agentId;
        if (!isCanonical) {
          log.info(
            { provider, channel, agentId },
            "released agent from canonical deferral"
          );
          connectionsRef.off("value", listener);
          resolve();
          return;
        }
      };
      connectionsRef.on("value", listener);
    });
    await connectionsRef.child(agentId).remove();
    await connectionDc.cancel();
    await requestDc.cancel();
    log.info({ provider, channel, agentId }, "claim released");
  }

  async release(
    provider: string,
    channel: string,
    agentId: string,
    force = false // if true, indicates we didn't have a choice (eg irc disconnect).
  ) {
    const connRef = this.firebase
      .ref("connections")
      .child(provider)
      .child(channel)
      .child(agentId);
    if (force) {
      await connRef.remove();
    } else {
      await connRef.set(false);
    }
    await this.firebase
      .ref("requests")
      .child(provider)
      .child(channel)
      .set(admin.database.ServerValue.TIMESTAMP);
  }

  // Finds all the channels owned by this agent and issues new join requests for them.
  async releaseAll(provider: string, agentId: string) {
    const results = await this.firebase
      .ref("connections")
      .child(provider)
      .get();
    const connections = results.val();
    for (const channel of Object.keys(connections || {})) {
      if (agentId in connections[channel]) {
        await this.release(provider, channel, agentId);
      }
    }
  }
}
