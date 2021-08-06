import { PubSub } from "@google-cloud/pubsub";
import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";
import * as serviceAccount from "../service_account.json";
import { ChatAdapter } from "./adapters/chat";
import { FirebaseAdapter } from "./adapters/firebase";
import { Agent } from "./agent";

const PROJECT_ID = serviceAccount.project_id;

admin.initializeApp({
  databaseURL: `https://${PROJECT_ID}-default-rtdb.firebaseio.com`,
});

const AGENT_ID = uuidv4();

console.log("running agent", AGENT_ID);

console.log(process.env);

const agent = new Agent(AGENT_ID, {
  pubsub: { client: new PubSub(), projectId: PROJECT_ID },
  chat: new ChatAdapter(),
  firebase: new FirebaseAdapter(admin.database(), admin.firestore()),
});

for (const signal of ["SIGINT", "SIGTERM", "uncaughtException"]) {
  process.on(signal, async () => {
    await agent.disconnect();
    process.exit(0);
  });
}
