import * as admin from "firebase-admin";
import fetch from "node-fetch";
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

  const json = await response.json();

  if (!json || !json["data"] || json["data"].length == 0) {
    return null;
  }
  return json["data"][0]["login"] as string;
}

export async function getTwitchUserId(username: string) {
  const token = await getAppAccessToken("twitch");

  if (!token) {
    return null;
  }
  const res = await fetch(
    "https://api.twitch.tv/helix/users?login=" + username,
    {
      headers: {
        "Content-Type": "application/json",
        "Client-Id": TWITCH_CLIENT_ID,
        Authorization: "Bearer " + token.token["access_token"],
      },
    }
  );
  const json = await res.json();
  if ((json.data || []).length === 0) {
    throw new Error("user not found " + username);
  }
  return json.data[0]["id"] as string;
}