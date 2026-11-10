// Package chatmessage holds settings shared by every writer of
// channels/{channelId}/messages documents.
package chatmessage

import "time"

// TTL is how long a message document lives. Writers set expiresAt to the
// write time plus TTL, and the Firestore TTL policy on messages.expiresAt
// deletes the document after that.
const TTL = 7 * 24 * time.Hour

// StreamStateTTL is how long stream.online and stream.offline documents live.
// The app reads the latest of them to decide whether a channel is live (which
// gates message alerts and audio sources) and to show uptime, so they must
// outlive the longest continuous stream, not just the chat history.
const StreamStateTTL = 90 * 24 * time.Hour

// TTLFor returns how long a message document of messageType lives.
func TTLFor(messageType string) time.Duration {
	switch messageType {
	case "stream.online", "stream.offline":
		return StreamStateTTL
	}
	return TTL
}
