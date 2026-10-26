// How long a channels/{channelId}/messages document lives. Writers set
// expiresAt to the write time plus this, and the Firestore TTL policy on
// messages.expiresAt deletes the document after that. Matches
// chatmessage.TTL in the agent.
export const MESSAGE_TTL_MS = 7 * 24 * 60 * 60 * 1000;
