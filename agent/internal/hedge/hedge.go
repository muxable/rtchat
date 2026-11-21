// Package hedge keeps one stalled Firestore commit from holding up a write:
// a commit that can be repeated safely gets a twin after After, and the first
// to succeed answers. It covers every write made through the client.
package hedge

import (
	"context"
	"time"

	"cloud.google.com/go/firestore/apiv1/firestorepb"
	"google.golang.org/api/option"
	"google.golang.org/grpc"
	"google.golang.org/protobuf/proto"
)

const (
	After       = 2 * time.Second
	MaxAttempts = 3
	commit      = "/google.firestore.v1.Firestore/Commit"
)

// Firestore is the client option that hedges the client's commits.
func Firestore() option.ClientOption {
	return option.WithGRPCDialOption(grpc.WithChainUnaryInterceptor(Interceptor))
}

// repeatable reports whether committing req twice leaves the same state: it
// is outside a transaction and doesn't increment. A repeated precondition or
// create fails rather than applying twice, which Interceptor tolerates.
func repeatable(req *firestorepb.CommitRequest) bool {
	if len(req.GetTransaction()) > 0 {
		return false
	}
	for _, write := range req.GetWrites() {
		for _, transform := range write.GetUpdateTransforms() {
			if transform.GetIncrement() != nil {
				return false
			}
		}
	}
	return true
}

// Interceptor hedges repeatable commits. Any success wins. A failure answers
// only once no attempt is left that might succeed, since a twin's
// AlreadyExists or failed precondition may just see an earlier attempt's write.
func Interceptor(ctx context.Context, method string, req, reply any, cc *grpc.ClientConn, invoker grpc.UnaryInvoker, opts ...grpc.CallOption) error {
	request, ok := req.(*firestorepb.CommitRequest)
	if method != commit || !ok || !repeatable(request) {
		return invoker(ctx, method, req, reply, cc, opts...)
	}
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	type result struct {
		reply proto.Message
		err   error
	}
	results := make(chan result, MaxAttempts)
	started, pending := 0, 0
	start := func() {
		started++
		pending++
		attempt := proto.Clone(reply.(proto.Message))
		go func() { results <- result{attempt, invoker(ctx, method, req, attempt, cc, opts...)} }()
	}
	start()
	hedge := time.NewTicker(After)
	defer hedge.Stop()
	var err error
	for {
		select {
		case r := <-results:
			pending--
			if r.err == nil {
				proto.Merge(reply.(proto.Message), r.reply)
				return nil
			}
			if err == nil {
				err = r.err
			}
			if pending == 0 {
				return err
			}
		case <-hedge.C:
			if started < MaxAttempts {
				start()
			}
		}
	}
}
