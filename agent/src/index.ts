import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";
import { runTwitchAgent } from "./agents/twitch";

const PROJECT_ID = process.env["PROJECT_ID"] || "rtchat-47692";

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: `https://${PROJECT_ID}-default-rtdb.firebaseio.com`,
});

const AGENT_ID = uuidv4();

console.log("running agent", AGENT_ID);

runTwitchAgent(AGENT_ID).then((close) => {
  for (const signal of ["SIGINT", "SIGTERM", "uncaughtException"]) {
    process.on(signal, async (err) => {
      console.error("received", signal, "with error", err);
      await close();
      process.exit(0);
    });
  }
});
