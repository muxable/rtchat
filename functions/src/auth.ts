import * as crypto from "crypto";
import express from "express";
import { rateLimit } from "express-rate-limit";
import expressSession from "express-session";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import fetch from "cross-fetch";
import { AuthorizationCode } from "simple-oauth2";
import {
  codeChallenge,
  createCodeVerifier,
  getKickProfile,
  KICK_SCOPES,
} from "./kick";
import {
  isValidState,
  oauthConfig,
  STREAMELEMENTS_OAUTH_CONFIG,
  STREAMLABS_OAUTH_CONFIG,
  TWITCH_CLIENT_ID,
  TWITCH_OAUTH_CONFIG,
} from "./oauth";
import { Store, SessionData } from "express-session";
import { getYouTubeProfile, YOUTUBE_SCOPES } from "./youtube_actions";

admin.initializeApp();

export interface StoreOptions {
  dataset: admin.firestore.Firestore;
  kind?: string;
}

export class FirestoreStore extends Store {
  db: admin.firestore.Firestore;
  kind: string;
  constructor(options: StoreOptions) {
    super();
    this.db = options.dataset;
    if (!this.db) {
      throw new Error("No dataset provided to Firestore Session.");
    }
    this.kind = options.kind || "Session";
  }

  get = (
    sid: string,
    callback: (err?: Error | null, session?: SessionData) => void,
  ) => {
    this.db
      .collection(this.kind)
      .doc(sid)
      .get()
      .then((doc) => {
        if (!doc.exists) {
          return callback();
        }

        try {
          const result = JSON.parse(doc.data()!.data);
          return callback(null, result);
        } catch (err) {
          return callback(err as Error);
        }
      }, callback);
  };

  set = (
    sid: string,
    session: SessionData,
    callback?: (err?: Error) => void,
  ) => {
    callback = callback || (() => {});
    let sessJson;

    try {
      sessJson = JSON.stringify(session);
    } catch (err) {
      return callback(err as Error);
    }

    this.db
      .collection(this.kind)
      .doc(sid)
      .set({ data: sessJson })
      .then(() => {
        callback!();
      });
  };

  destroy = (sid: string, callback?: (err?: Error) => void) => {
    callback = callback || (() => {});
    this.db
      .collection(this.kind)
      .doc(sid)
      .delete()
      .then(() => callback!(), callback);
  };
}

const app = express();

// requests arrive through Google's front end, which sets X-Forwarded-For.
app.set("trust proxy", 1);

// each sign-in is a handful of requests; this only slows down abuse.
app.use(
  "/auth",
  rateLimit({
    windowMs: 60 * 1000,
    limit: 30,
    standardHeaders: "draft-7",
    legacyHeaders: false,
  }),
);

app.use(
  expressSession({
    store: new FirestoreStore({
      dataset: admin.firestore(),
      kind: "express-sessions",
    }),
    name: "__session",
    secret: functions.config().express.secret,
    resave: true,
    saveUninitialized: true,
    rolling: true,
    cookie: { maxAge: 60000, secure: "auto", httpOnly: true },
  }),
);

declare module "express-session" {
  interface Session {
    companion?: string;
    state?: string;
    token?: string;
    provider?: string;
    codeVerifier?: string;
  }
}

const HOST =
  process.env.NODE_ENV === "production"
    ? "https://chat.rtirl.com"
    : "http://localhost:5000";

app.get("/auth/twitch/redirect", (req, res) => {
  const state = req.session.state || crypto.randomBytes(20).toString("hex");
  req.session.companion = req.query.companion?.toString();
  req.session.state = state.toString();
  const redirectUri = new AuthorizationCode(TWITCH_OAUTH_CONFIG).authorizeURL({
    redirect_uri: `${HOST}/auth/twitch/callback`,
    scope: [
      "bits:read",
      "channel:bot",
      "channel:edit:commercial",
      "channel:manage:ads",
      "channel:manage:broadcast",
      "channel:manage:moderators",
      "channel:manage:polls",
      "channel:manage:predictions",
      "channel:manage:raids",
      "channel:manage:vips",
      "channel:moderate",
      "channel:read:ads",
      "channel:read:hype_train",
      "channel:read:redemptions",
      "channel:read:subscriptions",
      "chat:edit",
      "chat:read",
      "moderation:read",
      "moderator:manage:banned_users",
      "moderator:manage:chat_messages",
      "moderator:manage:chat_settings",
      "moderator:manage:shoutouts",
      "moderator:manage:warnings",
      "moderator:read:chatters",
      "moderator:read:followers",
      "moderator:read:shoutouts",
      "user:bot",
      "user:read:email",
      "user:read:emotes",
      "user:read:follows",
      "user:read:moderated_channels",
      "user:read:subscriptions",
      "user:write:chat",
    ],
    state: state,
  });
  res.redirect(`${redirectUri}&force_verify=true`);
});

