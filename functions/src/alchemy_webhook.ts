import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// TODO: webhook receiver from alchemy
export const alchemyWebhook = functions.https.onRequest(async (req, res) => {

	// const body = req.body;
	// const event = body.event;
	// const alchemyWebhookId = body.webhookId;
	// const network = event.network;

	// // list of activities
	// const activitities = event.activity;
  res.status(200).send();
});


export const setRealTimeCashAddress = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
	// console.log("data", data);
	const userId = data?.userId;
	const address = data?.address;
  if (!address) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing userId, address params"
    );
  }
	// console.log('userId,', userId)
	// console.log('address', address)

	const webhookId = "wh_octjglnywaupz6th";

	try {
		await admin.firestore().collection("realtimecash").doc(userId).set({
			address,
			webhookId,
		});
	} catch (error) {
  	throw new functions.https.HttpsError("invalid-argument", "invalid provider");
	}
  return;
});