package chatmessage

import (
	"context"
	"errors"
	"sync"
	"time"

	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// AttemptTimeout bounds one Create, including its hedged attempts.
const AttemptTimeout = 15 * time.Second

var (
	// ErrExpired means a buffered write was still failing after MaxAge.
	ErrExpired = errors.New("message write buffered too long")
	// ErrBufferFull means the buffer already held Capacity writes.
	ErrBufferFull = errors.New("message write buffer full")
)

// Transient reports whether err may succeed if the write is tried again later.
func Transient(err error) bool {
	if errors.Is(err, context.DeadlineExceeded) {
		return true
	}
	switch status.Code(err) {
	case codes.Unavailable, codes.DeadlineExceeded, codes.Aborted, codes.ResourceExhausted:
		return true
	}
	return false
}

// Buffer holds message writes through a Firestore outage. A write that fails
// transiently is queued and retried in order, with backoff, until it lands or
// is MaxAge old. While writes are queued, new writes join the queue rather
// than stall on their own, so chat is delayed during an outage instead of lost.
type Buffer struct {
	MaxAge   time.Duration
	Capacity int
	// Parallel is how many queued writes are retried at once.
	Parallel int

	mu    sync.Mutex
	queue []*pending
	since time.Time
	wake  chan struct{}
}

type pending struct {
	create func(context.Context) error
	queued time.Time
	done   func(duplicate bool, err error)
}

func NewBuffer() *Buffer {
	return &Buffer{MaxAge: 10 * time.Minute, Capacity: 20000, Parallel: 32, wake: make(chan struct{}, 1)}
}

// Create writes the message, calling done once it lands, fails permanently,
// or is dropped from the buffer. It blocks for at most AttemptTimeout.
func (b *Buffer) Create(ctx context.Context, create func(context.Context) error, done func(duplicate bool, err error)) {
	b.mu.Lock()
	queued := len(b.queue) > 0
	b.mu.Unlock()
	if !queued {
		attempt, cancel := context.WithTimeout(ctx, AttemptTimeout)
		duplicate, err := Create(attempt, create)
		cancel()
		if err == nil || !Transient(err) || ctx.Err() != nil {
			done(duplicate, err)
			return
		}
	}
	b.push(&pending{create: create, queued: time.Now(), done: done})
}

func (b *Buffer) push(p *pending) {
	b.mu.Lock()
	if len(b.queue) >= b.Capacity {
		b.mu.Unlock()
		p.done(false, ErrBufferFull)
		return
	}
	if len(b.queue) == 0 {
		b.since = time.Now()
		zap.L().Info("buffering message writes")
	}
	b.queue = append(b.queue, p)
	b.mu.Unlock()
	select {
	case b.wake <- struct{}{}:
	default:
	}
}

// Run retries queued writes until ctx ends, then drops whatever is left.
func (b *Buffer) Run(ctx context.Context) {
	backoff := time.Second
	for {
		if b.drain(ctx) {
			backoff = time.Second
			select {
			case <-b.wake:
				continue
			case <-ctx.Done():
				b.drop(ctx.Err())
				return
			}
		}
		select {
		case <-time.After(backoff):
			backoff = min(2*backoff, 30*time.Second)
		case <-ctx.Done():
			b.drop(ctx.Err())
			return
		}
	}
}

// drain retries queued writes in batches while they keep landing. It reports
// whether the queue emptied; false means Firestore is still failing.
func (b *Buffer) drain(ctx context.Context) bool {
	for {
		b.mu.Lock()
		now := time.Now()
		expired := 0
		for expired < len(b.queue) && now.Sub(b.queue[expired].queued) > b.MaxAge {
			expired++
		}
		dropped := b.queue[:expired:expired]
		batch := b.queue[expired:min(len(b.queue), expired+b.Parallel)]
		b.queue = b.queue[expired+len(batch):]
		b.mu.Unlock()
		if len(dropped) > 0 {
			zap.L().Error("dropped buffered message writes", zap.Error(ErrExpired), zap.Int("count", len(dropped)))
			for _, p := range dropped {
				p.done(false, ErrExpired)
			}
		}
		if len(batch) == 0 {
			b.mu.Lock()
			empty := len(b.queue) == 0
			if empty && !b.since.IsZero() {
				zap.L().Info("buffered message writes flushed", zap.Duration("after", time.Since(b.since)))
				b.since = time.Time{}
			}
			b.mu.Unlock()
			if empty {
				return true
			}
			continue
		}

		retry := make([]*pending, len(batch))
		var wg sync.WaitGroup
		for i, p := range batch {
			wg.Add(1)
			go func() {
				defer wg.Done()
				attempt, cancel := context.WithTimeout(ctx, AttemptTimeout)
				duplicate, err := Create(attempt, p.create)
				cancel()
				if err != nil && Transient(err) && ctx.Err() == nil {
					retry[i] = p
					return
				}
				p.done(duplicate, err)
			}()
		}
		wg.Wait()
		var failed []*pending
		for _, p := range retry {
			if p != nil {
				failed = append(failed, p)
			}
		}
		if len(failed) > 0 {
			b.mu.Lock()
			b.queue = append(failed, b.queue...)
			b.mu.Unlock()
			return false
		}
	}
}

func (b *Buffer) drop(err error) {
	b.mu.Lock()
	queue := b.queue
	b.queue = nil
	b.mu.Unlock()
	if len(queue) > 0 {
		zap.L().Error("dropped buffered message writes", zap.Error(err), zap.Int("count", len(queue)))
	}
	for _, p := range queue {
		p.done(false, err)
	}
}
