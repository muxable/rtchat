import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";
import { FirebaseAdapter } from "./adapters/firebase";
import { runTwitchAgent } from "./agents/twitch";
import { log } from "./log";

const PROJECT_ID = process.env["PROJECT_ID"] || "rtchat-47692";

async function main() {
  if (!process.env["GOOGLE_APPLICATION_CREDENTIALS"]) {
    const client = new SecretManagerServiceClient();
    // credentials are not set, initialize the app from secret manager.
    // TODO: why don't gcp default credentials work?
    const [version] = await client.accessSecretVersion({
      name: "projects/rtchat-47692/secrets/firebase-service-account/versions/latest",
    });
    const secret = version.payload?.data?.toString();
    if (!secret) {
      throw new Error("unable to retrieve credentials from secret manager");
    }
    admin.initializeApp({
      credential: admin.credential.cert(JSON.parse(secret)),
      databaseURL: `https://${PROJECT_ID}-default-rtdb.firebaseio.com`,
    });
  } else {
    admin.initializeApp({
      databaseURL: `https://${PROJECT_ID}-default-rtdb.firebaseio.com`,
    });
  }

  const AGENT_ID = uuidv4();

  log.info({ agentId: AGENT_ID }, "running agent");
  const firebase = new FirebaseAdapter(
    admin.database(),
    admin.firestore(),
    "twitch",
    new Set(["muxfd"])
  );

  runTwitchAgent(firebase, AGENT_ID).then((close) => {
    for (const signal of ["SIGINT", "SIGTERM"]) {
      process.on(signal, async (err) => {
        log.error(err, "received %s", signal);
        await close();
        log.info({ agentId: AGENT_ID }, "agent closed");
        process.exit(0);
      });
    }
  });
}

main().catch((err) => {
  log.error(err);
});
