package main

import (
	"testing"
	"time"
)

func TestSnapshotLoopStuckOnlyAfterAMinute(t *testing.T) {
	var loop snapshotLoop
	now := time.Now()
	if loop.stuck(now) {
		t.Fatal("stuck before the first snapshot")
	}
	loop.applying(now)
	if loop.stuck(now.Add(10 * time.Second)) {
		t.Fatal("a few seconds of applying changes counted as stuck")
	}
	if !loop.stuck(now.Add(stuckAfter + time.Second)) {
		t.Fatal("a loop applying changes for over a minute was not stuck")
	}
	loop.listening()
	if loop.stuck(now.Add(time.Hour)) {
		t.Fatal("stuck while listening")
	}
}
