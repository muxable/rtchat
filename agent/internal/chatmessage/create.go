package chatmessage

import (
	"context"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// HedgeAfter is how long an attempt may stay pending before another starts
// alongside it. MaxAttempts bounds the attempts one write may start.
const (
	HedgeAfter  = 2 * time.Second
	MaxAttempts = 3
)

// Create runs create, a Firestore Create of one message document, until it
// lands or ctx ends. Creates are idempotent: a document that already exists
// counts as written. So rather than wait out an RPC that has stalled, Create
// starts another attempt beside it after HedgeAfter, or shortly after a
// transient failure, and the first to land wins.
//
// duplicate reports that the document existed before this write. It is false
// whenever another attempt was in flight, since that attempt may have created it.
func Create(ctx context.Context, create func(context.Context) error) (duplicate bool, err error) {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	results := make(chan error, MaxAttempts)
	started, pending := 0, 0
	start := func() {
		started++
		pending++
		go func() { results <- create(ctx) }()
	}
	start()
	hedge := time.NewTimer(HedgeAfter)
	defer hedge.Stop()
	var retry <-chan time.Time
	for {
		select {
		case attempt := <-results:
			pending--
			switch status.Code(attempt) {
			case codes.OK:
				return false, nil
			case codes.AlreadyExists:
				return started == 1, nil
			case codes.Unavailable, codes.DeadlineExceeded, codes.Aborted, codes.ResourceExhausted:
				err = attempt
			default:
				return false, attempt
			}
			if ctx.Err() == nil && started < MaxAttempts {
				retry = time.After(time.Duration(started) * 100 * time.Millisecond)
			} else if pending == 0 {
				return false, err
			}
		case <-hedge.C:
			if started < MaxAttempts {
				start()
				hedge.Reset(HedgeAfter)
			}
		case <-retry:
			retry = nil
			if started < MaxAttempts {
				start()
				hedge.Reset(HedgeAfter)
			}
		case <-ctx.Done():
			if err == nil {
				err = ctx.Err()
			}
			return false, err
		}
	}
}
