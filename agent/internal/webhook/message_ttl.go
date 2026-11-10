package webhook

import (
	"time"

	"github.com/muxable/rtchat/agent/internal/chatmessage"
)

// messageTTL is how long the message documents written by webhooks live.
const messageTTL = chatmessage.TTL

// messageTTLFor is how long a webhook message document of messageType lives;
// stream.online and stream.offline documents outlive the rest.
func messageTTLFor(messageType string) time.Duration {
	return chatmessage.TTLFor(messageType)
}
