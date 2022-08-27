import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "node-fetch";
import { getTwitchUserId } from "./twitch";

export const updateChatStatus = functions.pubsub
  .schedule("* * * * *") // every 1 minute
  .onRun(async () => {
    const promises: Promise<any>[] = [];
    // fetch the active connections from realtime database
    const connections =
      (await admin.database().ref("connections").once("value")).val() || {};
    for (const [provider, channels] of Object.entries(connections)) {
      for (const channel of Object.keys(channels as any)) {
        switch (provider) {
          case "twitch":
            const promise = fetch(
              `https://tmi.twitch.tv/group/user/${channel}/chatters`
            )
              .then((res) => res.json())
              .then(async (json) => {
                return admin
                  .firestore()
                  .collection("chat-status")
                  .add({
                    provider,
                    channel,
                    channelId: `twitch:${await getTwitchUserId(channel)}`,
                    ...json["chatters"],
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                  });
              });
            promises.push(promise);
        }
      }
    }

    await Promise.all(promises);
  });
