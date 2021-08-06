import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";
import * as serviceAccount from "../service_account.json";
import { Agent } from "./agent";

const PROJECT_ID = serviceAccount.project_id;

admin.initializeApp({
  databaseURL: `https://${PROJECT_ID}-default-rtdb.firebaseio.com`,
});

const AGENT_ID = uuidv4();

console.log("running agent", AGENT_ID);

console.log(process.env);

const agent = new Agent(AGENT_ID);

process.on("SIGTERM", () => agent.disconnect());
process.on("uncaughtException", () => agent.disconnect());
