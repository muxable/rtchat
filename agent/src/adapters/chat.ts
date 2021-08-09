import { Token } from "simple-oauth2";
import * as tmi from "tmi.js";

type Events = {
  lock: () => Promise<boolean>;
  unlock: (reconnect: boolean) => Promise<boolean>;
  onMessage: (
    channel: string,
    tags: tmi.ChatUserstate,
    message: string
  ) => void;
  onMessageDeleted: (
    channel: string,
    username: string,
    deletedMessage: string,
    tags: any
  ) => void;
  onRaided: (
    channel: string,
    username: string,
    viewers: number,
    tags: any
  ) => void;
};

type ChatClient = {
  provider: string;
  channel: string;
  remote: tmi.Client;
  refreshTimer: NodeJS.Timeout | undefined;
  disconnect: (reconnect: boolean, persistDelay: number) => Promise<void>;
};

export class ChatAdapter {
  readonly clients: ChatClient[] = [];

  async addClient(
    params: {
      provider: string;
      channel: string;
      username: string;
      token: Token;
    },
    events: Events
  ) {
    switch (params.provider) {
      case "twitch":
        const remote = new tmi.Client({
          connection: { secure: true, reconnect: false },
          identity: {
            username: params.username,
            password: `oauth:${params.token["access_token"]}`,
          },
          channels: [params.channel],
        });
        const client = {
          ...params,
          remote,
          refreshTimer: setTimeout(async () => {
            console.log("refreshing");
            client.disconnect(true, 5000);
          }, (params.token["expires_in"] - 30 * 60) * 1000),
          disconnect: async (reconnect: boolean, persistDelay: number) => {
            console.log("disconnecting", reconnect, persistDelay);
            remote.removeAllListeners("disconnected");
            this.clients.splice(this.clients.indexOf(client), 1);
            if (await events.unlock(reconnect)) {
              await new Promise((resolve) => setTimeout(resolve, persistDelay));
            } else {
              console.error("failed to perform soft disconnect");
            }
            if (remote.readyState() === "OPEN") {
              remote.disconnect();
            }
            if (client.refreshTimer) {
              clearTimeout(client.refreshTimer);
            }
          },
        };
        remote.on("message", events.onMessage);
        remote.on("messagedeleted", events.onMessageDeleted);
        remote.on("raided", events.onRaided as any);
        remote.on("connected", async () => {
          if (await events.lock()) {
            // we acquired the lock, keep the client around.
            this.clients.push(client);
          } else {
            // failed to acquire the lock, disconnect the client.
            remote.removeAllListeners("disconnected");
            remote.disconnect();
          }
        });
        remote.on("disconnected", async (reason) => {
          client.disconnect(true, 0);
        });

        await remote.connect();

        console.log(
          "listening on",
          params.provider,
          params.channel,
          "as",
          params.username
        );
        return;
    }
  }

  async removeClient({
    provider,
    channel,
  }: {
    provider: string;
    channel: string;
  }) {
    for (let i = this.clients.length - 1; i >= 0; i--) {
      const client = this.clients[i];
      if (client.provider === provider && client.channel === channel) {
        client.disconnect(false, 0);
      }
    }
  }

  async close() {
    for (const client of this.clients) {
      client.disconnect(true, 0);
    }
  }
}
