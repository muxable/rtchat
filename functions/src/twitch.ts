import * as admin from "firebase-admin";
import fetch from "cross-fetch";
import { getAppAccessToken, TWITCH_CLIENT_ID } from "./oauth";

export async function getChannelId(uid: string, provider: string) {
  const usernameDoc = await admin
    .firestore()
    .collection("profiles")
    .doc(uid)
    .get();

  return `${provider}:${usernameDoc.get(provider)["id"]}`;
}

export async function getTwitchLogin(id: string) {
  const token = await getAppAccessToken("twitch");

  if (!token) {
    return null;
  }

  const response = await fetch(`https://api.twitch.tv/helix/users?id=${id}`, {
    headers: {
      Authorization: `Bearer ${token.token["access_token"]}`,
      "Client-Id": TWITCH_CLIENT_ID,
    },
  });

  const json = (await response.json()) as any;

  if (!json || !json["data"] || json["data"].length == 0) {
    return null;
  }
  return json["data"][0]["login"] as string;
}
