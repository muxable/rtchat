import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "node-fetch";
import { app as authApp } from "./auth";
import { getUserEmotes } from "./emotes";
import { eventsub } from "./eventsub";
import { getAccessToken, getAppAccessToken, TWITCH_CLIENT_ID } from "./oauth";
import { search } from "./search";
import { subscribe, unsubscribe, cleanup } from "./subscriptions";
import { getTwitchClient, getTwitchLogin } from "./twitch";

admin.initializeApp();

export const send = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const message = data?.message;
  if (!provider || !channelId || !message) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, message"
    );
  }

  switch (provider) {
    case "twitch":
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        return;
      }
      const client = await getTwitchClient(context.auth.uid, channelId);
      await client.connect();
      try {
        await await client.say(channel, message);
      } catch (err) {
        console.error(err);
      }
      return;
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const ban = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const username = data?.username;
  const reason = data?.reason;
  if (!provider || !channelId || !username || !reason) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, username, reason"
    );
  }

  switch (provider) {
    case "twitch":
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        return;
      }
      const client = await getTwitchClient(context.auth.uid, channelId);
      await client.connect();
      try {
        await client.ban(channel, username, reason);
      } catch (err) {
        console.error(err);
      }
      return;
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const unban = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const username = data?.username;
  if (!provider || !channelId || !username) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, username"
    );
  }

  switch (provider) {
    case "twitch":
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        return;
      }
      const client = await getTwitchClient(context.auth.uid, channelId);
      await client.connect();
      try {
        await client.unban(channel, username);
      } catch (err) {
        console.error(err);
      }
      return;
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const timeout = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const username = data?.username;
  const length = data?.length;
  const reason = data?.reason;
  if (!provider || !channelId || !username || !length || !reason) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, username, length, reason"
    );
  }

  switch (provider) {
    case "twitch":
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        return;
      }
      const client = await getTwitchClient(context.auth.uid, channelId);
      await client.connect();
      try {
        await client.timeout(channel, username, length, reason);
      } catch (err) {
        console.error(err);
      }
      return;
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const deleteMessage = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  const messageId = data?.messageId;
  if (!provider || !channelId || !messageId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, messageId"
    );
  }

  switch (provider) {
    case "twitch":
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        return;
      }
      const client = await getTwitchClient(context.auth.uid, channelId);
      await client.connect();
      try {
        await client.deletemessage(channel, messageId);
      } catch (err) {
        console.error(err);
      }
      return;
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const clear = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  if (!provider || !channelId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId"
    );
  }

  switch (provider) {
    case "twitch":
      const channel = await getTwitchLogin(context.auth.uid, channelId);
      if (!channel) {
        return;
      }
      const client = await getTwitchClient(context.auth.uid, channelId);
      await client.connect();
      try {
        await client.clear(channel);
      } catch (err) {
        console.error(err);
      }
      return;
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const getStatistics = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const provider = data?.provider;
  const channelId = data?.channelId;
  if (!provider || !channelId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId"
    );
  }

  switch (provider) {
    case "twitch":
      const token = await getAccessToken(context.auth.uid, provider);
      if (!token) {
        throw new functions.https.HttpsError("internal", "auth error");
      }
      const headers = {
        "Client-Id": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${token}`,
      };
      const viewerResponse = await fetch(
        `https://api.twitch.tv/helix/streams?user_id=${channelId}&first=1`,
        { headers }
      );
      const viewerJson = await viewerResponse.json();
      const followerResponse = await fetch(
        `https://api.twitch.tv/helix/users/follows?to_id=${channelId}&first=1`,
        { headers }
      );
      const followerJson = await followerResponse.json();
      const stream = viewerJson["data"][0];
      if (!stream) {
        return {
          isOnline: false,
          viewers: 0,
          followers: followerJson["total"],
        };
      }
      return {
        isOnline: true,
        viewers: stream["viewer_count"],
        followers: followerJson["total"],
      };
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

export const getProfilePicture = functions.https.onRequest(async (req, res) => {
  const provider = req.query?.provider as string | null;
  const channelId = req.query?.channelId as string | null;
  const login = req.query?.login as string | null;
  if (!provider || !(channelId || login)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId, login"
    );
  }

  const queryParam = channelId ? `twitch.id`: `twitch.login`;
  const queryValue = channelId ? channelId: login;

  switch (provider) {
    case "twitch":
      // check if it exists in firestore already.
      const snapshot = await admin
        .firestore()
        .collection("profiles")
        .where(queryParam, "==", queryValue)
        .limit(1)
        .get();
      if (!snapshot.empty) {
        // return the profile picture url from the database instead.
        const url = snapshot.docs[0].get("twitch")[
          "profilePictureUrl"
        ] as string;
        const image = await fetch(url);
        res.setHeader("Content-Type", "image/png");
        res.status(200).send(await image.buffer());
        return;
      }

      const token = await getAppAccessToken(provider);
      if (!token) {
        throw new functions.https.HttpsError("internal", "auth error");
      }
      const headers = {
        Authorization: `Bearer ${token.token["access_token"]}`,
        "Client-Id": TWITCH_CLIENT_ID,
      };
      try {
        const apiParam = channelId ? `id=${channelId}`: `login=${login}`;
        const response = await fetch(
          `https://api.twitch.tv/helix/users?${apiParam}`,
          { headers: headers }
        );
        const json = await response.json();
        const imageUrl =
          json["data"]?.[0]?.["profile_image_url"] ??
          "https://static-cdn.jtvnw.net/user-default-pictures-uv/ebb84563-db81-4b9c-8940-64ed33ccfc7b-profile_image-300x300.png";
        const image = await fetch(imageUrl);
        res.setHeader("Content-Type", "image/png");
        res.status(200).send(await image.buffer());
      } catch (err) {
        console.error(err);
        throw new functions.https.HttpsError("not-found", "image not found");
      }
    default:
      throw new functions.https.HttpsError(
        "invalid-argument",
        "invalid provider"
      );
  }
});

export const demoAuth = functions.https.onCall(async (data, context) => {
  // sign in with automux
  return await admin.auth().createCustomToken("kKa9SYk5eFTjQXaz1soSCdlZMan2");
});

export { subscribe, unsubscribe, eventsub, search, getUserEmotes, cleanup };
export const auth = functions.https.onRequest(authApp);
