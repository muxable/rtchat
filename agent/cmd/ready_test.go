package main

import (
	"errors"
	"io"
	"sync/atomic"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/agent"
)

func TestInitialJoinsWaitsForEveryChannel(t *testing.T) {
	fired := 0
	j := newInitialJoins(func() { fired++ })
	j.add("twitch:a")
	j.add("twitch:b")
	j.done("twitch:a")
	j.seal()
	if fired != 0 {
		t.Fatal("ready before every initial channel was applied")
	}
	j.add("twitch:late") // after seal: not part of the initial set
	j.done("twitch:b")
	j.done("twitch:b")
	if fired != 1 {
		t.Fatalf("fired %d times", fired)
	}
}

func TestInitialJoinsWaitsForSeal(t *testing.T) {
	fired := 0
	j := newInitialJoins(func() { fired++ })
	j.add("twitch:a")
	j.done("twitch:a")
	if fired != 0 {
		t.Fatal("ready before the first snapshot finished")
	}
	j.seal()
	if fired != 1 {
		t.Fatal("not ready after an applied snapshot")
	}
}

func TestEmptySnapshotIsReady(t *testing.T) {
	fired := false
	newInitialJoins(func() { fired = true }).seal()
	if !fired {
		t.Fatal("empty snapshot not ready")
	}
}

func TestAppliedHookRunsAfterFailedJoins(t *testing.T) {
	m := newRequestManager(func(*agent.Request) (io.Closer, error) { return nil, errors.New("offline") })
	ready := &atomic.Bool{}
	j := newInitialJoins(func() { ready.Store(true) })
	m.applied = j.done
	for _, id := range []string{"twitch:a", "twitch:b"} {
		j.add(id)
		m.submit((*agent.Request)(&firestore.DocumentRef{ID: id}), firestore.DocumentAdded)
	}
	j.seal()
	deadline := time.Now().Add(time.Second)
	for !ready.Load() {
		if time.Now().After(deadline) {
			t.Fatal("failed joins never counted as applied")
		}
		time.Sleep(time.Millisecond)
	}
}
