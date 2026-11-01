package chatmessage

import (
	"context"
	"errors"
	"sync/atomic"
	"testing"
	"testing/synctest"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func stall(ctx context.Context) error {
	<-ctx.Done()
	return status.Error(codes.DeadlineExceeded, "context deadline exceeded")
}

func TestCreate(t *testing.T) {
	for _, tc := range []struct {
		name          string
		attempts      []func(context.Context) error
		wantCalls     int32
		wantDuplicate bool
		wantCode      codes.Code
		within        time.Duration
	}{
		{"written", []func(context.Context) error{func(context.Context) error { return nil }}, 1, false, codes.OK, 0},
		{"already written", []func(context.Context) error{func(context.Context) error { return status.Error(codes.AlreadyExists, "") }}, 1, true, codes.OK, 0},
		{"permanent failure", []func(context.Context) error{func(context.Context) error { return status.Error(codes.PermissionDenied, "") }}, 1, false, codes.PermissionDenied, 0},
		{"transient failure retried", []func(context.Context) error{
			func(context.Context) error { return status.Error(codes.Unavailable, "") },
			func(context.Context) error { return nil },
		}, 2, false, codes.OK, time.Second},
		{"stalled attempt hedged", []func(context.Context) error{stall, func(context.Context) error { return nil }}, 2, false, codes.OK, HedgeAfter},
		// The stalled attempt may land first; the hedge then sees its own write.
		{"hedge sees stalled write", []func(context.Context) error{
			func(ctx context.Context) error {
				select {
				case <-time.After(HedgeAfter + time.Second):
					return nil
				case <-ctx.Done():
					return ctx.Err()
				}
			},
			func(ctx context.Context) error {
				time.Sleep(time.Second)
				return status.Error(codes.AlreadyExists, "")
			},
		}, 2, false, codes.OK, HedgeAfter + time.Second},
		{"transient failures exhausted", []func(context.Context) error{
			func(context.Context) error { return status.Error(codes.Unavailable, "") },
			func(context.Context) error { return status.Error(codes.Aborted, "") },
			func(context.Context) error { return status.Error(codes.Unavailable, "") },
		}, MaxAttempts, false, codes.Unavailable, time.Second},
		{"every attempt stalls", []func(context.Context) error{stall, stall, stall}, MaxAttempts, false, codes.DeadlineExceeded, 15 * time.Second},
	} {
		t.Run(tc.name, func(t *testing.T) {
			synctest.Test(t, func(t *testing.T) {
				ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
				defer cancel()
				var calls atomic.Int32
				start := time.Now()
				duplicate, err := Create(ctx, func(ctx context.Context) error {
					n := calls.Add(1)
					return tc.attempts[min(int(n), len(tc.attempts))-1](ctx)
				})
				code := status.Code(err)
				if errors.Is(err, context.DeadlineExceeded) {
					code = codes.DeadlineExceeded
				}
				if calls.Load() != tc.wantCalls || duplicate != tc.wantDuplicate || code != tc.wantCode || time.Since(start) > tc.within {
					t.Fatalf("calls=%d duplicate=%v err=%v after %v", calls.Load(), duplicate, err, time.Since(start))
				}
			})
		})
	}
}