app.get("/auth/twitch/callback", async (req, res) => {
  if (!isValidState(req.session?.state, req.query.state)) {
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
  }).then((response) => response.json() as any);

  req.session.state = undefined;

  const twitchProfile = {
    id: users["data"][0]["id"],
    displayName: users["data"][0]["display_name"],
    login: users["data"][0]["login"],
    profilePictureUrl: users["data"][0]["profile_image_url"],
    email: users["data"][0]["email"] || null,
  };

  await completeSignIn(req, res, "twitch", twitchProfile, results.token);
});

// Maps a provider account to a Firebase user (creating one if needed), stores
// the provider's token and profile, and hands a custom token back to the app.
async function completeSignIn(
  req: express.Request,
  res: express.Response,
  provider: string,
  profile: { id: string },
  token: object,
) {
  // check if this user exists already.
  const userIdRef = admin
    .database()
    .ref("userIds")
    .child(provider)
    .child(profile.id);
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
    .set({ [provider]: JSON.stringify(token) }, { merge: true });

  // save the profile information too.
  await admin
    .firestore()
    .collection("profiles")
    .doc(firebaseUserId)
    .set({ [provider]: profile }, { merge: true });

  const customToken = await admin.auth().createCustomToken(firebaseUserId);

  if (req.session.companion) {
    await admin
      .firestore()
      .collection("companion-tokens")
      .doc(req.session.companion)
      .set({ token: customToken }, { merge: true });
    res.send("Logged in successfully.");
  } else {
    res.redirect(
      "com.rtirl.chat://success?token=" + encodeURIComponent(customToken),
    );
  }
}

app.get("/auth/kick/redirect", (req, res) => {
  const state = crypto.randomBytes(20).toString("hex");
  const verifier = createCodeVerifier();
  req.session.companion = req.query.companion?.toString();
  req.session.state = state;
  req.session.codeVerifier = verifier;
  const redirectUri = new AuthorizationCode(oauthConfig("kick")).authorizeURL({
    redirect_uri: `${HOST}/auth/kick/callback`,
    scope: KICK_SCOPES,
    state,
    code_challenge: codeChallenge(verifier),
    code_challenge_method: "S256",
  } as any);
  res.redirect(redirectUri);
});

app.get("/auth/kick/callback", async (req, res) => {
  const verifier = req.session?.codeVerifier;
  if (!isValidState(req.session?.state, req.query.state) || !verifier) {
    res.redirect("/auth/kick/redirect");
    return;
  }
  req.session.state = undefined;
  req.session.codeVerifier = undefined;

  const results = await new AuthorizationCode(oauthConfig("kick")).getToken({
    code: String(req.query.code),
    redirect_uri: `${HOST}/auth/kick/callback`,
    code_verifier: verifier,
  } as any);

  const profile = await getKickProfile(String(results.token.access_token));
  await completeSignIn(req, res, "kick", profile, results.token);
});

app.get("/auth/youtube/redirect", (req, res) => {
  const state = crypto.randomBytes(20).toString("hex");
  req.session.companion = req.query.companion?.toString();
  req.session.state = state;
  const redirectUri = new AuthorizationCode(
    oauthConfig("youtube"),
  ).authorizeURL({
    redirect_uri: `${HOST}/auth/youtube/callback`,
    scope: YOUTUBE_SCOPES,
    state,
    // a refresh token is only issued with offline access, and only on the
    // first consent unless consent is prompted again.
    access_type: "offline",
    prompt: "consent select_account",
    include_granted_scopes: "true",
  } as any);
  res.redirect(redirectUri);
});

type SignInError = "access_denied" | "sign_in_failed" | "no_youtube_channel";

// only fixed codes are echoed back: the error query parameter is attacker
// controlled, so it's never reflected.
function signInError(
  req: express.Request,
  res: express.Response,
  message: SignInError,
) {
  if (req.session.companion) {
    res.status(400).type("text/plain").send(message);
  } else {
    res.redirect(
      "com.rtirl.chat://error?message=" + encodeURIComponent(message),
    );
  }
}

