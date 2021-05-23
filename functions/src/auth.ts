import { FirestoreStore } from "@google-cloud/connect-firestore";
import { Firestore } from "@google-cloud/firestore";
import * as crypto from "crypto";
import * as express from "express";
import * as expressSession from "express-session";
import * as admin from "firebase-admin";
import fetch from "node-fetch";
import { AuthorizationCode } from "simple-oauth2";
import { TWITCH_CLIENT_ID, TWITCH_OAUTH_CONFIG } from "./oauth";

const app = express();

app.use(
  expressSession({
    store: new FirestoreStore({
      dataset: new Firestore(),
      kind: "express-sessions",
    }),
    name: "__session",
    secret: "ishdcr78aw34rycn*&#FHCa8e7fh32c",
    resave: true,
    saveUninitialized: true,
    rolling: true,
    cookie: { maxAge: 60000, secure: "auto", httpOnly: true },
  })
);

declare module "express-session" {
  interface Session {
    state?: string;
  }
}

const HOST =
  process.env.NODE_ENV === "production"
    ? "https://chat.rtirl.com"
    : "http://localhost:5000";

app.get("/auth/twitch/redirect", (req, res) => {
  const state = req.session.state || crypto.randomBytes(20).toString("hex");
  req.session.state = state.toString();
  const redirectUri = new AuthorizationCode(TWITCH_OAUTH_CONFIG).authorizeURL({
    redirect_uri: `${HOST}/auth/twitch/callback`,
    scope: ["user:read:email", "chat:read", "chat:edit", "channel:moderate"],
    state: state,
  });
  res.redirect(`${redirectUri}&force_verify=true`);
});

app.get("/auth/twitch/callback", async (req, res) => {
  if (!req.session?.state || req.session.state !== req.session.state) {
    console.error(new Error("invalid state"));
    res.redirect("/auth/twitch/redirect");
    return;
  }
  const results = await new AuthorizationCode(TWITCH_OAUTH_CONFIG).getToken({
    code: String(req.query.code),
    redirect_uri: `${HOST}/auth/twitch/callback`,
  });

  const users = await fetch("https://api.twitch.tv/helix/users", {
    headers: {
      Authorization: `Bearer ${results.token.access_token}`,
      "Client-Id": TWITCH_CLIENT_ID,
    },
  }).then((response) => response.json());

  req.session.state = undefined;

  const twitchUserId = users["data"][0]["id"];
  const email = users["data"][0]["email"];

  // check if this user exists already.
  const userIdRef = admin
    .database()
    .ref("userIds")
    .child("twitch")
    .child(twitchUserId);
  const firebaseUserIdDoc = await userIdRef.get();
  let firebaseUserId = firebaseUserIdDoc.val();
  if (!firebaseUserId) {
    const userRecord = await admin.auth().createUser({});
    await userIdRef.set(userRecord.uid);
    firebaseUserId = userRecord.uid;
  }

  // save the token to the user doc.
  await admin
    .firestore()
    .collection("tokens")
    .doc(firebaseUserId)
    .set({ twitch: JSON.stringify(results.token) }, { merge: true });

  // save the profile information too.
  const twitchProfile = {
    email,
    id: users["data"][0]["id"],
    displayName: users["data"][0]["display_name"],
    login: users["data"][0]["login"],
    profilePictureUrl: users["data"][0]["profile_image_url"],
  };

  await admin
    .firestore()
    .collection("profiles")
    .doc(firebaseUserId)
    .set({ twitch: twitchProfile }, { merge: true });

  // we can be a bit handwavey here because this request is automatically https'd.
  // it would probably be smarter to put this in a cookie, but whatever.
  const token = await admin.auth().createCustomToken(firebaseUserId);
  res.redirect("/?token=" + encodeURIComponent(token));
});

export { app };
