import * as admin from "firebase-admin";
import fetch from "node-fetch";
import * as tmi from "tmi.js";
import { getAccessToken, getAppAccessToken, TWITCH_CLIENT_ID } from "./oauth";

export async function getTwitchClient(uid: string, channel: string) {
  const token = await getAccessToken(uid, "twitch");

  const usernameDoc = await admin
    .firestore()
    .collection("profiles")
    .doc(uid)
    .get();

  const username = usernameDoc.get("twitch")["login"];
  const identity = { username, password: `oauth:${token}` };
  const client = new tmi.Client({
    channels: [channel],
    identity,
  });
  await client.connect();
  return client;
}

export async function getTwitchLogin(id: string) {
  const token = await getAppAccessToken("twitch");

  const response = await fetch(`https://api.twitch.tv/helix/users?id=${id}`, {
    headers: {
      Authorization: `Bearer ${token}`,
      "Client-Id": TWITCH_CLIENT_ID,
    },
  });

  const json = await response.json();

  if (!json || !json["data"] || json["data"].length == 0) {
    return null;
  }
  return json["data"][0]["login"] as string;
}
