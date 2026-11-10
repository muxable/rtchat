package jobs

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

type memoryLeases struct {
	mu     sync.Mutex
	leases map[string]Lease
}

func (s *memoryLeases) Acquire(_ context.Context, name, slot string, now time.Time, ttl time.Duration) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !canAcquire(s.leases[name], slot, now) {
		return false
	}
	s.leases[name] = Lease{ExpiresAt: now.Add(ttl), CompletedSlot: s.leases[name].CompletedSlot}
	return true
}
func (s *memoryLeases) Finish(_ context.Context, name, slot string, success bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	lease := Lease{CompletedSlot: s.leases[name].CompletedSlot}
	if success {
		lease.CompletedSlot = slot
	}
	s.leases[name] = lease
}
func TestReplicasAndCompletion(t *testing.T) {
	store := &memoryLeases{leases: map[string]Lease{}}
	runner := Runner{Leases: store}
	now := time.Now()
	var calls atomic.Int32
	entered := make(chan struct{})
	release := make(chan struct{})
	job := Job{Name: "refresh", Timeout: time.Minute, Run: func(context.Context) error { calls.Add(1); close(entered); <-release; return nil }}
	done := make(chan struct{})
	go func() { runner.Once(context.Background(), job, now); close(done) }()
	<-entered
	var replicas sync.WaitGroup
	for i := 0; i < 3; i++ {
		replicas.Add(1)
		go func() { defer replicas.Done(); runner.Once(context.Background(), job, now) }()
	}
	replicas.Wait()
	close(release)
	<-done
	runner.Once(context.Background(), job, now)
	if calls.Load() != 1 {
		t.Fatalf("runs = %d", calls.Load())
	}
}
func TestExpiryTakeover(t *testing.T) {
	store := &memoryLeases{leases: map[string]Lease{}}
	ctx := context.Background()
	now := time.Now()
	if !store.Acquire(ctx, "job", "slot", now, time.Minute) {
		t.Fatal("free lease not taken")
	}
	if store.Acquire(ctx, "job", "slot", now.Add(59*time.Second), time.Minute) {
		t.Fatal("took live lease")
	}
	if !store.Acquire(ctx, "job", "slot", now.Add(time.Minute), time.Minute) {
		t.Fatal("expired lease not taken")
	}
}
func TestFailureRetriedAndCancellation(t *testing.T) {
	store := &memoryLeases{leases: map[string]Lease{}}
	r := Runner{Leases: store}
	now := time.Now()
	calls := 0
	job := Job{Name: "fail", Timeout: time.Second, Run: func(context.Context) error { calls++; return errors.New("provider unavailable") }}
	r.Once(context.Background(), job, now)
	r.Once(context.Background(), job, now)
	if calls != 2 {
		t.Fatal(calls)
	}
	job.Timeout = 5 * time.Millisecond
	job.Run = func(ctx context.Context) error { <-ctx.Done(); return ctx.Err() }
	r.Once(context.Background(), job, now)
	if store.leases["fail"].CompletedSlot != "" {
		t.Fatal("timeout marked successful")
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	job.Run = func(context.Context) error { t.Fatal("ran canceled job"); return nil }
	r.Once(ctx, job, now)
}
func TestScheduleLosAngelesDST(t *testing.T) {
	cases := map[string]string{
		"2026-03-08T10:59:00Z": "2026-03-07", // 03:59 PDT
		"2026-03-08T11:00:00Z": "2026-03-08", // 04:00 PDT
		"2026-11-01T11:59:00Z": "2026-10-31", // 03:59 PST
		"2026-11-01T12:00:00Z": "2026-11-01", // 04:00 PST
	}
	for input, want := range cases {
		at, _ := time.Parse(time.RFC3339, input)
		if got := Slot(at, true); got != want {
			t.Errorf("%s => %s want %s", input, got, want)
		}
	}
	at, _ := time.Parse(time.RFC3339, "2026-10-16T12:07:30Z")
	if got := Slot(at, false); got != "2026-10-16T12:04:00Z" {
		t.Fatal(got)
	}
}
func TestIdleAssignmentSafety(t *testing.T) {
	cutoff := time.Now()
	old := map[string]interface{}{"subscribedAt": cutoff.Add(-time.Second)}
	if idleAssignment("twitch:muxfd", old, cutoff) {
		t.Fatal("protected assignment deleted")
	}
	if !idleAssignment("youtube:abc", old, cutoff) {
		t.Fatal("old assignment retained")
	}
	for _, data := range []map[string]interface{}{{}, {"subscribedAt": "bad"}, {"subscribedAt": cutoff}, {"subscribedAt": cutoff.Add(time.Second)}} {
		if idleAssignment("twitch:user", data, cutoff) {
			t.Fatalf("deleted unsafe assignment %v", data)
		}
	}
}
