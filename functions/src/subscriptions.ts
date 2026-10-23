import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import { removeIdleKickSubscriptions } from "./kick_subscriptions";

export const unsubscribe = functions.pubsub
  .schedule("0 4 * * *") // daily at 4a
  .onRun(async () => {
    const limit = Date.now() - 7 * 86400 * 1000;
    const assignmentsRef = admin.firestore().collection("assignments");
    const assignments = await assignmentsRef.get();
    for (const assignment of assignments.docs) {
      // ignore twitch:muxfd
      if (assignment.id === "twitch:muxfd") {
        continue;
      }
      const data = assignment.data();
      if (data.subscribedAt.toMillis() < limit) {
        // delete this doc
        await assignment.ref.delete();
      }
    }
    await removeIdleKickSubscriptions();
  });
