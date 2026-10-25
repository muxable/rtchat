package main

import (
	"testing"
	"time"

	"cloud.google.com/go/firestore"
)

func TestHeartbeatFilter(t *testing.T) {
	f := newHeartbeatFilter()
	subscribed := time.Unix(100, 0)
	steps := []struct {
		kind firestore.DocumentChangeKind
		data map[string]interface{}
		skip bool
	}{
		{firestore.DocumentAdded, map[string]interface{}{"subscribedAt": subscribed}, false},
		// a heartbeat alone keeps the running client.
		{firestore.DocumentModified, map[string]interface{}{"subscribedAt": subscribed, "heartbeatAt": time.Unix(200, 0)}, true},
		{firestore.DocumentModified, map[string]interface{}{"subscribedAt": subscribed, "heartbeatAt": time.Unix(300, 0)}, true},
		// a subscribe on channel open still reconnects, as before.
		{firestore.DocumentModified, map[string]interface{}{"subscribedAt": time.Unix(400, 0)}, false},
		{firestore.DocumentModified, map[string]interface{}{"subscribedAt": time.Unix(500, 0)}, false},
		// cleaned up, then recreated by a heartbeat: joined again.
		{firestore.DocumentRemoved, nil, false},
		{firestore.DocumentAdded, map[string]interface{}{"heartbeatAt": time.Unix(600, 0)}, false},
		{firestore.DocumentModified, map[string]interface{}{"heartbeatAt": time.Unix(700, 0)}, true},
		{firestore.DocumentModified, map[string]interface{}{"heartbeatAt": time.Unix(800, 0), "subscribedAt": time.Unix(800, 0)}, false},
	}
	for i, step := range steps {
		if got := f.heartbeatOnly("twitch:room", step.kind, step.data); got != step.skip {
			t.Fatalf("step %d: skip = %v, want %v", i, got, step.skip)
		}
	}
	// a modification of a channel not seen yet (e.g. after a snapshot reset)
	// isn't skipped.
	if f.heartbeatOnly("twitch:other", firestore.DocumentModified, map[string]interface{}{"heartbeatAt": time.Unix(1, 0)}) {
		t.Fatal("skipped an unseen channel")
	}
}
