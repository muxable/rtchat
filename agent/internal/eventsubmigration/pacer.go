package eventsubmigration

import (
	"context"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/muxable/rtchat/agent/internal/clients"
)

// maxReserveHold bounds a sleep derived from a Ratelimit-Reset header so a
// malformed or skewed header cannot stall the migration indefinitely.
const maxReserveHold = 2 * time.Minute

// Pacer spaces every Helix request the migration makes and backs off when the
// shared app-token bucket runs low. The app token's 800 points/min budget is
// shared with production, so the migration takes a fixed slice (Interval) and
// yields entirely whenever the bucket drops below Reserve until it refills.
type Pacer struct {
	Interval time.Duration
	Reserve  int
	Now      func() time.Time
	Sleep    func(context.Context, time.Duration) error

	mu        sync.Mutex
	next      time.Time
	known     bool
	remaining int
	reset     time.Time
}

// NewPacer paces at perMinute requests per minute, holding whenever fewer than
// reserve points remain in the shared bucket.
func NewPacer(perMinute, reserve int) *Pacer {
	p := &Pacer{Reserve: reserve}
	if perMinute > 0 {
		p.Interval = time.Minute / time.Duration(perMinute)
	}
	return p
}

func (p *Pacer) now() time.Time {
	if p.Now != nil {
		return p.Now()
	}
	return time.Now()
}
func (p *Pacer) sleep(ctx context.Context, d time.Duration) error {
	if p.Sleep != nil {
		return p.Sleep(ctx, d)
	}
	return clients.Wait(ctx, d)
}

// holdLocked returns how long to wait for the shared bucket to refill.
func (p *Pacer) holdLocked() time.Duration {
	if !p.known || p.remaining >= p.Reserve {
		return 0
	}
	d := p.reset.Sub(p.now()) + time.Second
	if d <= 0 {
		return 0
	}
	if d > maxReserveHold {
		d = maxReserveHold
	}
	return d
}

func (p *Pacer) holdIfLowLocked(ctx context.Context) error {
	if d := p.holdLocked(); d > 0 {
		if deadline, ok := ctx.Deadline(); ok && time.Until(deadline) < d {
			// Work under a lease cannot outlast it: finish the few requests left
			// from the reserve instead. Run holds between leases.
			return nil
		}
		if err := p.sleep(ctx, d); err != nil {
			return err
		}
	}
	if p.known && p.remaining < p.Reserve {
		// The bucket refilled at reset; the next response reports the new value.
		p.known = false
	}
	return nil
}

// Hold waits out a low shared bucket without consuming a request slot. Run
// calls it before taking a per-broadcaster lease so the lease is not held
// while sleeping.
func (p *Pacer) Hold(ctx context.Context) error {
	if p == nil {
		return nil
	}
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.holdIfLowLocked(ctx)
}

// Throttled reports whether the next request would wait for a bucket reset.
func (p *Pacer) Throttled() bool {
	if p == nil {
		return false
	}
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.holdLocked() > 0
}

// Wait blocks until the next request may be sent.
func (p *Pacer) Wait(ctx context.Context) error {
	if p == nil {
		return nil
	}
	p.mu.Lock()
	defer p.mu.Unlock()
	if err := p.holdIfLowLocked(ctx); err != nil {
		return err
	}
	now := p.now()
	if p.next.After(now) {
		if err := p.sleep(ctx, p.next.Sub(now)); err != nil {
			return err
		}
		now = p.now()
	}
	p.next = now.Add(p.Interval)
	return nil
}

// Observe records Helix's Ratelimit-Remaining and Ratelimit-Reset headers.
func (p *Pacer) Observe(header http.Header) {
	if p == nil {
		return
	}
	remaining, err := strconv.Atoi(header.Get("Ratelimit-Remaining"))
	if err != nil {
		return
	}
	reset, err := strconv.ParseInt(header.Get("Ratelimit-Reset"), 10, 64)
	if err != nil {
		return
	}
	p.mu.Lock()
	defer p.mu.Unlock()
	p.known, p.remaining, p.reset = true, remaining, time.Unix(reset, 0)
}
