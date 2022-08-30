import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import fetch from "node-fetch";

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


type webhookIdResponse = {
	id: string;
	appId: string;
	network: string;
	webhookType: string;
	webHookUrl: string;
	isActive: boolean;
	timeCreated: string;
	addresses: string[];
}

export const setRealTimeCashAddress = functions.https.onCall(async (data, context) => {
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


	// https://docs.alchemy.com/reference/create-webhook
	// create webhook for user with userId
	const options = {
		method: 'POST',
		headers: {
			Accept: 'application/json',
			'X-Alchemy-Token': 'this-is-a-token',
			'Content-Type': 'application/json'
		},
		body: JSON.stringify({
			network: 'ETH_MAINNET',
			webhook_type: 'ADDRESS_ACTIVITY',
			webhook_url: 'localhost/{userId}' // TODO: replace with real webhook url
		})
	};

	fetch('https://dashboard.alchemyapi.io/api/create-webhook', options)
		.then(response => response.json())
		.then(async response => {
			const res = response as webhookIdResponse;
			const webhookId = res.id;
			await admin.firestore().collection("realtimecash").doc(userId).set({
				address,
				webhookId,
			}).catch(error => {
				throw new functions.https.HttpsError(error, error.message);
			});
		})
		.catch(err => {
			throw new functions.https.HttpsError(err, err.message);
		});

  return;
});