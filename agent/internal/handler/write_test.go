package handler

import (
	"context"
	"fmt"
	"sync"
	"sync/atomic"
	"testing"
	"testing/synctest"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestCreateMessageRetriesTransientError(t *testing.T) {
	calls := 0
	_, err := createMessage(context.Background(), func(context.Context) error {
		calls++
		if calls == 1 {
			return status.Error(codes.Unavailable, "temporary outage")
		}
		return nil
	})
	if err != nil || calls != 2 {
		t.Fatalf("calls=%d err=%v; chat dropped", calls, err)
	}
}

func TestCreateMessageAlreadyExistsAndPermanentError(t *testing.T) {
	for _, code := range []codes.Code{codes.AlreadyExists, codes.PermissionDenied} {
		calls := 0
		_, err := createMessage(context.Background(), func(context.Context) error { calls++; return status.Error(code, "fake") })
		if calls != 1 || (err == nil) != (code == codes.AlreadyExists) {
			t.Fatalf("calls=%d err=%v", calls, err)
		}
	}
}

// A stalled Firestore RPC must not consume the whole write budget: the
// production failure was one hung Create timing out with no retry left.
func TestCreateMessageSurvivesStalledAttempt(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		var calls atomic.Int32
		start := time.Now()
		_, err := createMessage(context.Background(), func(ctx context.Context) error {
			if calls.Add(1) == 1 {
				<-ctx.Done()
				return status.Error(codes.DeadlineExceeded, "context deadline exceeded")
			}
			return nil
		})
		if err != nil || calls.Load() != 2 || time.Since(start) > 5*time.Second {
			t.Fatalf("calls=%d err=%v after %v; chat dropped", calls.Load(), err, time.Since(start))
		}
	})
}

// The 2026-11-07 outage: every Firestore call stalled for about a minute.
// Messages received during it must be held and written once it recovers.
func TestWriteDocumentHoldsMessagesThroughOutage(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()
		recovered := time.Now().Add(time.Minute)
		var mu sync.Mutex
		written := map[string]bool{}
		h := &TwitchAgent{Context: ctx, createDoc: func(ctx context.Context, doc *chatDocument) error {
			if time.Now().Before(recovered) {
				<-ctx.Done()
				return ctx.Err()
			}
			mu.Lock()
			defer mu.Unlock()
			written[doc.messageID] = true
			return nil
		}}
		for i := range 100 {
			go h.writeDocument("message", &chatDocument{"twitch:1", fmt.Sprint(i), nil})
			time.Sleep(time.Second)
		}
		time.Sleep(time.Minute)
		synctest.Wait()
		if len(written) != 100 {
			t.Fatalf("%d of 100 messages written", len(written))
		}
	})
}
