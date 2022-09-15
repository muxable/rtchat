import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import fetch from "cross-fetch";
import * as crypto from "crypto";

type Log = {
  removed: boolean;
  address: string;
  data: string;
  topics: string[];
};

type RawContract = {
  rawvalue?: string;
  address?: string;
  decimal?: number;
};

type Activity = {
  category: string;
  fromAddress: string;
  toAddress: string;
  blockNum: string;
  value?: number;
  erc721TokenId?: string;
  asset?: string;
  hash: string;
  typeTraceAddress: string;
  rawContract?: RawContract;
  log?: Log;
};

type AddressEvent = {
  network: string;
  activity: Activity[];
};

type AddressNotification = {
  webhookId: string;
  id: string;
  createdAt: string;
  type: string;
  event: AddressEvent;
};

function isValidSignatureForStringBody(
  body: string, // must be raw string body, not json transformed version of the body
  signature: string, // your "X-Alchemy-Signature" from header
  signingKey: string // taken from dashboard for specific webhook
): boolean {
  const hmac = crypto.createHmac("sha256", signingKey); // Create a HMAC SHA256 hash using the signing key
  hmac.update(body, "utf8"); // Update the token hash with the request body using utf8
  const digest = hmac.digest("hex");
  return signature === digest;
}

export const alchemyWebhook = functions.https.onRequest(async (req, res) => {
  const body = req.body;
  const headerKey = req.headers["x-alchemy-signature"] as string;
  const signingKey = functions.config().alchemy.signingkey;

  if (!isValidSignatureForStringBody(body, headerKey, signingKey)) {
    res.status(403).send("Fail to validate signature");
    return;
  }

  const notification: AddressNotification = body as AddressNotification;

  for (const activity of notification.event.activity) {
    // look for userId that associated with this address
    const addressDoc = await admin
      .firestore()
      .collection("realtimecash")
      .where("address", "==", activity.toAddress)
      .limit(1)
      .get();

    const userId = addressDoc.docs[0].id;

    // get channelId for this user
    const profileDoc = await admin
      .firestore()
      .collection("profiles")
      .doc(userId)
      .get();

    const channelId = `twitch:${profileDoc.get("twitch").id}`;

    // storing donation respoonses in realtimecash collection
    await admin.firestore().collection("messages").add({
      channelId: channelId,
      webhookId: notification.webhookId,
      id: notification.id,
      createdAt: notification.createdAt,
      type: "realtimecash.donation",
      notificationType: notification.type,
      activity: activity,
    });
  }
  res.status(200).send("OK");
});

export const setRealTimeCashAddress = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("permission-denied", "missing auth");
    }

    const userId = context.auth.uid;
    const address = data?.address;
    if (!address) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "missing userId, address params"
      );
    }

    const WEBHOOKID = functions.config().alchemy.webhookid;
    const options = {
      method: "PATCH",
      headers: {
        accept: "application/json",
        "X-Alchemy-Token": functions.config().alchemy.authtoken,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        addresses_to_add: ["0x9131F047B512fD9cc42afc7025e2e9Cb7E62eedF"],
        webhook_id: WEBHOOKID,
      }),
    };

    // https://docs.alchemy.com/reference/update-webhook-addresses
    fetch(
      "https://dashboard.alchemyapi.io/api/update-webhook-addresses",
      options
    )
      .then(async (response) => {
        await admin
          .firestore()
          .collection("realtimecash")
          .doc(userId)
          .set({
            address,
            WEBHOOKID,
          })
          .catch((error) => {
            // fail to write to firestore
            throw new functions.https.HttpsError(error, error.message);
          });
      })
      .catch((err) => {
        throw new functions.https.HttpsError(err, err.message);
      });
    return;
  }
);
