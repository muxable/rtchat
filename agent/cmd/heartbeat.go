package main

import (
	"reflect"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/subscriptions"
)

// heartbeatFilter drops assignment changes that only moved the heartbeat, so
// a client re-subscribing to keep a channel collected doesn't reconnect its
// chat. Additions and removals always pass, so a channel cleaned up and then
// recreated by a heartbeat is joined again. It is used from the snapshot loop
// only, so it isn't safe for concurrent use.
type heartbeatFilter struct {
	seen map[string]map[string]interface{}
}

func newHeartbeatFilter() *heartbeatFilter {
	return &heartbeatFilter{seen: map[string]map[string]interface{}{}}
}

// heartbeatOnly records the change and reports whether it should be skipped.
func (f *heartbeatFilter) heartbeatOnly(key string, kind firestore.DocumentChangeKind, data map[string]interface{}) bool {
	if kind == firestore.DocumentRemoved {
		delete(f.seen, key)
		return false
	}
	rest := make(map[string]interface{}, len(data))
	for field, value := range data {
		if field != subscriptions.HeartbeatField {
			rest[field] = value
		}
	}
	previous, ok := f.seen[key]
	f.seen[key] = rest
	return kind == firestore.DocumentModified && ok && reflect.DeepEqual(previous, rest)
}
