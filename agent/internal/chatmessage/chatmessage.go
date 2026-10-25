// Package chatmessage holds settings shared by every writer of
// channels/{channelId}/messages documents.
package chatmessage

import "time"

// TTL is how long a message document lives. Writers set expiresAt to the
// write time plus TTL, and the Firestore TTL policy on messages.expiresAt
// deletes the document after that.
const TTL = 7 * 24 * time.Hour
