package main

import "sync"

// initialJoins reports when every channel from the first assignments snapshot
// has been applied, so an instance only passes its health check once it is
// actually reading those channels. Otherwise a rolling deploy can delete the
// old instances while the new ones are still joining.
type initialJoins struct {
	mu      sync.Mutex
	pending map[string]bool
	sealed  bool
	fired   bool
	onDone  func()
}

func newInitialJoins(onDone func()) *initialJoins {
	return &initialJoins{pending: map[string]bool{}, onDone: onDone}
}

// add must be called before the channel is submitted.
func (j *initialJoins) add(key string) {
	j.mu.Lock()
	defer j.mu.Unlock()
	if !j.sealed {
		j.pending[key] = true
	}
}

// seal marks the end of the first snapshot.
func (j *initialJoins) seal() {
	j.mu.Lock()
	j.sealed = true
	j.mu.Unlock()
	j.check()
}

func (j *initialJoins) done(key string) {
	j.mu.Lock()
	delete(j.pending, key)
	j.mu.Unlock()
	j.check()
}

func (j *initialJoins) check() {
	j.mu.Lock()
	fire := j.sealed && len(j.pending) == 0 && !j.fired
	if fire {
		j.fired = true
	}
	j.mu.Unlock()
	if fire {
		j.onDone()
	}
}
