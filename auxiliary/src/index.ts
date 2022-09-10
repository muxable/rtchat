import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import * as admin from "firebase-admin";
import { merge } from "rxjs";
import { streamlabs$ } from "./streamlabs";

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

  const subscriber = merge(streamlabs$).subscribe();
  for (const signal in ["SIGINT", "SIGTERM"]) {
    process.on(signal, () => {
      subscriber.unsubscribe();
      process.exit(0);
    });
  }
}

main();
