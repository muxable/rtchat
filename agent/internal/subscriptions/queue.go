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
	// twitchAppInterval is how often each replica rechecks the app
	// subscription, in case Twitch revoked it without a delivered revocation.
	twitchAppInterval = time.Hour
	// twitchRemovedTTL is how long revocations for a broadcaster just removed
	// are ignored. One deauthorization revokes every scoped subscription.
	twitchRemovedTTL = 5 * time.Minute
)

var errTwitchBudget = errors.New("Twitch rate-limit reserve reached")

// twitchJob is what an item does for its broadcaster.
type twitchJob int

const (
	// twitchReconcileJob creates a broadcaster's missing subscriptions.
	twitchReconcileJob twitchJob = iota
	// twitchRemoveJob deletes a deauthorized broadcaster's subscriptions.
	twitchRemoveJob
	// twitchAppJob ensures the app's user.authorization.revoke subscription.
	twitchAppJob
)

// twitchAppKey is the app subscription's item and lease key. It isn't numeric,
// so it can't collide with a broadcaster.
const twitchAppKey = "app-authorization"

type twitchItem struct {
	channel  string
	job      twitchJob
	enqueued time.Time
	ready    time.Time
	attempts int
	costHeld bool
	running  bool
	// changed is set when the job changes while the item runs, even back to
	// the running job, so the latest intent still runs after it.
	changed bool
}

// TwitchQueue reconciles broadcasters' EventSub subscriptions, and removes
// them when a broadcaster deauthorizes the app, on one worker per replica,
// paced by Twitch's rate and cost limits. It is not durable: subscribe runs on
// every channel open, so a lost reconcile is redone, but a removal lost to a
// restart leaves that broadcaster's unscoped subscriptions behind.
type TwitchQueue struct {
	service *Service
	now     func() time.Time
	lock    func(context.Context, string, func(context.Context) error) error
	// reauthorized reports whether a broadcaster authorized the app again
	// after a deauthorization, so their removal must be skipped.
	reauthorized func(context.Context, string) (bool, error)
	capacity     int
	wake         chan struct{}

	// remaining and reset are the app token's Helix bucket as last reported
	// to the worker. Every replica and job using the client ID shares it.
	remaining int
	reset     time.Time

	mu      sync.Mutex
	pending map[string]*twitchItem
	// removed is when each broadcaster's removal last finished.
	removed   map[string]time.Time
	costCheck time.Time
	// cappedUntil is when the last report that Twitch's EventSub cost limit
	// is full stops applying. Twitch then rejects every new subscription, so
	// subscribe doesn't queue work that can't succeed.
	cappedUntil time.Time
}

func NewTwitchQueue(s *Service) *TwitchQueue {
	return &TwitchQueue{
		service: s,
		now:     time.Now,
		lock: func(ctx context.Context, key string, work func(context.Context) error) error {
			return subscriptionlock.TryWith(ctx, s.DB, key, work)
		},
		reauthorized: s.twitchReauthorized,
		capacity:     twitchQueueCapacity,
		pending:      map[string]*twitchItem{},
		removed:      map[string]time.Time{},
		wake:         make(chan struct{}, 1),
	}
}

// Enqueue schedules a broadcaster's reconcile. A broadcaster already waiting
// or in progress for a reconcile keeps its item, including any backoff or cost
// hold.
func (q *TwitchQueue) Enqueue(channel string) { q.enqueue(channel, twitchReconcileJob) }

// EnqueueRemove schedules the deletion of a broadcaster's subscriptions after
// they deauthorize the app.
func (q *TwitchQueue) EnqueueRemove(channel string) { q.enqueue(channel, twitchRemoveJob) }

// Deauthorized schedules a removal for a deauthorization. Revocations for a
// broadcaster removed within twitchRemovedTTL are repeats of the same
// deauthorization and are ignored. The user.authorization.revoke notification
// always removes, since the broadcaster may have re-authorized on another
// replica and deauthorized again.
func (q *TwitchQueue) Deauthorized(channel string, revocation bool) {
	if q != nil && revocation {
		q.mu.Lock()
		at, ok := q.removed[channel]
		q.mu.Unlock()
		if ok && q.now().Sub(at) < twitchRemovedTTL {
			return
		}
	}
	q.EnqueueRemove(channel)
}

// EnsureApp schedules a check of the app's user.authorization.revoke
// subscription, recreating it if it is missing or failed.
func (q *TwitchQueue) EnsureApp() { q.enqueue(twitchAppKey, twitchAppJob) }

