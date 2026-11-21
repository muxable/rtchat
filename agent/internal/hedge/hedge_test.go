package hedge

import (
	"context"
	"sync/atomic"
	"testing"
	"testing/synctest"
	"time"

	"cloud.google.com/go/firestore/apiv1/firestorepb"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func stall(ctx context.Context) error {
	<-ctx.Done()
	return status.Error(codes.DeadlineExceeded, "context deadline exceeded")
}

func set() *firestorepb.CommitRequest {
	return &firestorepb.CommitRequest{Writes: []*firestorepb.Write{{Operation: &firestorepb.Write_Update{Update: &firestorepb.Document{Name: "doc"}}}}}
}

func TestInterceptor(t *testing.T) {
	increment := set()
	increment.Writes[0].UpdateTransforms = []*firestorepb.DocumentTransform_FieldTransform{{FieldPath: "n", TransformType: &firestorepb.DocumentTransform_FieldTransform_Increment{Increment: &firestorepb.Value{}}}}
	transaction := set()
	transaction.Transaction = []byte("tx")
	for _, tc := range []struct {
		name      string
		method    string
		req       any
		attempts  []func(context.Context) error
		wantCalls int32
		wantCode  codes.Code
		within    time.Duration
	}{
		{"committed", commit, set(), []func(context.Context) error{func(context.Context) error { return nil }}, 1, codes.OK, 0},
		{"failure answers at once", commit, set(), []func(context.Context) error{func(context.Context) error { return status.Error(codes.PermissionDenied, "") }}, 1, codes.PermissionDenied, 0},
		{"stalled commit hedged", commit, set(), []func(context.Context) error{stall, func(context.Context) error { return nil }}, 2, codes.OK, After},
		// A twin may only see the stalled attempt's own write; wait for it.
		{"twin sees the stalled write", commit, set(), []func(context.Context) error{
			func(ctx context.Context) error { time.Sleep(After + time.Second); return nil },
			func(context.Context) error { return status.Error(codes.AlreadyExists, "") },
		}, 2, codes.OK, After + time.Second},
		{"every attempt stalls", commit, set(), []func(context.Context) error{stall, stall, stall}, MaxAttempts, codes.DeadlineExceeded, time.Minute},
		{"increment never hedged", commit, increment, []func(context.Context) error{stall}, 1, codes.DeadlineExceeded, time.Minute},
		{"transaction never hedged", commit, transaction, []func(context.Context) error{stall}, 1, codes.DeadlineExceeded, time.Minute},
		{"other methods never hedged", "/google.firestore.v1.Firestore/BeginTransaction", &firestorepb.BeginTransactionRequest{}, []func(context.Context) error{stall}, 1, codes.DeadlineExceeded, time.Minute},
	} {
		t.Run(tc.name, func(t *testing.T) {
			synctest.Test(t, func(t *testing.T) {
				ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
				defer cancel()
				var calls atomic.Int32
				invoker := func(ctx context.Context, _ string, _, reply any, _ *grpc.ClientConn, _ ...grpc.CallOption) error {
					n := calls.Add(1)
					err := tc.attempts[min(int(n), len(tc.attempts))-1](ctx)
					if err == nil {
						if r, ok := reply.(*firestorepb.CommitResponse); ok {
							r.CommitTime = timestamppb.New(time.Unix(int64(n), 0))
						}
					}
					return err
				}
				reply := &firestorepb.CommitResponse{}
				start := time.Now()
				err := Interceptor(ctx, tc.method, tc.req, reply, nil, invoker)
				if calls.Load() != tc.wantCalls || status.Code(err) != tc.wantCode || time.Since(start) > tc.within {
					t.Fatalf("calls=%d err=%v after %v", calls.Load(), err, time.Since(start))
				}
				if err == nil && reply.GetCommitTime() == nil {
					t.Fatal("winning reply not returned")
				}
			})
		})
	}
}
