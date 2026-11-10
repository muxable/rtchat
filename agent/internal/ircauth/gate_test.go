package ircauth

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"
)

func TestReplicasShareAuthenticationBudget(t *testing.T) {
	var mu sync.Mutex
	next := map[string]time.Time{}
	attempts := map[string][]time.Time{}
	reserve := func(ctx context.Context, login string) (time.Duration, error) {
		mu.Lock()
		defer mu.Unlock()
		now := time.Now()
		if next[login].After(now) {
			return next[login].Sub(now), nil
		}
		next[login] = now.Add(time.Millisecond)
		attempts[login] = append(attempts[login], now)
		return 0, nil
	}
	var done sync.WaitGroup
	// Each Gate is a separate process sharing the transactional store. A deployment
	// starts many channel readers, all authenticating as the same fallback bot.
	for replica := 0; replica < 3; replica++ {
		gate := &Gate{reserve: reserve}
		for channel := 0; channel < 25; channel++ {
			done.Add(1)
			go func() {
				defer done.Done()
				if err := gate.Wait(context.Background(), "bot"); err != nil {
					t.Error(err)
				}
			}()
		}
	}
	done.Wait()
	if len(attempts["bot"]) != 75 {
		t.Fatal(attempts)
	}
	for i := 1; i < len(attempts["bot"]); i++ {
		if attempts["bot"][i].Sub(attempts["bot"][i-1]) < time.Millisecond {
			t.Fatal("authentication burst exceeded shared budget")
		}
	}
}

func TestWaitingCanBeCanceledAndErrorsPropagate(t *testing.T) {
	want := errors.New("store unavailable")
	gate := &Gate{reserve: func(context.Context, string) (time.Duration, error) { return 0, want }}
	if err := gate.Wait(context.Background(), "bot"); !errors.Is(err, want) {
		t.Fatal(err)
	}
	gate.reserve = func(context.Context, string) (time.Duration, error) { return time.Hour, nil }
	ctx, cancel := context.WithTimeout(context.Background(), time.Millisecond)
	defer cancel()
	if err := gate.Wait(ctx, "bot"); !errors.Is(err, context.DeadlineExceeded) {
		t.Fatal(err)
	}
	// A queued local waiter also observes cancellation without entering the store.
	lock := make(chan struct{}, 1)
	lock <- struct{}{}
	gate.locks.Store("blocked", lock)
	if err := gate.Wait(ctx, "blocked"); !errors.Is(err, context.DeadlineExceeded) {
		t.Fatal(err)
	}
}
