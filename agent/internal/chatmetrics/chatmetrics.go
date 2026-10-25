// Package chatmetrics counts chat events and their Firestore write outcomes in
// process and periodically logs the deltas, which log-based metrics sum. This
// replaces a log line per chat message.
package chatmetrics

import (
	"context"
	"sort"
	"sync"
	"time"

	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type Outcome string

const (
	Created Outcome = "created"
	// Duplicate is expected: every agent instance writes the same document ID.
	Duplicate Outcome = "duplicate"
	Failed    Outcome = "failed"
	// Skipped events were received but produce no document.
	Skipped Outcome = "skipped"
)

// OutcomeOf classifies the error returned by a Firestore Create.
func OutcomeOf(err error) Outcome {
	switch {
	case err == nil:
		return Created
	case status.Code(err) == codes.AlreadyExists:
		return Duplicate
	default:
		return Failed
	}
}

type key struct {
	provider, kind string
	outcome        Outcome
}

type Counters struct {
	mu     sync.Mutex
	counts map[key]int64
}

// Default is the process-wide counter set flushed by Run.
var Default = &Counters{}

func Record(provider, kind string, outcome Outcome) { Default.Add(provider, kind, outcome) }

func (c *Counters) Add(provider, kind string, outcome Outcome) {
	c.mu.Lock()
	if c.counts == nil {
		c.counts = make(map[key]int64)
	}
	c.counts[key{provider, kind, outcome}]++
	c.mu.Unlock()
}

// Flush logs one "chat events" entry per provider, kind and outcome counted
// since the previous flush, then resets the counts.
func (c *Counters) Flush(logger *zap.Logger) {
	c.mu.Lock()
	counts := c.counts
	c.counts = nil
	c.mu.Unlock()
	keys := make([]key, 0, len(counts))
	for k := range counts {
		keys = append(keys, k)
	}
	sort.Slice(keys, func(i, j int) bool {
		a, b := keys[i], keys[j]
		if a.provider != b.provider {
			return a.provider < b.provider
		}
		if a.kind != b.kind {
			return a.kind < b.kind
		}
		return a.outcome < b.outcome
	})
	for _, k := range keys {
		logger.Info("chat events", zap.String("provider", k.provider), zap.String("kind", k.kind), zap.String("outcome", string(k.outcome)), zap.Int64("count", counts[k]))
	}
}

// Run flushes Default to the global logger every interval and once more when
// ctx ends.
func Run(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			Default.Flush(zap.L())
			return
		case <-ticker.C:
			Default.Flush(zap.L())
		}
	}
}
