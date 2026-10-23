package subscriptions

import (
	"context"
	"errors"
	"net/http"
	"net/url"
	"strconv"
	"sync"
	"time"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
	"go.uber.org/zap"
)

const (
	twitchQueueCapacity = 10000
	// twitchBudgetReserve is the share of the client's 800 requests per minute
	// the queue leaves for user-facing calls on every replica.
	twitchBudgetReserve     = 100
	twitchCostCheckInterval = 5 * time.Minute
	twitchBusyDelay         = 5 * time.Second
	twitchMaxAttempts       = 6
	twitchIdle              = time.Hour
)

var errTwitchBudget = errors.New("Twitch rate-limit reserve reached")

type twitchItem struct {
	channel  string
	enqueued time.Time
	ready    time.Time
	attempts int
	costHeld bool
	running  bool
}

// TwitchQueue reconciles broadcasters' EventSub subscriptions on one worker
// per replica, paced by Twitch's rate and cost limits. It is not durable:
// subscribe runs on every channel open, so work lost to a restart is redone.
type TwitchQueue struct {
	service  *Service
	now      func() time.Time
	lock     func(context.Context, string, func(context.Context) error) error
	capacity int
	wake     chan struct{}

	// remaining and reset are the app token's Helix bucket as last reported
	// to the worker. Every replica and job using the client ID shares it.
	remaining int
	reset     time.Time

	mu        sync.Mutex
	pending   map[string]*twitchItem
	costCheck time.Time
}

func NewTwitchQueue(s *Service) *TwitchQueue {
	return &TwitchQueue{
		service: s,
		now:     time.Now,
		lock: func(ctx context.Context, key string, work func(context.Context) error) error {
			return subscriptionlock.TryWith(ctx, s.DB, key, work)
		},
		capacity: twitchQueueCapacity,
		pending:  map[string]*twitchItem{},
		wake:     make(chan struct{}, 1),
	}
}

// Enqueue schedules a broadcaster's reconcile. A broadcaster already waiting
// or in progress keeps its item, including any backoff or cost hold.
func (q *TwitchQueue) Enqueue(channel string) {
	if q == nil {
		zap.L().Error("twitch eventsub queue not configured", zap.String("channel", channel))
		return
	}
	q.mu.Lock()
	defer q.mu.Unlock()
	if q.pending[channel] != nil {
		return
	}
	if len(q.pending) >= q.capacity {
		zap.L().Warn("twitch eventsub queue full", zap.String("channel", channel), zap.Int("queue_depth", len(q.pending)))
		return
	}
	now := q.now()
	q.pending[channel] = &twitchItem{channel: channel, enqueued: now, ready: now}
	select {
	case q.wake <- struct{}{}:
	default:
	}
}

// Run drains the queue until ctx ends. Pending items are dropped on shutdown.
func (q *TwitchQueue) Run(ctx context.Context) {
	for ctx.Err() == nil {
		delay := q.step(ctx)
		if delay <= 0 {
			continue
		}
		timer := time.NewTimer(delay)
		select {
		case <-ctx.Done():
		case <-q.wake:
		case <-timer.C:
		}
		timer.Stop()
	}
}

// step processes at most one ready item and returns how long to wait before
// the next step.
func (q *TwitchQueue) step(ctx context.Context) time.Duration {
	now := q.now()
	if delay := q.budgetWait(now); delay > 0 {
		return delay
	}
	if q.costCheckDue(now) {
		q.checkCost(ctx, now)
		now = q.now()
	}
	item, delay := q.next(now)
	if item == nil {
		return delay
	}
	q.process(ctx, item)
	return 0
}

func (q *TwitchQueue) observe(header http.Header) {
	remaining, err := strconv.Atoi(header.Get("Ratelimit-Remaining"))
	if err != nil {
		return
	}
	reset, err := strconv.ParseInt(header.Get("Ratelimit-Reset"), 10, 64)
	if err != nil {
		return
	}
	q.remaining, q.reset = remaining, time.Unix(reset, 0)
}

// budgetWait is how long to pause so the bucket keeps its reserve.
func (q *TwitchQueue) budgetWait(now time.Time) time.Duration {
	if q.remaining <= twitchBudgetReserve && q.reset.After(now) {
		return q.reset.Sub(now)
	}
	return 0
}

// call sends single attempts with the app token, unless that would spend the
// reserve. Retries are scheduled by the queue rather than slept inside a lease.
func (q *TwitchQueue) call(token string) twitchCall {
	return func(ctx context.Context, method string, query url.Values, body, out any) error {
		if q.budgetWait(q.now()) > 0 {
			return errTwitchBudget
		}
		return q.service.API.twitchOnce(ctx, token, method, "/eventsub/subscriptions", query, body, out, q.observe)
	}
}

func (q *TwitchQueue) costCheckDue(now time.Time) bool {
	q.mu.Lock()
	defer q.mu.Unlock()
	for _, item := range q.pending {
		if item.costHeld {
			return !now.Before(q.costCheck)
		}
	}
	return false
}

