import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { GoogleAuth } from "google-auth-library";
import fetch from "cross-fetch";

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

  const voiceNameTokens = data.voice.split("-");
  const languageCode = `${voiceNameTokens[0]}-${voiceNameTokens[1]}`;

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
        voice: {
          languageCode: languageCode,
          name: data.voice,
        },
        audioConfig: {
          speakingRate: data.rate,
          pitch: data.pitch,
          audioEncoding: "MP3",
        },
      }),
    }
  );

  const json = (await response.json()) as any;

  console.log(json);

  return json["audioContent"];
});

export const getVoices = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "invalid auth");
  }

  const token = await auth.getAccessToken();

  const response = await fetch(
    `https://texttospeech.googleapis.com/v1/voices?languageCode=${data.language}`,
    {
      method: "GET",
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/json",
      },
    }
  );

  const json = (await response.json()) as any;

  console.log(json);

  return json["voices"];
});