// enqueue keeps one item per broadcaster, and the latest intent wins: enqueuing
// the other job switches a waiting item to it with fresh retry state, and one
// that arrives while the item runs keeps the item queued to run the new job
// next. A subscribe after re-authorization therefore replaces a pending
// removal, and a deauthorization after a subscribe removes.
func (q *TwitchQueue) enqueue(channel string, job twitchJob) {
	if q == nil {
		zap.L().Error("twitch eventsub queue not configured", zap.String("channel", channel))
		return
	}
	q.mu.Lock()
	defer q.mu.Unlock()
	now := q.now()
	if item := q.pending[channel]; item != nil {
		if item.job == job {
			// A removal already running may have checked re-authorization
			// before this deauthorization, so it runs again.
			if job == twitchRemoveJob && item.running {
				item.changed = true
			}
			return
		}
		item.job = job
		item.changed = item.running
		if !item.running {
			item.attempts, item.costHeld, item.ready = 0, false, now
		}
		q.signal()
		return
	}
	// Removals free cost, and the app subscription costs nothing.
	if job == twitchReconcileJob && now.Before(q.cappedUntil) {
		zap.L().Info("twitch eventsub reconcile skipped while cost limit is full", zap.String("channel", channel))
		return
	}
	if len(q.pending) >= q.capacity {
		zap.L().Warn("twitch eventsub queue full", zap.String("channel", channel), zap.Int("queue_depth", len(q.pending)))
		return
	}
	q.pending[channel] = &twitchItem{channel: channel, job: job, enqueued: now, ready: now}
	q.signal()
}

func (q *TwitchQueue) signal() {
	select {
	case q.wake <- struct{}{}:
	default:
	}
}

// Run drains the queue until ctx ends. Pending items are dropped on shutdown.
// Every replica checks the app subscription at start and every
// twitchAppInterval; the lease lets one create it.
func (q *TwitchQueue) Run(ctx context.Context) {
	var appAt time.Time
	for ctx.Err() == nil {
		if now := q.now(); !now.Before(appAt) {
			q.EnsureApp()
			appAt = now.Add(twitchAppInterval)
		}
		delay := q.step(ctx)
		if wait := appAt.Sub(q.now()); delay > wait {
			delay = wait
		}
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
	item, job, delay := q.next(now)
	if item == nil {
		return delay
	}
	q.process(ctx, item, job)
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
	if headroom {
		q.cappedUntil = time.Time{}
	} else {
		q.cappedUntil = now.Add(twitchCostCheckInterval)
	}
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

// next marks the oldest ready item running and returns the job it runs, or
// returns how long until one may be ready.
func (q *TwitchQueue) next(now time.Time) (*twitchItem, twitchJob, time.Duration) {
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
	if found == nil {
		return nil, 0, delay
	}
	found.running, found.changed = true, false
	return found, found.job, delay
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

func (q *TwitchQueue) process(ctx context.Context, item *twitchItem, job twitchJob) {
	var result twitchReconcile
	deleted := 0
	reauthorized := false
	token, err := q.service.API.Tokens.AppAccessToken(ctx, "twitch")
	if err == nil {
		// Removals take the reconcile's lease so the two never interleave.
		err = q.lock(ctx, "twitch:"+item.channel, func(ctx context.Context) error {
			var err error
			switch job {
			case twitchRemoveJob:
				// Checked under the lease, which subscribe also takes.
				if reauthorized, err = q.reauthorized(ctx, item.channel); err == nil && !reauthorized {
					deleted, err = q.service.removeTwitch(ctx, item.channel, q.call(token))
				}
			case twitchAppJob:
				result, err = q.service.ensureTwitchApp(ctx, q.call(token))
			default:
				result, err = q.service.reconcileTwitch(ctx, item.channel, q.call(token))
			}
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
	if deleted > 0 {
		// Freed cost, even if the removal then failed or was superseded: stop
		// dropping reconciles, and recheck held ones.
		q.cappedUntil, q.costCheck = time.Time{}, now
	}
	switch {
	case item.changed:
		// Another job was enqueued while this one ran; the latest runs next.
		// A reconcile, removal, then reconcile again must reconcile again: the
		// first may have run before the deauthorization revoked anything.
		outcome = "superseded"
		item.changed = false
		item.attempts, item.costHeld, item.ready = 0, false, now
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
		q.cappedUntil = now.Add(twitchCostCheckInterval)
	case err == nil:
		delete(q.pending, item.channel)
		switch {
		case job == twitchRemoveJob && reauthorized:
			// Not a removal, so it doesn't suppress the revocations of a
			// later deauthorization.
			outcome = "reauthorized"
		case job == twitchRemoveJob:
			for channel, at := range q.removed {
				if now.Sub(at) >= twitchRemovedTTL {
					delete(q.removed, channel)
				}
			}
			q.removed[item.channel] = now
		}
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
	fields := []zap.Field{zap.String("channel", item.channel), zap.String("outcome", outcome), zap.Int("attempts", attempts), zap.Int64("wait_ms", now.Sub(item.enqueued).Milliseconds()), zap.Int("queue_depth", depth), zap.Int64("oldest_pending_ms", oldest.Milliseconds())}
	if err != nil {
		fields = append(fields, zap.Error(err))
	}
	switch job {
	case twitchRemoveJob:
		zap.L().Info("twitch eventsub remove", append(fields, zap.Int("deleted", deleted))...)
	case twitchAppJob:
		zap.L().Info("twitch eventsub app authorization", append(fields, zap.Int("created", result.created), zap.Strings("held", result.held))...)
	default:
		zap.L().Info("twitch eventsub reconcile", append(fields, zap.Int("created", result.created), zap.Strings("skipped", result.skipped), zap.Strings("held", result.held))...)
	}
}
