import * as functions from "firebase-functions";
import { PubSub } from "@google-cloud/pubsub";
import * as admin from "firebase-admin";

export const subscribe = functions.https.onRequest(async (req, res) => {
  const provider = req.body?.provider;
  const channel = req.body?.channel;
  if (!provider || !channel) {
    res.status(400).send("missing provider, channel");
    return;
  }

  const pubsub = new PubSub({ projectId: "rtchat-47692" });

  const response = await pubsub
    .topic("projects/rtchat-47692/topics/subscribe")
    .publish(Buffer.from(JSON.stringify({ provider, channel })));

  res.status(200).send(response);
});

export const cleanup = functions.pubsub
  .schedule("* * * * *")
  .onRun(async () => {
    // remove any messages older than 24 hours.
    const timestamp = admin.firestore.Timestamp.fromMillis(
      new Date().getTime() - 86400 * 1000
    );
    while (true) {
      const snapshot = await admin
        .firestore()
        .collection("messages")
        .where("timestamp", "<=", timestamp)
        .limit(500)
        .get();
      if (snapshot.empty) {
        return;
      }
      const batch = admin.firestore().batch();
      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
      }
      await batch.commit();
    }
  });
