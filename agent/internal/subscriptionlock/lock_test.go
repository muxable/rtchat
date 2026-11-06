package subscriptionlock

import (
	"context"
	"errors"
	"fmt"
	"os"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"google.golang.org/api/option"
)

func TestLeaseExclusionExpiryAndCancellation(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST")
	}
	ctx := context.Background()
	db, err := firestore.NewClient(ctx, fmt.Sprintf("lifecycle-%d", time.Now().UnixNano()), option.WithoutAuthentication())
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	var active atomic.Int32
	var runs atomic.Int32
	var wg sync.WaitGroup
	for i := 0; i < 3; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := With(ctx, db, "kick:123", func(context.Context) error {
				if active.Add(1) != 1 {
					t.Error("concurrent lifecycle work")
				}
				runs.Add(1)
				time.Sleep(10 * time.Millisecond)
				active.Add(-1)
				return nil
			}); err != nil {
				t.Error(err)
			}
		}()
	}
	wg.Wait()
	if runs.Load() != 3 {
		t.Fatal(runs.Load())
	}
	if _, err := db.Collection("subscriptionLeases").Doc("kick:dead").Set(ctx, map[string]interface{}{"owner": "dead", "until": time.Now().Add(-time.Second)}); err != nil {
		t.Fatal(err)
	}
	if err := With(ctx, db, "kick:dead", func(context.Context) error { return nil }); err != nil {
		t.Fatal("expired lease not taken", err)
	}
	if _, err := db.Collection("subscriptionLeases").Doc("kick:busy").Set(ctx, map[string]interface{}{"owner": "live", "until": time.Now().Add(time.Minute)}); err != nil {
		t.Fatal(err)
	}
	if err := TryWith(ctx, db, "kick:busy", func(context.Context) error { t.Error("entered busy lease"); return nil }); !errors.Is(err, ErrBusy) {
		t.Fatal("busy lease not reported", err)
	}
	if err := TryWith(ctx, db, "kick:free", func(context.Context) error { return nil }); err != nil {
		t.Fatal(err)
	}
	bounded, cancel := context.WithTimeout(ctx, 30*time.Millisecond)
	defer cancel()
	if err := With(bounded, db, "kick:busy", func(context.Context) error { t.Error("entered busy lease"); return nil }); err == nil {
		t.Fatal("canceled wait succeeded")
	}
}

func TestLeaseRetentionDistinguishesUncertainAndLogicalFailures(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST")
	}
	db, err := firestore.NewClient(context.Background(), fmt.Sprintf("lifecycle-failures-%d", time.Now().UnixNano()), option.WithoutAuthentication())
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	for _, mode := range []string{"canceled", "uncertain", "logical"} {
		t.Run(mode, func(t *testing.T) {
			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()
			err := With(ctx, db, mode, func(work context.Context) error {
				switch mode {
				case "canceled":
					cancel()
					return work.Err()
				case "uncertain":
					return &UncertainError{Err: fmt.Errorf("lost response")}
				default:
					return fmt.Errorf("definite rejection")
				}
			})
			if err == nil {
				t.Fatal("work failure lost")
			}
			entered := false
			retry, stop := context.WithTimeout(context.Background(), 100*time.Millisecond)
			defer stop()
			err = With(retry, db, mode, func(context.Context) error { entered = true; return nil })
			if mode == "logical" {
				if err != nil || !entered {
					t.Fatalf("safe retry blocked: %v", err)
				}
			} else if err == nil || entered {
				t.Fatalf("uncertain operation admitted overlapping work: %v", err)
			}
		})
	}
}

