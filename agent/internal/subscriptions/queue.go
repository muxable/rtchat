package subscriptions

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"reflect"
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
	twitchMaxAttempts       = 6
	twitchIdle              = time.Hour
)

var errTwitchBudget = errors.New("Twitch rate-limit reserve reached")

// twitchBudget is the last Ratelimit-Remaining and Ratelimit-Reset Twitch
// reported. Every replica and job shares the bucket for the client ID.
type twitchBudget struct {
	mu        sync.Mutex
	known     bool
	remaining int
	reset     time.Time
}

func (b *twitchBudget) observe(header http.Header) {
	if b == nil {
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
	b.mu.Lock()
	defer b.mu.Unlock()
	b.known, b.remaining, b.reset = true, remaining, time.Unix(reset, 0)
}

// wait returns how long to pause so remaining stays above reserve.
func (b *twitchBudget) wait(now time.Time, reserve int) time.Duration {
	b.mu.Lock()
	defer b.mu.Unlock()
	if !b.known || b.remaining > reserve || !b.reset.After(now) {
		return 0
	}
	return b.reset.Sub(now)
}

type twitchItem struct {
	channel  string
	seq      uint64
	enqueued time.Time
	ready    time.Time
	attempts int
	costHeld bool
}

// TwitchQueue reconciles broadcasters' EventSub subscriptions on one worker
// per replica, paced by Twitch's rate and cost limits. It is not durable:
// subscribe runs on every channel open, so work lost to a restart is redone.
type TwitchQueue struct {
	service  *Service
	now      func() time.Time
	lock     func(context.Context, string, func(context.Context) error) error
	capacity int

	mu        sync.Mutex
	pending   map[string]*twitchItem
	seq       uint64
	costCheck time.Time
	wake      chan struct{}
}

func NewTwitchQueue(s *Service) *TwitchQueue {
	if s.API.budget == nil {
		s.API.budget = &twitchBudget{}
	}
	return &TwitchQueue{
		service: s,
		now:     time.Now,
		lock: func(ctx context.Context, key string, work func(context.Context) error) error {
			return subscriptionlock.With(ctx, s.DB, key, work)
		},
		capacity: twitchQueueCapacity,
		pending:  map[string]*twitchItem{},
		wake:     make(chan struct{}, 1),
	}
}

// Enqueue schedules a broadcaster's reconcile. A broadcaster already waiting
// keeps its place, so repeated channel opens don't add work.
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
	q.seq++
	q.pending[channel] = &twitchItem{channel: channel, seq: q.seq, enqueued: now, ready: now}
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
	if delay := q.service.API.budget.wait(now, twitchBudgetReserve); delay > 0 {
		return delay
	}
	if q.costCheckDue(now) {
		q.checkCost(ctx, now)
	}
	item, delay := q.next(now)
	if item == nil {
		return delay
	}
	q.process(ctx, item)
	return 0
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
		err = q.service.API.twitch(ctx, token, http.MethodGet, "/eventsub/subscriptions", url.Values{"first": {"1"}}, nil, &result)
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

// next removes the oldest ready item, or returns how long until one may be.
func (q *TwitchQueue) next(now time.Time) (*twitchItem, time.Duration) {
	q.mu.Lock()
	defer q.mu.Unlock()
	var found *twitchItem
	delay := twitchIdle
	for _, item := range q.pending {
		if item.costHeld {
			if wait := q.costCheck.Sub(now); wait < delay {
				delay = wait
			}
			continue
		}
		if item.ready.After(now) {
			if wait := item.ready.Sub(now); wait < delay {
				delay = wait
			}
			continue
		}
		if found == nil || item.seq < found.seq {
			found = item
		}
	}
	if found != nil {
		delete(q.pending, found.channel)
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

func (q *TwitchQueue) depth() int {
	q.mu.Lock()
	defer q.mu.Unlock()
	return len(q.pending)
}

// requeue puts an item back unless the broadcaster was enqueued again while
// it was in flight, in which case the newer item covers it.
func (q *TwitchQueue) requeue(item *twitchItem, now time.Time) {
	q.mu.Lock()
	defer q.mu.Unlock()
	if existing := q.pending[item.channel]; existing != nil {
		existing.seq, existing.enqueued = item.seq, item.enqueued
		return
	}
	if item.costHeld && q.costCheck.Before(now) {
		q.costCheck = now.Add(twitchCostCheckInterval)
	}
	q.pending[item.channel] = item
}

type twitchReconcile struct {
	created int
	skipped []string
	held    []string
}

func (q *TwitchQueue) process(ctx context.Context, item *twitchItem) {
	var result twitchReconcile
	token, err := q.service.API.Tokens.AppAccessToken(ctx, "twitch")
	if err == nil {
		err = q.lock(ctx, "twitch:"+item.channel, func(ctx context.Context) error {
			var err error
			result, err = q.reconcile(ctx, item.channel, token)
			return err
		})
	}
	if ctx.Err() != nil {
		return
	}
	now := q.now()
	outcome := "complete"
	var callableErr *callable.Error
	var uncertain *subscriptionlock.UncertainError
	switch {
	case err == nil && len(result.held) > 0:
		outcome = "cost_held"
		item.costHeld = true
		q.requeue(item, now)
	case err == nil:
	case errors.Is(err, errTwitchBudget) || (isStatus(err, 429) && !errors.As(err, new(*costLimitError))):
		outcome = "rate_limited"
		delay := q.service.API.budget.wait(now, twitchBudgetReserve)
		if delay <= 0 {
			delay = time.Minute
		}
		item.ready = now.Add(delay)
		q.requeue(item, now)
	case errors.As(err, &callableErr):
		outcome = "dropped"
	default:
		item.attempts++
		if item.attempts >= twitchMaxAttempts {
			outcome = "dropped"
			break
		}
		outcome = "retry"
		delay := 30 * time.Second << (item.attempts - 1)
		// An uncertain mutation keeps the broadcaster's lease until it expires.
		if errors.As(err, &uncertain) && delay < 90*time.Second {
			delay = 90 * time.Second
		}
		item.ready = now.Add(delay)
		q.requeue(item, now)
	}
	q.mu.Lock()
	depth, oldest := q.stats(now)
	q.mu.Unlock()
	fields := []zap.Field{zap.String("channel", item.channel), zap.String("outcome", outcome), zap.Int("created", result.created), zap.Strings("skipped", result.skipped), zap.Strings("held", result.held), zap.Int("attempts", item.attempts), zap.Int64("wait_ms", now.Sub(item.enqueued).Milliseconds()), zap.Int("queue_depth", depth), zap.Int64("oldest_pending_ms", oldest.Milliseconds())}
	if err != nil {
		fields = append(fields, zap.Error(err))
	}
	zap.L().Info("twitch eventsub reconcile", fields...)
}

// call makes a Twitch request unless it would spend the reserved budget.
func (q *TwitchQueue) call(ctx context.Context, token, method string, query url.Values, body, out any) error {
	if q.service.API.budget.wait(q.now(), twitchBudgetReserve) > 0 {
		return errTwitchBudget
	}
	return q.service.API.twitch(ctx, token, method, "/eventsub/subscriptions", query, body, out)
}

func (q *TwitchQueue) list(ctx context.Context, id, token string) ([]twitchSubscription, error) {
	var subscriptions []twitchSubscription
	seen := map[string]bool{}
	query := url.Values{"user_id": {id}}
	for {
		var result struct {
			Data       []twitchSubscription `json:"data"`
			Pagination struct {
				Cursor string `json:"cursor"`
			} `json:"pagination"`
		}
		if err := q.call(ctx, token, http.MethodGet, query, nil, &result); err != nil {
			return nil, err
		}
		if result.Data == nil {
			return nil, fmt.Errorf("Twitch subscriptions response missing data")
		}
		subscriptions = append(subscriptions, result.Data...)
		cursor := result.Pagination.Cursor
		if cursor == "" {
			return subscriptions, nil
		}
		if seen[cursor] {
			return nil, fmt.Errorf("Twitch subscription pagination loop")
		}
		seen[cursor] = true
		query.Set("after", cursor)
	}
}

// reconcile lists a broadcaster's subscriptions and creates the missing ones.
// Each attempt lists first, so a POST with an uncertain outcome is never
// created twice.
func (q *TwitchQueue) reconcile(ctx context.Context, id, token string) (twitchReconcile, error) {
	var result twitchReconcile
	if err := q.service.checkTwitchSecret(); err != nil {
		return result, err
	}
	existing, err := q.list(ctx, id, token)
	if err != nil {
		return result, err
	}
	wantedSubscriptions := twitchConditions(id)
	// Validate the entire existing set before any creation/deletion. A later
	// legacy callback conflict must not leave a partially migrated broadcaster.
	for _, wanted := range wantedSubscriptions {
		for _, sub := range existing {
			if sub.Type == wanted.Type && sub.Version == wanted.Version && reflect.DeepEqual(sub.Condition, wanted.Condition) && !ownCallback(sub) {
				return result, &callable.Error{Code: "failed-precondition", Message: "Twitch callbacks require coordinated migration before enabling subscriptions"}
			}
		}
	}
	for _, wanted := range wantedSubscriptions {
		found := false
		for _, sub := range existing {
			if sub.Type != wanted.Type || sub.Version != wanted.Version || !reflect.DeepEqual(sub.Condition, wanted.Condition) {
				continue
			}
			if sub.Status == "enabled" || sub.Status == "webhook_callback_verification_pending" {
				found = true
				break
			}
			// Failed subscriptions at our own callback may be replaced safely. Never
			// delete a legacy or unknown transport as a side effect of app activity.
			if err = q.call(ctx, token, http.MethodDelete, url.Values{"id": {sub.ID}}, nil, nil); err != nil && !isStatus(err, 404) {
				return result, err
			}
		}
		if found {
			continue
		}
		body := map[string]interface{}{"type": wanted.Type, "version": wanted.Version, "condition": wanted.Condition, "transport": map[string]interface{}{"method": "webhook", "callback": TwitchCallback, "secret": q.service.TwitchSecret}}
		err = q.call(ctx, token, http.MethodPost, nil, body, nil)
		outcome := "created"
		switch {
		case err == nil:
			result.created++
		case isStatus(err, 403):
			outcome = "scope_unavailable"
			result.skipped = append(result.skipped, wanted.Type)
		case errors.As(err, new(*costLimitError)):
			// Held until Twitch reports cost headroom.
			outcome = "cost_limited"
			result.held = append(result.held, wanted.Type)
		case isStatus(err, 400):
			// Retired types or versions.
			outcome = "rejected"
			result.skipped = append(result.skipped, wanted.Type)
		case errors.Is(err, errTwitchBudget):
			return result, err
		case isStatus(err, 429):
			outcome = "rate_limited"
		default:
			outcome = "error"
		}
		zap.L().Info("twitch eventsub create", zap.String("channel", id), zap.String("type", wanted.Type), zap.String("outcome", outcome), zap.Error(err))
		if outcome == "rate_limited" || outcome == "error" {
			return result, err
		}
	}
	return result, nil
}
