package webhook

import "github.com/muxable/rtchat/agent/internal/chatmessage"

// messageTTL is how long the message documents written by webhooks live.
const messageTTL = chatmessage.TTL