func TestWaitLimitDoesNotShortenLeasedWork(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST")
	}
	ctx := context.Background()
	db, err := firestore.NewClient(ctx, fmt.Sprintf("bounded-lifecycle-%d", time.Now().UnixNano()), option.WithoutAuthentication())
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	if _, err := db.Collection("subscriptionLeases").Doc("busy").Set(ctx, map[string]interface{}{"owner": "worker", "until": time.Now().Add(time.Minute)}); err != nil {
		t.Fatal(err)
	}
	started := time.Now()
	if err := WithWaitLimit(ctx, db, "busy", 100*time.Millisecond, func(context.Context) error { t.Error("entered occupied lease"); return nil }); !errors.Is(err, ErrBusy) {
		t.Fatal(err)
	}
	if elapsed := time.Since(started); elapsed > time.Second {
		t.Fatal("wait budget was ignored", elapsed)
	}
	if err := WithWaitLimit(ctx, db, "free", time.Second, func(work context.Context) error {
		deadline, ok := work.Deadline()
		if !ok || time.Until(deadline) < 40*time.Second {
			t.Error("leased work inherited acquisition deadline", deadline)
		}
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	canceled, stop := context.WithCancel(ctx)
	stop()
	if err := WithWaitLimit(canceled, db, "busy", time.Second, func(context.Context) error { t.Error("entered lease after cancellation"); return nil }); !errors.Is(err, context.Canceled) {
		t.Fatal("caller cancellation was reported as contention", err)
	}
}

// Work that doesn't conflict with a holder's job runs beside it without
// touching its lease; any other holder still excludes it.
func TestWithWaitLimitBeside(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST")
	}
	ctx := context.Background()
	db, err := firestore.NewClient(ctx, fmt.Sprintf("beside-%d", time.Now().UnixNano()), option.WithoutAuthentication())
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	// A labeled holder records its job in the lease.
	held, release := make(chan struct{}), make(chan struct{})
	done := make(chan error, 1)
	go func() {
		done <- With(Job(ctx, "reconcile"), db, "twitch:1", func(context.Context) error {
			close(held)
			<-release
			return nil
		})
	}()
	<-held
	lease, err := db.Collection("subscriptionLeases").Doc("twitch:1").Get(ctx)
	if err != nil || lease.Data()["job"] != "reconcile" {
		t.Fatalf("lease not labeled: %v %v", lease.Data(), err)
	}
	owner := lease.Data()["owner"]

	ran := false
	started := time.Now()
	if err := WithWaitLimitBeside(ctx, db, "twitch:1", time.Second, []string{"reconcile"}, func(ctx context.Context) error {
		if _, ok := ctx.Deadline(); !ok {
			t.Error("work beside a holder has no deadline")
		}
		ran = true
		return nil
	}); err != nil || !ran || time.Since(started) > 500*time.Millisecond {
		t.Fatalf("beside: ran=%v err=%v after %v", ran, err, time.Since(started))
	}
	if err := WithWaitLimitBeside(ctx, db, "twitch:1", 300*time.Millisecond, []string{"remove"}, func(context.Context) error {
		t.Error("ran beside a job it conflicts with")
		return nil
	}); !errors.Is(err, ErrBusy) {
		t.Fatalf("conflicting job: %v", err)
	}
	lease, err = db.Collection("subscriptionLeases").Doc("twitch:1").Get(ctx)
	if err != nil || lease.Data()["owner"] != owner {
		t.Fatalf("work beside the holder changed its lease: %v %v", lease.Data(), err)
	}
	close(release)
	if err := <-done; err != nil {
		t.Fatal(err)
	}

	// An unlabeled holder, such as a removal or an older replica, excludes all.
	held, release = make(chan struct{}), make(chan struct{})
	go func() {
		done <- With(ctx, db, "twitch:2", func(context.Context) error {
			close(held)
			<-release
			return nil
		})
	}()
	<-held
	if err := WithWaitLimitBeside(ctx, db, "twitch:2", 300*time.Millisecond, []string{"reconcile"}, func(context.Context) error {
		t.Error("ran beside an unlabeled holder")
		return nil
	}); !errors.Is(err, ErrBusy) {
		t.Fatalf("unlabeled holder: %v", err)
	}
	close(release)
	if err := <-done; err != nil {
		t.Fatal(err)
	}
	// Once free, the lease is taken and released as usual.
	if err := WithWaitLimitBeside(ctx, db, "twitch:2", time.Second, []string{"reconcile"}, func(context.Context) error { return nil }); err != nil {
		t.Fatal(err)
	}
}
