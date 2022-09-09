import fetch from "cross-fetch";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

export const streamlabs = functions.pubsub
  .schedule("* * * * *")
  .onRun(async (context) => {
    // fetch profiles that have lastActiveAt in the last 3 days.
    const profiles = await admin
      .firestore()
      .collection("profiles")
      .where(
        "lastActiveAt",
        ">",
        admin.firestore.Timestamp.fromDate(
          new Date(Date.now() - 3 * 86400 * 1000)
        )
      )
      .get();
    const promises = profiles.docs.map(async (profileDoc) => {
      // fetch the streamlabs doc.
      const streamlabsDoc = await admin
        .firestore()
        .collection("streamlabs")
        .doc(profileDoc.id)
        .get();
      if (!streamlabsDoc.exists || !streamlabsDoc.get("token")) {
        return;
      }

      // call the streamlabs api with the access token.
      const accessToken = streamlabsDoc.get("token")["access_token"];
      if (!accessToken) {
        return;
      }
      const after = streamlabsDoc.get("after") || 0;
      const response = await fetch(
        `https://streamlabs.com/api/v1.0/donations?access_token=${accessToken}&limit=10&after=${after}`
      );
      const json = await response.json();

      // update the after signal.
      if (json["data"].length > 0) {
        await streamlabsDoc.ref.update({
          after: json["data"][0]["donation_id"],
        });
      }

      // associate with every provider.
      for (const donation of json["data"]) {
        for (const provider of ["twitch", "youtube"]) {
          if (!profileDoc.get(provider)) {
            continue;
          }
          const channel = profileDoc.get(provider)["login"];
          const channelId = `${provider}:${profileDoc.get(provider)["id"]}`;
          await admin
            .firestore()
            .collection("messages")
            .add({
              channel,
              channelId,
              type: "streamlabs.donation",
              donationId: donation["donation_id"],
              name: donation["name"],
              message: donation["message"],
              amount: donation["amount"],
              currency: donation["currency"],
              timestamp: admin.firestore.Timestamp.fromMillis(
                donation["created_at"]
              ),
            });
        }
      }
    });
    await Promise.all(promises);
  });
