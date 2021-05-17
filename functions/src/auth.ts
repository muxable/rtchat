import { FirestoreStore } from "@google-cloud/connect-firestore";
import { Firestore } from "@google-cloud/firestore";
import * as crypto from "crypto";
import * as express from "express";
import * as expressSession from "express-session";
import * as admin from "firebase-admin";
import fetch from "node-fetch";
import { AuthorizationCode } from "simple-oauth2";
import { TWITCH_CLIENT_ID, TWITCH_OAUTH_CONFIG } from "./oauth";
import { v4 as uuidv4 } from "uuid";

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

async function createFirebaseAccount(uid: string, externalToken: string) {
  await admin
    .auth()
    .getUser(uid)
    .catch((error) => {
      // If user does not exists we create it.
      if (error.code === "auth/user-not-found") {
        return admin
          .auth()
          .createUser({ uid })
          .then(() => admin.database().ref("keys").child(uid).set(uuidv4()));
      }
      throw error;
    });

  const token = await admin.auth().createCustomToken(uid);

  const key = (await admin.database().ref("keys").child(uid).get()).val();

  if (!key) {
    throw new Error("key not found!");
  }

  await admin
    .firestore()
    .collection("profiles")
    .doc(key)
    .set({ userId: uid, token: externalToken }, { merge: true });

  return { token, key };
}

app.get("/auth/twitch/redirect", (req, res) => {
  const state = req.session.state || crypto.randomBytes(20).toString("hex");
  req.session.state = state.toString();
  const redirectUri = new AuthorizationCode(TWITCH_OAUTH_CONFIG).authorizeURL({
    redirect_uri: `${HOST}/auth/twitch/callback`,
    scope: ["user:read:email", "chat:read", "chat:edit"],
    state: state,
  });
  res.redirect(`${redirectUri}&force_verify=true`);
});

app.get("/auth/twitch/callback", async (req, res) => {
  if (!req.session?.state) {
    res.status(500).send("state not set");
    return;
  } else if (req.session.state !== req.session.state) {
    res.status(403).send("incorrect state");
    return;
  }
  const results = await new AuthorizationCode(TWITCH_OAUTH_CONFIG).getToken({
    code: String(req.query.code),
    redirect_uri: `${HOST}/auth/twitch/callback`,
  });

  const accessToken = JSON.stringify(results.token);

  const users = await fetch("https://api.twitch.tv/helix/users", {
    headers: {
      Authorization: `Bearer ${results.token.access_token}`,
      "Client-Id": TWITCH_CLIENT_ID,
    },
  }).then((response) => response.json());

  req.session.state = undefined;

  const userId = `twitch:${users["data"][0]["id"]}`;
  const email = users["data"][0]["email"];

  // Create a Firebase account and get the Custom Auth Token.
  const { token, key } = await createFirebaseAccount(userId, accessToken);

  await admin.auth().updateUser(userId, { email, emailVerified: true });

  await admin
    .firestore()
    .collection("profiles")
    .doc(key)
    .set(
      {
        displayName: users["data"][0]["display_name"],
        url: `https://twitch.tv/${users["data"][0]["login"]}`,
        profilePictureUrl: users["data"][0]["profile_image_url"],
      },
      { merge: true }
    );

  // we can be a bit handwavey here because this request is automatically https'd.
  // it would probably be smarter to put this in a cookie, but whatever.
  res.redirect("/?provider=twitch&token=" + encodeURIComponent(token));
});

export { app };