// checkCost releases items held on the EventSub cost limit once Twitch
// reports headroom.
func (q *TwitchQueue) checkCost(ctx context.Context, now time.Time) {
	q.mu.Lock()
	q.costCheck = now.Add(twitchCostCheckInterval)
	q.mu.Unlock()
	var result struct {
		TotalCost    int `json:"total_cost"`
		MaxTotalCost int `json:"max_total_cost"`
	}
	token, err := q.service.API.Tokens.AppAccessToken(ctx, "twitch")
	if err == nil {
		err = q.call(token)(ctx, http.MethodGet, url.Values{"first": {"1"}}, nil, &result)
	}
	if err != nil {
		zap.L().Warn("twitch eventsub cost check failed", zap.Error(err))
		return
	}
	headroom := result.MaxTotalCost > 0 && result.TotalCost < result.MaxTotalCost
	q.mu.Lock()
	held := 0
	for _, item := range q.pending {
		if item.costHeld {
			held++
			if headroom {
				item.costHeld = false
				item.ready = now
			}
		}
	}
	depth, oldest := q.stats(now)
	q.mu.Unlock()
	zap.L().Info("twitch eventsub cost check", zap.Int("total_cost", result.TotalCost), zap.Int("max_total_cost", result.MaxTotalCost), zap.Bool("headroom", headroom), zap.Int("held", held), zap.Int("queue_depth", depth), zap.Int64("oldest_pending_ms", oldest.Milliseconds()))
}

// next marks the oldest ready item running, or returns how long until one may
// be ready.
func (q *TwitchQueue) next(now time.Time) (*twitchItem, time.Duration) {
	q.mu.Lock()
	defer q.mu.Unlock()
	var found *twitchItem
	delay := twitchIdle
	for _, item := range q.pending {
		switch {
		case item.running:
		case item.costHeld:
			if wait := q.costCheck.Sub(now); wait < delay {
				delay = wait
			}
		case item.ready.After(now):
			if wait := item.ready.Sub(now); wait < delay {
				delay = wait
			}
		case found == nil || item.enqueued.Before(found.enqueued) || (item.enqueued.Equal(found.enqueued) && item.channel < found.channel):
			found = item
		}
	}
	if found != nil {
		found.running = true
	}
	return found, delay
}

// stats must be called with q.mu held.
func (q *TwitchQueue) stats(now time.Time) (int, time.Duration) {
	var oldest time.Duration
	for _, item := range q.pending {
		if age := now.Sub(item.enqueued); age > oldest {
			oldest = age
		}
	}
	return len(q.pending), oldest
}

// retryAt is when Twitch asked for a retry, from Retry-After or
// Ratelimit-Reset, or zero if it didn't say.
func retryAt(header http.Header, now time.Time) time.Time {
	var at time.Time
	if seconds, err := strconv.Atoi(header.Get("Retry-After")); err == nil && seconds > 0 {
		at = now.Add(time.Duration(seconds) * time.Second)
	}
	if date, err := http.ParseTime(header.Get("Retry-After")); err == nil && date.After(at) {
		at = date
	}
	if reset, err := strconv.ParseInt(header.Get("Ratelimit-Reset"), 10, 64); err == nil && time.Unix(reset, 0).After(at) {
		at = time.Unix(reset, 0)
	}
	return at
}

// after returns at, or now plus fallback when at has already passed.
func after(now, at time.Time, fallback time.Duration) time.Time {
	if at.After(now) {
		return at
	}
	return now.Add(fallback)
}

func (q *TwitchQueue) process(ctx context.Context, item *twitchItem) {
	var result twitchReconcile
	token, err := q.service.API.Tokens.AppAccessToken(ctx, "twitch")
	if err == nil {
		err = q.lock(ctx, "twitch:"+item.channel, func(ctx context.Context) error {
			var err error
			result, err = q.service.reconcileTwitch(ctx, item.channel, q.call(token))
			return err
		})
	}
	if ctx.Err() != nil {
		return
	}
	now := q.now()
	outcome := "complete"
	var retry *retryError
	var callableErr *callable.Error
	var uncertain *subscriptionlock.UncertainError
	q.mu.Lock()
	item.running = false
	switch {
	case errors.Is(err, subscriptionlock.ErrBusy):
		// Another request or replica holds the broadcaster; not a failure.
		outcome = "busy"
		item.ready = now.Add(twitchBusyDelay)
	case err == nil && len(result.held) > 0:
		outcome = "cost_held"
		item.costHeld = true
		if q.costCheck.Before(now) {
			q.costCheck = now.Add(twitchCostCheckInterval)
		}
	case err == nil:
		delete(q.pending, item.channel)
	case errors.Is(err, errTwitchBudget):
		outcome = "rate_limited"
		item.ready = after(now, q.reset, time.Minute)
	case isStatus(err, 429) && errors.As(err, &retry):
		outcome = "rate_limited"
		item.ready = after(now, retryAt(retry.Header, now), time.Minute)
	case errors.As(err, &callableErr):
		outcome = "dropped"
		delete(q.pending, item.channel)
	default:
		item.attempts++
		if item.attempts >= twitchMaxAttempts {
			outcome = "dropped"
			delete(q.pending, item.channel)
			break
		}
		outcome = "retry"
		delay := 30 * time.Second << (item.attempts - 1)
		// An uncertain mutation keeps the broadcaster's lease until it expires.
		if errors.As(err, &uncertain) && delay < 90*time.Second {
			delay = 90 * time.Second
		}
		item.ready = now.Add(delay)
		if errors.As(err, &retry) {
			if at := retryAt(retry.Header, now); at.After(item.ready) {
				item.ready = at
			}
		}
	}
	depth, oldest := q.stats(now)
	attempts := item.attempts
	q.mu.Unlock()
	fields := []zap.Field{zap.String("channel", item.channel), zap.String("outcome", outcome), zap.Int("created", result.created), zap.Strings("skipped", result.skipped), zap.Strings("held", result.held), zap.Int("attempts", attempts), zap.Int64("wait_ms", now.Sub(item.enqueued).Milliseconds()), zap.Int("queue_depth", depth), zap.Int64("oldest_pending_ms", oldest.Milliseconds())}
	if err != nil {
		fields = append(fields, zap.Error(err))
	}
	zap.L().Info("twitch eventsub reconcile", fields...)
}
