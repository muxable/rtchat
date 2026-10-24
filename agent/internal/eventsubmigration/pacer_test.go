package eventsubmigration

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"testing"
	"time"
)

type fakeClock struct {
	mu     sync.Mutex
	now    time.Time
	sleeps []time.Duration
}

func (c *fakeClock) Now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.now
}
func (c *fakeClock) Sleep(ctx context.Context, d time.Duration) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.sleeps = append(c.sleeps, d)
	c.now = c.now.Add(d)
	return ctx.Err()
}

func TestPacerSpacesEveryRequestAndYieldsBelowReserve(t *testing.T) {
	clock := &fakeClock{now: time.Unix(1_800_000_000, 0)}
	var mu sync.Mutex
	remaining, requests := 700, 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		defer mu.Unlock()
		requests++
		w.Header().Set("Ratelimit-Remaining", strconv.Itoa(remaining))
		w.Header().Set("Ratelimit-Reset", strconv.FormatInt(clock.Now().Add(30*time.Second).Unix(), 10))
		page := Listing{Data: []Subscription{}}
		if r.URL.Query().Get("after") == "" {
			// A paged listing: every page is paced too.
			page.Pagination.Cursor = "next"
		}
		json.NewEncoder(w).Encode(page)
	}))
	defer server.Close()
	pacer := NewPacer(150, 200)
	pacer.Now, pacer.Sleep = clock.Now, clock.Sleep
	api := &API{Client: server.Client(), BaseURL: server.URL, ClientID: "client", Token: "token", Pacer: pacer}
	start := clock.Now()
	for i := 0; i < 2; i++ {
		if _, err := api.List(context.Background(), nil); err != nil {
			t.Fatal(err)
		}
	}
	// Four requests at 150/min: three 400ms gaps, no reserve hold.
	if requests != 4 || clock.Now().Sub(start) != 1200*time.Millisecond {
		t.Fatal(requests, clock.Now().Sub(start), clock.sleeps)
	}
	if pacer.Throttled() {
		t.Fatal("throttled above reserve")
	}
	mu.Lock()
	remaining = 150
	mu.Unlock()
	if err := api.Delete(context.Background(), "x"); err != nil {
		t.Fatal(err)
	}
	if !pacer.Throttled() {
		t.Fatal("not throttled below reserve")
	}
	before := clock.Now()
	if err := pacer.Hold(context.Background()); err != nil {
		t.Fatal(err)
	}
	// Ratelimit-Reset was 30s after the last response; hold until just past it.
	if waited := clock.Now().Sub(before); waited < 30*time.Second || waited > 32*time.Second {
		t.Fatal("did not wait for the bucket to reset", waited)
	}
	if pacer.Throttled() {
		t.Fatal("still throttled after reset")
	}
}

func TestPacerHoldIsBoundedByLeaseDeadlineAndSkewedReset(t *testing.T) {
	clock := &fakeClock{now: time.Unix(1_800_000_000, 0)}
	pacer := NewPacer(150, 200)
	pacer.Now, pacer.Sleep = clock.Now, clock.Sleep
	header := http.Header{}
	header.Set("Ratelimit-Remaining", "0")
	header.Set("Ratelimit-Reset", strconv.FormatInt(clock.Now().Add(time.Hour).Unix(), 10))
	pacer.Observe(header)
	// Under a lease (a deadline sooner than the reset) requests proceed.
	lease, cancel := context.WithDeadline(context.Background(), time.Now().Add(45*time.Second))
	defer cancel()
	if err := pacer.Wait(lease); err != nil || len(clock.sleeps) != 0 {
		t.Fatal("held past the lease deadline", clock.sleeps, err)
	}
	if err := pacer.Hold(context.Background()); err != nil {
		t.Fatal(err)
	}
	if len(clock.sleeps) != 1 || clock.sleeps[0] != maxReserveHold {
		t.Fatal("skewed reset header not bounded", clock.sleeps)
	}
}

func TestCheckpointJournalReplayAndCompaction(t *testing.T) {
	dir := t.TempDir()
	statePath, journalPath := filepath.Join(dir, "b.state.json"), filepath.Join(dir, "b.journal.jsonl")
	snapshot := Snapshot{Schema: 1, ClientID: "client"}
	checkpoint, err := LoadCheckpoint(statePath, journalPath, snapshot)
	if err != nil || len(checkpoint.Entries) != 0 {
		t.Fatal(checkpoint, err)
	}
	journal, err := OpenJournal(journalPath, checkpoint)
	if err != nil {
		t.Fatal(err)
	}
	journal.Append("a", Progress{TargetID: "t", SourceDeleted: true})
	journal.Append("a", Progress{TargetID: "t", DeletedOld: true})
	journal.Append("b", Progress{Attempts: 2, LastError: "boom"})
	journal.Close()
	// A torn final line from a crash mid-append is ignored.
	file, _ := os.OpenFile(journalPath, os.O_APPEND|os.O_WRONLY, 0600)
	file.WriteString(`{"id":"c","progr`)
	file.Close()
	checkpoint, err = LoadCheckpoint(statePath, journalPath, snapshot)
	if err != nil || !checkpoint.Entries["a"].DeletedOld || checkpoint.Entries["a"].SourceDeleted || checkpoint.Entries["b"].Attempts != 2 || len(checkpoint.Entries) != 2 {
		t.Fatal(checkpoint, err)
	}
	if err = CompactCheckpoint(statePath, journalPath, checkpoint); err != nil {
		t.Fatal(err)
	}
	if _, err = os.Stat(journalPath); !os.IsNotExist(err) {
		t.Fatal("journal not folded")
	}
	reloaded, err := LoadCheckpoint(statePath, journalPath, snapshot)
	if err != nil || len(reloaded.Entries) != 2 || reloaded.Entries["b"].LastError != "boom" {
		t.Fatal(reloaded, err)
	}
	other := Snapshot{Schema: 1, ClientID: "other"}
	journal, _ = OpenJournal(journalPath, reloaded)
	journal.Close()
	os.Remove(statePath)
	if _, err = LoadCheckpoint(statePath, journalPath, other); err == nil {
		t.Fatal("journal from another snapshot accepted")
	}
}
