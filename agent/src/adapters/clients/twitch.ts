import { Token } from "simple-oauth2";
import * as tmi from "tmi.js";
import { ChatClient } from "./client";

type TwitchEvents = {
  onConnect: () => void;
  onDisconnect: (resubscribe: boolean) => void;
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

export class TwitchClient implements ChatClient {
  private client: tmi.Client;
  private disposed = false;

  public readonly provider = "twitch";

  constructor(
    public readonly channel: string,
    token: Token,
    private events: TwitchEvents
  ) {
    this.client = new tmi.Client({
      connection: { secure: true, reconnect: false },
      identity: {
        username: "realtimechat",
        password: `oauth:${token["access_token"]}`,
      },
      channels: [channel],
    });
    this.client.on("message", events.onMessage);
    this.client.on("messagedeleted", events.onMessageDeleted);
    this.client.on("raided", events.onRaided as any);
    this.client.on("connected", () => {
      this.events.onConnect();
    });
    this.client.on("disconnected", () => this.disconnect(true));
    setTimeout(() => {
      this.disconnect(true);
    }, (token["expires_in"] - 30 * 60) * 1000);
  }

  disconnect(reconnect = false) {
    if (this.disposed) {
      return;
    }
    this.disposed = true;
    this.events.onDisconnect(reconnect);
    // delay the actual disconnect to allow another agent to connect.
    const state = this.client.readyState();
    if (state === "OPEN" || state == "CONNECTING") {
      setTimeout(() => {
        this.client.disconnect();
      }, 5000);
    }
  }
}
