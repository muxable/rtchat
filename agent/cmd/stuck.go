package main

import (
	"sync/atomic"
	"time"
)

// stuckAfter is how long the snapshot loop may spend applying one batch of
// assignment changes before autohealing replaces the agent. The daily idle
// cleanup removes dozens of channels at once; applying that takes seconds and
// must not make every replica unhealthy at the same time.
const stuckAfter = time.Minute

// snapshotLoop tracks when the assignment snapshot loop stopped listening.
type snapshotLoop struct {
	busySince atomic.Int64
}

func (l *snapshotLoop) listening() { l.busySince.Store(0) }

func (l *snapshotLoop) applying(now time.Time) { l.busySince.Store(now.UnixNano()) }

// stuck reports whether the loop has been applying changes for too long.
func (l *snapshotLoop) stuck(now time.Time) bool {
	since := l.busySince.Load()
	return since != 0 && now.Sub(time.Unix(0, since)) > stuckAfter
}
