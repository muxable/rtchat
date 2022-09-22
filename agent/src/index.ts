import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";
import { FirebaseAdapter } from "./adapters/firebase";
import { runTwitchAgent } from "./agents/twitch";
import { log } from "./log";

const PROJECT_ID = process.env["PROJECT_ID"] || "rtchat-47692";

async function main() {
  try {
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
  } catch (e) {
    if (!process.env["GOOGLE_APPLICATION_CREDENTIALS"]) {
      throw e;
    }
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
    new Set([]) // add a username here to only join that channel for development.
  );

  runTwitchAgent(firebase, AGENT_ID).then((close) => {
    for (const signal of ["SIGINT", "SIGTERM", "uncaughtException"]) {
      process.on(signal, async (err) => {
        firebase.debugKeepConnected = new Set();
        log.error(
          {
            agentId: AGENT_ID,
            error: err,
            signal,
            stack: err instanceof Error ? err.stack : null,
          },
          "received signal"
        );
        await Promise.race([
          close().then(() => {
            log.info({ agentId: AGENT_ID }, "agent closed");
          }),
          new Promise((resolve) => setTimeout(resolve, 60 * 1000)).then(() => {
            log.error({ agentId: AGENT_ID }, "agent close timed out after 60s");
          }),
        ]);
        process.exit(signal == "uncaughtException" ? 1 : 0);
      });
    }
  });
}

main().catch((err) => {
  log.error(err);
});
