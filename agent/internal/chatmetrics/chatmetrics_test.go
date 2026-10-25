package chatmetrics

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestOutcomeOf(t *testing.T) {
	for err, want := range map[error]Outcome{
		nil:                                      Created,
		status.Error(codes.AlreadyExists, "dup"): Duplicate,
		status.Error(codes.Unavailable, "down"):  Failed,
		errors.New("other"):                      Failed,
	} {
		if got := OutcomeOf(err); got != want {
			t.Errorf("OutcomeOf(%v) = %s, want %s", err, got, want)
		}
	}
}

func TestFlushLogsDeltas(t *testing.T) {
	core, logs := observer.New(zap.InfoLevel)
	logger := zap.New(core)
	c := &Counters{}
	var wg sync.WaitGroup
	for i := 0; i < 50; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			c.Add("twitch", "message", Created)
			c.Add("twitch", "message", Duplicate)
			c.Add("twitch", "message", Duplicate)
		}()
	}
	wg.Wait()
	c.Add("youtube", "message", Failed)
	c.Flush(logger)

	type entry struct {
		provider, kind, outcome string
		count                   int64
	}
	var got []entry
	for _, e := range logs.TakeAll() {
		if e.Message != "chat events" {
			t.Fatalf("message = %q", e.Message)
		}
		f := e.ContextMap()
		got = append(got, entry{f["provider"].(string), f["kind"].(string), f["outcome"].(string), f["count"].(int64)})
	}
	want := []entry{
		{"twitch", "message", "created", 50},
		{"twitch", "message", "duplicate", 100},
		{"youtube", "message", "failed", 1},
	}
	if len(got) != len(want) {
		t.Fatalf("got %v, want %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("got %v, want %v", got, want)
		}
	}

	// Counts are deltas: a flush with nothing new logs nothing.
	c.Flush(logger)
	if n := logs.Len(); n != 0 {
		t.Fatalf("empty flush logged %d entries", n)
	}
	c.Add("kick", "message", Created)
	c.Flush(logger)
	if e := logs.TakeAll(); len(e) != 1 || e[0].ContextMap()["count"] != int64(1) {
		t.Fatalf("second flush = %v", e)
	}
}

func TestRunFlushesOnTick(t *testing.T) {
	core, logs := observer.New(zap.InfoLevel)
	defer zap.ReplaceGlobals(zap.New(core))()
	defer func(saved *Counters) { Default = saved }(Default)
	Default = &Counters{}
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan struct{})
	go func() { defer close(done); Run(ctx, 10*time.Millisecond) }()
	Record("twitch", "message", Created)
	deadline := time.Now().Add(5 * time.Second)
	for logs.Len() == 0 && time.Now().Before(deadline) {
		time.Sleep(5 * time.Millisecond)
	}
	if logs.Len() != 1 {
		t.Fatalf("tick logged %d entries", logs.Len())
	}
	cancel()
	<-done
	// Run does not flush on exit; main flushes after shutdown instead.
	Record("twitch", "clearchat", Created)
	Default.Flush(zap.L())
	if logs.Len() != 2 {
		t.Fatalf("final flush logged %d entries in total, want 2", logs.Len())
	}
}
