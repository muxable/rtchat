import * as admin from "firebase-admin";
import { concatMap, Observable } from "rxjs";
import { AuthorizationCode, ModuleOptions } from "simple-oauth2";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";

async function getTwitchOAuthConfig(): Promise<ModuleOptions<"client_id">> {
  const client = new SecretManagerServiceClient();
  const id =
    process.env["TWITCH_CLIENT_ID"] || "edfnh2q85za8phifif9jxt3ey6t9b9";
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

  private getMessage(key: string) {
    return this.firestore.collection("messages").doc(key);
  }

  async getCredentials(forceRefresh = false) {
    const userId = getBotUserId(this.provider);

    const username = (
      await this.firestore.collection("profiles").doc(userId).get()
    ).get(this.provider)["login"] as string;

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
      } catch (err) {
        if (err.data?.payload?.message === "Invalid refresh token") {
          throw new Error("invalid refresh token");
        }
        throw err;
      }
    }
    await ref.update({ [this.provider]: JSON.stringify(accessToken.token) });
    return {
      token: accessToken.token,
      username,
    };
  }

  async addMessage(
    channelId: string,
    channel: string,
    messageId: string,
    message: string,
    timestamp: Date,
    tags: any
  ) {
    await this.getMessage(`twitch:${messageId}`).set({
      channelId: `${this.provider}:${channelId}`,
      channel,
      type: "message",
      timestamp: admin.firestore.Timestamp.fromDate(timestamp),
      tags,
      message,
    });
  }

  async deleteMessage(messageId: string, timestamp: Date, tags: any) {
    const original = await this.getMessage(`twitch:${messageId}`).get();

    if (!original.exists) {
      return;
    }

    await this.getMessage(`twitch:x-${messageId}`).set({
      channelId: original.get("channelId"),
      type: "messagedeleted",
      timestamp: admin.firestore.Timestamp.fromDate(timestamp),
      tags,
      messageId,
    });
  }

  onAssignment(
    provider: string,
    agentId: string,
    join: (channel: string) => Promise<void>,
    leave: (channel: string) => Promise<void>
  ) {
    const channels = new Set<string>();
    const ref = this.firebase.ref("agents").child(provider);

    const claimListener = async (snapshot: admin.database.DataSnapshot) => {
      const channel = Object.keys(snapshot.val() || {}).pop();
      if (!channel) {
        return;
      }
      // incur a slight delay to reduce contesting and load balance a little.
      const delay = 250 * Math.random() + 250 * Math.log1p(channels.size);
      await new Promise((resolve) => setTimeout(resolve, delay));
      await ref.child(channel).transaction((data) => {
        if (data !== "") {
          return;
        }
        return agentId;
      });
    };

    const claimRef = ref.orderByValue().limitToFirst(1).equalTo("");
    const assignRef = ref.orderByValue().equalTo(agentId);

    const subscription = new Observable<admin.database.DataSnapshot>(
      (subscriber) => {
        const listener = (s: admin.database.DataSnapshot) => {
          subscriber.next(s);
        };

        assignRef.on("value", listener);

        return () => assignRef.off("value", listener);
      }
    )
      .pipe(
        concatMap(async (snapshot) => {
          const requestedChannels = new Set(Object.keys(snapshot.val() || {}));

          // TODO: handle join failure in a way that doesn't cause infinite loops.
          const add = diff(requestedChannels, channels);
          const remove = diff(channels, requestedChannels);
          for (const channel of add) {
            try {
              await join(channel);
              channels.add(channel);
            } catch (e) {
              console.error("failed to join " + channel);
              await ref.child(channel).set("");
            }
          }
          for (const channel of remove) {
            try {
              await leave(channel);
              channels.delete(channel);
            } catch (e) {
              console.warn("failed to leave " + channel);
            }
          }
          // register a disconnect handler too in case our cleanup isn't called.
          // if we get preempted here we're in for a bad time.
          const update: { [key: string]: "" } = {};
          for (const channel of Array.from(channels)) {
            update[channel] = "";
          }
          await ref.onDisconnect().cancel();
          await ref.onDisconnect().update(update);
        })
      )
      .subscribe({ error: (err) => console.error(err) });

    claimRef.on("value", claimListener);

    return async () => {
      claimRef.off("value", claimListener);
      subscription.unsubscribe();

      // remove all existing channel claims.
      const update: { [key: string]: "" } = {};
      for (const channel of Array.from(channels)) {
        update[channel] = "";
      }
      await ref.update(update);
      await ref.onDisconnect().cancel();
      channels.clear();
    };
  }
}
