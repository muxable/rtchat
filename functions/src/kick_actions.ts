import * as functions from "firebase-functions";
import { kickApi } from "./kick";
import { getAccessToken, getAppAccessToken } from "./oauth";

// Chat actions on Kick, taken on behalf of the signed-in user with their Kick
// token. https://docs.kick.com/apis/chat, https://docs.kick.com/apis/moderation

async function userToken(uid: string) {
  const token = await getAccessToken(uid, "kick");
  if (!token) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "kick account not linked",
    );
  }
  return token;
}

// Message documents are keyed "kick:<message id>", which is what clients
// pass around.
export function toKickMessageId(messageId: string) {
  return messageId.replace(/^kick:/, "");
}

// Kick timeouts are whole minutes between 1 and 10080 (7 days); the app speaks
// in seconds like twitch.
export function toKickTimeoutMinutes(seconds: number) {
  return Math.min(10080, Math.max(1, Math.ceil(seconds / 60)));
}

export async function sendKickMessage(
  uid: string,
  broadcasterId: string,
  message: string,
  replyToMessageId?: string,
) {
  const response = await kickApi(await userToken(uid), "/chat", {
    method: "POST",
    body: JSON.stringify({
      content: message,
      type: "user",
      broadcaster_user_id: Number(broadcasterId),
      ...(replyToMessageId
        ? { reply_to_message_id: toKickMessageId(replyToMessageId) }
        : {}),
    }),
  });
  return response?.data?.message_id ? `kick:${response.data.message_id}` : null;
}

export async function deleteKickMessage(uid: string, messageId: string) {
  await kickApi(
    await userToken(uid),
    `/chat/${encodeURIComponent(toKickMessageId(messageId))}`,
    { method: "DELETE" },
  );
}

// Kick moderation needs user ids; logins are channel slugs, which map to the
// user that owns the channel.
export async function resolveKickUserId(login: string) {
  const token = await getAppAccessToken("kick");
  if (!token) {
    throw new functions.https.HttpsError("internal", "kick auth error");
  }
  const response = await kickApi(
    String(token.token.access_token),
    `/channels?slug=${encodeURIComponent(login)}`,
  );
  const id = response?.data?.[0]?.broadcaster_user_id;
  if (!id) {
    throw new functions.https.HttpsError("not-found", "kick user not found");
  }
  return String(id);
}

export async function banKickUser(
  uid: string,
  broadcasterId: string,
  userId: string,
  options: { durationSeconds?: number; reason?: string } = {},
) {
  await kickApi(await userToken(uid), "/moderation/bans", {
    method: "POST",
    body: JSON.stringify({
      broadcaster_user_id: Number(broadcasterId),
      user_id: Number(userId),
      ...(options.durationSeconds
        ? { duration: toKickTimeoutMinutes(options.durationSeconds) }
        : {}),
      ...(options.reason ? { reason: options.reason.slice(0, 100) } : {}),
    }),
  });
}

export async function unbanKickUser(
  uid: string,
  broadcasterId: string,
  userId: string,
) {
  await kickApi(await userToken(uid), "/moderation/bans", {
    method: "DELETE",
    body: JSON.stringify({
      broadcaster_user_id: Number(broadcasterId),
      user_id: Number(userId),
    }),
  });
}
