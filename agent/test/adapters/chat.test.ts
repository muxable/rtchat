import * as admin from "firebase-admin";
import * as serviceAccount from "../../service_account.json";
import { ChatAdapter } from "../../src/adapters/chat";
import { FirebaseAdapter } from "../../src/adapters/firebase";

const PROJECT_ID = serviceAccount.project_id;
admin.initializeApp({
  databaseURL: `https://${PROJECT_ID}-default-rtdb.firebaseio.com`,
});

describe("ChatAdapter", () => {
  it("should roundtrip to twitch", () => {
    return new Promise<void>(async (resolve) => {
      const adapter = new ChatAdapter();
      const firebase = new FirebaseAdapter(admin.database(), admin.firestore());

      await adapter.addClient(
        {
          ...(await firebase.getCredentials("twitch")),
          provider: "twitch",
          channel: "realtimechat",
        },
        {
          async lock() {
            return true;
          },
          async unlock() {
            return true;
          },
          async onMessage(channel, tags, message) {
            expect(channel).toEqual("#realtimechat");
            expect(message).toEqual("test mooo");
            await adapter.close();
            // tmi.js has a 600ms wait time for the say command to respond.
            // this keeps the tests from erroring because of tmi.js's logs.
            await new Promise((resolve) => setTimeout(resolve, 750));
            resolve();
          },
          onMessageDeleted(channel, username, deletedMessage, tags) {
            fail("should not be called");
          },
          onRaided() {
            fail("should not be called");
          },
        }
      );

      expect(adapter.clients).toHaveLength(1);

      const [response] = await adapter.clients[0].remote.say(
        "realtimechat",
        "test mooo"
      );

      expect(response).toEqual("#realtimechat");
    });
  });
});
