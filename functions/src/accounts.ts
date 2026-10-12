import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import fetch from "cross-fetch";
import { KICK_CLIENT_ID, KICK_CLIENT_SECRET, TWITCH_CLIENT_ID } from "./oauth";

// Platforms a user can sign in with. Each linked account lives at
// profiles/{uid}.{provider}, tokens/{uid}.{provider} and the RTDB mapping
// userIds/{provider}/{providerUserId} -> uid.
export const ACCOUNT_PROVIDERS = ["twitch", "kick"];

export function linkedProviders(profile: Record<string, any> | undefined) {
  return ACCOUNT_PROVIDERS.filter((provider) => profile?.[provider]?.id);
}

export type LinkResult = "create" | "existing" | "link" | "conflict";

// Decides how an OAuth callback maps a provider account onto a Firebase user.
// `mappedUid` is the user the provider account already belongs to, if any, and
// `linkUid` is the signed-in user asking to link it.
export function resolveLink(
  mappedUid: string | null,
  linkUid: string | null
): LinkResult {
  if (!linkUid) {
    return mappedUid ? "existing" : "create";
  }
  if (mappedUid && mappedUid !== linkUid) {
    // never silently move an account between users.
    return "conflict";
  }
  return "link";
}

export type UnlinkCheck = "ok" | "not-linked" | "last-account";

export function checkUnlink(
  profile: Record<string, any> | undefined,
  provider: string
): UnlinkCheck {
  const linked = linkedProviders(profile);
  if (!linked.includes(provider)) {
    return "not-linked";
  }
  if (linked.length === 1) {
    return "last-account";
  }
  return "ok";
}

async function revokeToken(provider: string, encoded: string | undefined) {
  if (!encoded) {
    return;
  }
  const token = JSON.parse(encoded);
  switch (provider) {
    case "twitch":
      await fetch("https://id.twitch.tv/oauth2/revoke", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          client_id: TWITCH_CLIENT_ID,
          token: token.access_token,
        }).toString(),
      });
      return;
    case "kick":
      await fetch("https://id.kick.com/oauth/revoke", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          client_id: KICK_CLIENT_ID ?? "",
          client_secret: KICK_CLIENT_SECRET ?? "",
          token: token.refresh_token ?? token.access_token,
          token_hint_type: token.refresh_token
            ? "refresh_token"
            : "access_token",
        }).toString(),
      });
      return;
  }
}

export const unlinkAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("permission-denied", "missing auth");
  }
  const uid = context.auth.uid;
  const provider = data?.provider;
  if (!ACCOUNT_PROVIDERS.includes(provider)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "invalid provider"
    );
  }

  const profileRef = admin.firestore().collection("profiles").doc(uid);
  const tokensRef = admin.firestore().collection("tokens").doc(uid);
  const profile = (await profileRef.get()).data();
  switch (checkUnlink(profile, provider)) {
    case "not-linked":
      throw new functions.https.HttpsError("not-found", "account not linked");
    case "last-account":
      throw new functions.https.HttpsError(
        "failed-precondition",
        "cannot unlink the last account"
      );
  }

  const providerUserId = String(profile![provider].id);
  const encoded = (await tokensRef.get()).get(provider);
  try {
    await revokeToken(provider, encoded);
  } catch (err) {
    // the account is unlinked even if the provider can't be reached.
    functions.logger.warn("failed to revoke token", { provider, err });
  }

  const mappingRef = admin
    .database()
    .ref("userIds")
    .child(provider)
    .child(providerUserId);
  if ((await mappingRef.get()).val() === uid) {
    await mappingRef.remove();
  }
  const remove = { [provider]: admin.firestore.FieldValue.delete() };
  await tokensRef.set(remove, { merge: true });
  await profileRef.update(remove);
});
