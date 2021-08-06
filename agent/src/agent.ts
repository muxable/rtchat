import { Message, PubSub, Topic } from "@google-cloud/pubsub";
import { FirebaseAdapter } from "./adapters/firebase";
import { ChatAdapter } from "./adapters/chat";

type Adapters = {
  pubsub: { client: PubSub; projectId: string };
  chat: ChatAdapter;
  firebase: FirebaseAdapter;
};

export class Agent {
  private cleanup: () => Promise<void>;
  private joinTopic: Topic;
  private locks = new Set<string>();

  constructor(private agentId: string, private adapters: Adapters) {
    const prefix = `projects/${adapters.pubsub.projectId}/`;
    this.joinTopic = adapters.pubsub.client.topic(`${prefix}topics/subscribe`);

    console.log("binding join listener", this.joinTopic.name);

    const joinSubscription = this.joinTopic.subscription(
      `${prefix}subscriptions/subscribe-sub`
    );

    joinSubscription.on("message", (message) => this.onSubscribe(message));

    const leaveTopic = adapters.pubsub.client.topic(
      `${prefix}topics/unsubscribe`
    );

    const leaveSubscriptionId = `${prefix}subscriptions/unsubscribe-${agentId}`;
    console.log("binding leave listener", leaveSubscriptionId);

    const leaveSubscription =
      leaveTopic.createSubscription(leaveSubscriptionId);
    leaveSubscription.then(([subscription]) => {
      subscription.on("message", (message) => this.onUnsubscribe(message));
    });

    this.cleanup = async () => {
      console.log("cleaning up");

      joinSubscription.close();
      const [subscription] = await leaveSubscription;
      await subscription.delete();
    };
  }

  async onSubscribe(message: Message) {
    console.log("received subscribe message: " + message.data.toString());
    message.ack();

    const { provider, channel } = JSON.parse(message.data.toString());

    await this.subscribe(provider, channel);
  }

  async subscribe(provider: string, channel: string) {
    const { token, username } = await this.adapters.firebase.getCredentials(
      provider
    );

    this.adapters.chat.addClient(
      { token, username, provider, channel },
      {
        lock: async () => {
          const result = await this.adapters.firebase.lock(
            provider,
            channel,
            this.agentId
          );
          if (result) {
            this.locks.add(`${provider}:${channel}`);
          } else {
            console.log("lock already taken");
          }
          return result;
        },
        unlock: async (reconnect) => {
          if (!this.locks.has(`${provider}:${channel}`)) {
            console.error("lock not taken, ignoring unlock request");
            return true;
          }
          const result = await this.adapters.firebase.unlock(
            provider,
            channel,
            this.agentId
          );
          this.locks.delete(`${provider}:${channel}`);
          if (reconnect && result) {
            // try to resubscribe.
            await this.joinTopic.publishJSON({ provider, channel });
          }
          return result;
        },
        onMessage: (channel, tags, message) =>
          this.adapters.firebase.addMessage(channel, tags),
        onMessageDeleted: (channel, username, deletedMessage, tags) =>
          this.adapters.firebase.deleteMessage(channel, tags),
        onRaided: (channel, username, viewers, tags) =>
          this.adapters.firebase.addRaid(channel, username, viewers, tags),
      }
    );
  }

  async onUnsubscribe(message: Message) {
    console.log("received unsubscribe message: " + message.data.toString());
    message.ack();

    const { provider, channel } = JSON.parse(message.data.toString());

    await this.unsubscribe(provider, channel);
  }

  async unsubscribe(provider: string, channel: string) {
    await this.adapters.chat.removeClient({ provider, channel });
  }

  async disconnect() {
    await this.cleanup();

    await this.adapters.chat.close();
  }
}
