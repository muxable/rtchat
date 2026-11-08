package chatmessage

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"
	"testing"
	"testing/synctest"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type results struct {
	mu   sync.Mutex
	errs map[int]error
}

func (r *results) done(i int) func(bool, error) {
	return func(_ bool, err error) {
		r.mu.Lock()
		defer r.mu.Unlock()
		if r.errs == nil {
			r.errs = map[int]error{}
		}
		if _, ok := r.errs[i]; ok {
			panic("done called twice")
		}
		r.errs[i] = err
	}
}

func (r *results) get() map[int]error {
	r.mu.Lock()
	defer r.mu.Unlock()
	errs := make(map[int]error, len(r.errs))
	for i, err := range r.errs {
		errs[i] = err
	}
	return errs
}

// The production outage: every Firestore call stalled for about a minute,
// then recovered. Writes made during it must land afterwards, not be dropped.
func TestBufferHoldsWritesThroughOutage(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()
		b := NewBuffer()
		go b.Run(ctx)
		recovered := time.Now().Add(time.Minute)
		var written sync.Map
		var r results
		for i := range 100 {
			go b.Create(ctx, func(ctx context.Context) error {
				if time.Now().Before(recovered) {
					<-ctx.Done()
					return ctx.Err()
				}
				written.Store(i, true)
				return nil
			}, r.done(i))
			time.Sleep(time.Second)
		}
		time.Sleep(time.Minute)
		synctest.Wait()
		got := r.get()
		if len(got) != 100 {
			t.Fatalf("%d of 100 writes finished", len(got))
		}
		for i, err := range got {
			if _, ok := written.Load(i); err != nil || !ok {
				t.Fatalf("write %d: err=%v written=%v", i, err, ok)
			}
		}
	})
}

// Once writes are queued, new writes join the queue instead of stalling on
// Firestore themselves.
func TestBufferQueuesBehindOutage(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()
		b := NewBuffer()
		var down atomic.Bool
		down.Store(true)
		var calls atomic.Int32
		create := func(context.Context) error {
			calls.Add(1)
			if down.Load() {
				return status.Error(codes.Unavailable, "")
			}
			return nil
		}
		var r results
		b.Create(ctx, create, r.done(0))
		before := calls.Load()
		start := time.Now()
		b.Create(ctx, create, r.done(1))
		if calls.Load() != before || time.Since(start) != 0 {
			t.Fatalf("queued write tried Firestore directly")
		}
		down.Store(false)
		go b.Run(ctx)
		synctest.Wait()
		if got := r.get(); got[0] != nil || got[1] != nil || len(got) != 2 {
			t.Fatalf("results = %v", got)
		}
	})
}

func TestBufferDropsWrites(t *testing.T) {
	unavailable := func(context.Context) error { return status.Error(codes.Unavailable, "") }
	synctest.Test(t, func(t *testing.T) {
		ctx, cancel := context.WithCancel(context.Background())
		b := NewBuffer()
		b.Capacity = 2
		go b.Run(ctx)
		var r results
		for i := range 3 {
			b.Create(ctx, unavailable, r.done(i))
		}
		if err := r.get()[2]; !errors.Is(err, ErrBufferFull) {
			t.Fatalf("over capacity: err = %v", err)
		}
		time.Sleep(b.MaxAge + time.Minute)
		synctest.Wait()
		if got := r.get(); !errors.Is(got[0], ErrExpired) || !errors.Is(got[1], ErrExpired) {
			t.Fatalf("expired: %v", got)
		}

		b.Create(ctx, unavailable, r.done(3))
		cancel()
		synctest.Wait()
		if err := r.get()[3]; !errors.Is(err, context.Canceled) {
			t.Fatalf("shutdown: err = %v", err)
		}
	})
}

func TestBufferPassesThroughPermanentErrors(t *testing.T) {
	b := NewBuffer()
	var r results
	b.Create(context.Background(), func(context.Context) error { return status.Error(codes.PermissionDenied, "") }, r.done(0))
	if got := r.get(); status.Code(got[0]) != codes.PermissionDenied || len(b.queue) != 0 {
		t.Fatalf("results = %v, queued = %d", got, len(b.queue))
	}
}
