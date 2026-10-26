package ircauth

import (
	"context"
	"fmt"
	"os"
	"sort"
	"sync"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"google.golang.org/api/option"
)

func TestFirestoreReplicasShareAuthenticationSlots(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST for transaction integration tests")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	db, err := firestore.NewClient(ctx, fmt.Sprintf("irc-%d", time.Now().UnixNano()), option.WithoutAuthentication())
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	var done sync.WaitGroup
	attempts := make(chan time.Time, 6)
	start := time.Now()
	for replica := 0; replica < 3; replica++ {
		gate := NewFirestoreGate(db)
		for channel := 0; channel < 2; channel++ {
			done.Add(1)
			go func() {
				defer done.Done()
				if err := gate.Wait(ctx, "shared-bot"); err != nil {
					t.Error(err)
					return
				}
				attempts <- time.Now()
			}()
		}
	}
	done.Wait()
	close(attempts)
	var times []time.Time
	for attempt := range attempts {
		times = append(times, attempt)
	}
	if len(times) != 6 {
		t.Fatalf("only %d attempts completed", len(times))
	}
	sort.Slice(times, func(i, j int) bool { return times[i].Before(times[j]) })
	if times[5].Sub(start) < 5*time.Second {
		t.Fatal("replicas authenticated without sharing the Firestore budget")
	}
	for i := 1; i < len(times); i++ {
		if times[i].Sub(times[i-1]) < 500*time.Millisecond {
			t.Fatal("authentication slots overlapped", times)
		}
	}
	// Unrelated users do not wait behind the shared fallback account.
	if err := NewFirestoreGate(db).Wait(ctx, "other-user"); err != nil {
		t.Fatal(err)
	}
}
