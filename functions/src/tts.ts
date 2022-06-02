import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { GoogleAuth } from "google-auth-library";
import fetch from "node-fetch";

const auth = new GoogleAuth();

export const synthesize = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "invalid auth");
  }
  // verify that the user has a tts subscription active.

  const profile = await admin
    .firestore()
    .collection("profiles")
    .doc(context.auth.uid)
    .get();

  if (!profile.exists) {
    throw new functions.https.HttpsError("permission-denied", "invalid auth");
  }

  const claims = profile.get("claims") || {};
  if (!claims.tts) {
    throw new functions.https.HttpsError("permission-denied", "not subscribed");
  }

  const token = await auth.getAccessToken();

  const response = await fetch(
    "https://texttospeech.googleapis.com/v1/text:synthesize",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        input: {
          text: data.text,
        },
        audioConfig: {
          audioEncoding: "MP3",
        },
      }),
    }
  );

  const json = await response.json();

  console.log(json);

  return json["audioContent"];
});
