import * as tmi from "tmi.js";
import { getAccessToken } from "../oauth";
import { ChatClient } from "./clients/client";
import { TwitchClient } from "./clients/twitch";

type Parameters = {
  provider: string;
  channel: string;
};

type Events = {
  lock: () => Promise<boolean>;
  unlock: (resubscribe: boolean) => Promise<boolean>;
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

export class ChatAdapter {
  private clients: ChatClient[] = [];

  async addClient(params: Parameters, events: Events) {
    const token = await getAccessToken(params.provider);
    switch (params.provider) {
      case "twitch":
        const client = new TwitchClient(params.channel, token, {
          onConnect: async () => {
            if (await events.lock()) {
              // we acquired the lock, keep the client around.
              this.clients.push(client);
            } else {
              // failed to acquire the lock, disconnect the client.
              client.disconnect(false);
            }
          },
          onDisconnect: async (resubscribe) => {
            if (await events.unlock(resubscribe)) {
              // we released the lock, remove the client.
              this.clients.splice(this.clients.indexOf(client), 1);
            } else {
              console.error(
                "failed to release lock for",
                client.provider,
                client.channel
              );
            }
          },
          ...events,
        });
    }
  }

  async removeClient({ provider, channel }: Parameters) {
    for (let i = this.clients.length - 1; i >= 0; i--) {
      const client = this.clients[i];
      if (client.provider === provider && client.channel === channel) {
        client.disconnect(false);
      }
      this.clients.splice(i, 1);
    }
  }

  close() {
    for (const client of this.clients) {
      client.disconnect(true);
    }
    this.clients.length = 0;
  }
}
