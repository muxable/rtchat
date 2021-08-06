import { Message, PubSub, Topic } from "@google-cloud/pubsub";
import * as admin from "firebase-admin";
import * as serviceAccount from "../service_account.json";
import { FirebaseAdapter } from "./adapters/firebase";
import { ChatAdapter } from "./adapters/chat";

const PROJECT_ID = serviceAccount.project_id;

admin.initializeApp({
  databaseURL: `https://${PROJECT_ID}-default-rtdb.firebaseio.com`,
});

export class Agent {
  private chat = new ChatAdapter();
  private firebase = new FirebaseAdapter(admin.database(), admin.firestore());

  private cleanup: () => Promise<void>;
  private joinTopic: Topic;

  constructor(private agentId: string) {
    const prefix = `projects/${PROJECT_ID}/`;
    this.joinTopic = new PubSub().topic(`${prefix}topics/subscribe`);

    const joinSubscription = this.joinTopic.subscription(
      `${prefix}subscriptions/subscribe-sub`
    );

    joinSubscription.on("message", this.onSubscribe);

    const leaveTopic = new PubSub().topic(`${prefix}topics/unsubscribe`);

    const leaveSubscriptionId = `${prefix}subscriptions/unsubscribe-${agentId}`;

    leaveTopic
      .createSubscription(leaveSubscriptionId)
      .then(([subscription]) => subscription.on("message", this.onUnsubscribe));

    this.cleanup = async () => {
      joinSubscription.off("message", this.onSubscribe);

      await leaveTopic.subscription(leaveSubscriptionId).delete();
    };
  }

  async onSubscribe(message: Message) {
    console.log("received subscribe message: " + message.data.toString());
    message.ack();

    const { provider, channel } = JSON.parse(message.data.toString());

    this.chat.addClient(
      { provider, channel },
      {
        lock: () => this.firebase.lock(provider, channel, this.agentId),
        unlock: async (resubscribe: boolean) => {
          const result = await this.firebase.unlock(
            provider,
            channel,
            this.agentId
          );
          if (resubscribe) {
            // try to resubscribe.
            await this.joinTopic.publishJSON({ provider, channel });
          }
          return result;
        },
        onMessage: this.firebase.addMessage,
        onMessageDeleted: this.firebase.deleteMessage,
        onRaided: this.firebase.addRaid,
      }
    );
  }

  async onUnsubscribe(message: Message) {
    console.log("received unsubscribe message: " + message.data.toString());
    message.ack();

    const { provider, channel } = JSON.parse(message.data.toString());

    this.chat.removeClient({ provider, channel });
  }

  async disconnect() {
    await this.cleanup();

    this.chat.close();
  }
}