app.get("/auth/youtube/callback", async (req, res) => {
  if (!isValidState(req.session?.state, req.query.state)) {
    res.redirect("/auth/youtube/redirect");
    return;
  }
  req.session.state = undefined;
  if (req.query.error || !req.query.code) {
    signInError(
      req,
      res,
      !req.query.error || req.query.error === "access_denied"
        ? "access_denied"
        : "sign_in_failed",
    );
    return;
  }

  const results = await new AuthorizationCode(oauthConfig("youtube")).getToken({
    code: String(req.query.code),
    redirect_uri: `${HOST}/auth/youtube/callback`,
  });

  const profile = await getYouTubeProfile(String(results.token.access_token));
  if (!profile) {
    signInError(req, res, "no_youtube_channel");
    return;
  }
  await completeSignIn(req, res, "youtube", profile, results.token);
});

app.get("/auth/streamlabs/redirect", (req, res) => {
  req.session.token = req.query.token?.toString();
  req.session.provider = req.query.provider?.toString();
  const redirectUri = new AuthorizationCode(
    STREAMLABS_OAUTH_CONFIG,
  ).authorizeURL({
    redirect_uri: `${HOST}/auth/streamlabs/callback`,
    scope: ["donations.read", "socket.token"],
  });
  res.redirect(redirectUri);
});

async function toUserId(token?: string) {
  if (!token) {
    return null;
  }
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    return decoded.uid;
  } catch (e) {
    return null;
  }
}

app.get("/auth/streamlabs/callback", async (req, res) => {
  const provider = req.session.provider;
  const uid = await toUserId(req.session.token);
  if (!uid || !provider) {
    res.redirect("com.rtirl.chat://error?message=invalid_token");
    return;
  }
  const results = await new AuthorizationCode(STREAMLABS_OAUTH_CONFIG).getToken(
    {
      code: String(req.query.code),
      redirect_uri: `${HOST}/auth/streamlabs/callback`,
    },
  );
  const usernameDoc = await admin
    .firestore()
    .collection("profiles")
    .doc(uid)
    .get();

  const channelId = `${provider}:${usernameDoc.get(provider)["id"]}`;

  admin
    .firestore()
    .collection("streamlabs")
    .doc(uid)
    .set({ token: JSON.stringify(results.token), channelId }, { merge: true });

  res.redirect("com.rtirl.chat://success?token=1");
});

app.get("/auth/streamelements/redirect", (req, res) => {
  req.session.token = req.query.token?.toString();
  req.session.provider = req.query.provider?.toString();
  const redirectUri = new AuthorizationCode(
    STREAMELEMENTS_OAUTH_CONFIG,
  ).authorizeURL({
    redirect_uri: `${HOST}/auth/streamelements/callback`,
    scope: ["tips:read"],
  });
  res.redirect(redirectUri);
});

app.get("/auth/streamelements/callback", async (req, res) => {
  const provider = req.session.provider;
  const uid = await toUserId(req.session.token);
  if (!uid || !provider) {
    res.redirect("com.rtirl.chat://error?message=invalid_token");
    return;
  }
  // not sure why simple-oauth2 doesn't work here...
  const url =
    STREAMELEMENTS_OAUTH_CONFIG.auth.tokenHost +
    STREAMELEMENTS_OAUTH_CONFIG.auth.tokenPath;
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      client_id: STREAMELEMENTS_OAUTH_CONFIG.client.id,
      client_secret: STREAMELEMENTS_OAUTH_CONFIG.client.secret,
      grant_type: "authorization_code",
      redirect_uri: `https://chat.rtirl.com/auth/streamelements/callback`,
      code: String(req.query.code),
    }),
  });
  if (!response.ok) {
    res.redirect("com.rtirl.chat://error?message=invalid_token");
    return;
  }
  const json = await response.json();
  const expiresAt = new Date(+new Date() + json.expires_in * 1000);
  const usernameDoc = await admin
    .firestore()
    .collection("profiles")
    .doc(uid)
    .get();

  const channelId = `${provider}:${usernameDoc.get(provider)["id"]}`;

  admin
    .firestore()
    .collection("streamelements")
    .doc(uid)
    .set(
      {
        token: JSON.stringify({ ...json, expires_at: expiresAt.toISOString() }),
        channelId,
      },
      { merge: true },
    );

  res.redirect("com.rtirl.chat://success?token=1");
});

export { app };
