package eventsubmigration

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"sort"
	"time"

	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
)

type Locker func(context.Context, string, func(context.Context) error) error
type Migrator struct {
	API        *API
	Snapshot   Snapshot
	Checkpoint Checkpoint
	// Save durably records one entry's progress before returning.
	Save func(id string, progress Progress) error
	Lock Locker
	// Secret signs the subscriptions this mode creates: the dedicated
	// twitch-eventsub-secret going forward, the legacy secret for rollback.
	Secret string
	// RestoreSecret signs a subscription recreated where it was after a
	// break-before-make whose replacement failed: the legacy secret going
	// forward, the dedicated secret for rollback.
	RestoreSecret string
	// Activity maps a broadcaster ID to channels/twitch:<id>.lastActiveAt;
	// recently active broadcasters migrate first.
	Activity map[string]time.Time
	// MaxAttempts skips entries that already failed this many times unless
	// RetryFailed is set. Zero means 3.
	MaxAttempts int
	RetryFailed bool
	// ChunkSize and ChunkBudget bound the work done under one per-broadcaster
	// lease, which subscriptionlock limits to 45 seconds.
	ChunkSize     int
	ChunkBudget   time.Duration
	VerifyTimeout time.Duration
	PollInterval  time.Duration
	Now           func() time.Time
	Log           func(format string, args ...interface{})

	originals   map[string]bool
	costLogged  bool
	sinceReport int
}

// Summary describes one invocation. Migrated and Failed count subscriptions
// attempted in this invocation; Remaining counts planned subscriptions that
// are not yet complete according to the checkpoint.
type Summary struct {
	Planned, Migrated, AlreadyDone, Failed, SkippedFailed, CostBlocked, Remaining int
}

func (s Summary) String() string {
	return fmt.Sprintf("planned %d; migrated this run %d; already migrated %d; failed this run %d; skipped after repeated failures %d; blocked by cost cap %d; remaining %d",
		s.Planned, s.Migrated, s.AlreadyDone, s.Failed, s.SkippedFailed, s.CostBlocked, s.Remaining)
}

// errCostBlocked means a break-before-make would delete a subscription
// without freeing enough cost for its replacement, so nothing was changed.
var errCostBlocked = errors.New("over the EventSub cost cap: deleting this subscription would not free room for its replacement; source retained")

type checkpointError struct{ err error }

func (e *checkpointError) Error() string { return "checkpoint write failed: " + e.err.Error() }
func (e *checkpointError) Unwrap() error { return e.err }

// fatal reports errors that make every later subscription fail too: a
// rejected app token or an unwritable checkpoint. Everything else is recorded
// against the one subscription and the run continues.
func fatal(err error) bool {
	var checkpoint *checkpointError
	if errors.As(err, &checkpoint) {
		return true
	}
	var status *HTTPError
	return errors.As(err, &status) && status.Status == 401
}

func active(status string) bool {
	return status == "enabled" || status == "webhook_callback_verification_pending"
}
func Eligible(sub Subscription) bool {
	return sub.Transport.Method == "webhook" && (sub.Transport.Callback == LegacyCallback || sub.Transport.Callback == AliasCallback) && active(sub.Status)
}
func (s Snapshot) Planned() []Subscription {
	var plan []Subscription
	for _, sub := range s.Subscriptions {
		if Eligible(sub) {
			plan = append(plan, sub)
		}
	}
	return plan
}

// Group is one broadcaster's planned subscriptions, migrated under one lease.
type Group struct {
	Key, Broadcaster string
	LastActive       time.Time
	Subscriptions    []Subscription
}

// Order groups planned subscriptions by broadcaster, most recently active
// first; broadcasters without a lastActiveAt follow, then subscriptions with
// no user in their condition. Ties break by key and subscription ID.
func (s Snapshot) Order(activity map[string]time.Time) []Group {
	index := map[string]int{}
	var groups []Group
	for _, sub := range s.Planned() {
		user := conditionUser(sub)
		key := "twitch:" + user
		if user == "" {
			key = "twitch-eventsub-" + sub.ID
		}
		i, ok := index[key]
		if !ok {
			i = len(groups)
			index[key] = i
			group := Group{Key: key, Broadcaster: user}
			if user != "" {
				group.LastActive = activity[user]
			}
			groups = append(groups, group)
		}
		groups[i].Subscriptions = append(groups[i].Subscriptions, sub)
	}
	for _, group := range groups {
		sort.Slice(group.Subscriptions, func(i, j int) bool { return group.Subscriptions[i].ID < group.Subscriptions[j].ID })
	}
	sort.Slice(groups, func(i, j int) bool {
		a, b := groups[i], groups[j]
		if !a.LastActive.Equal(b.LastActive) {
			return a.LastActive.After(b.LastActive)
		}
		if (a.Broadcaster == "") != (b.Broadcaster == "") {
			return b.Broadcaster == ""
		}
		return a.Key < b.Key
	})
	return groups
}

func canonical(condition json.RawMessage) []byte {
	var value interface{}
	decoder := json.NewDecoder(bytes.NewReader(condition))
	decoder.UseNumber()
	if decoder.Decode(&value) != nil {
		return nil
	}
	data, _ := json.Marshal(value)
	return data
}
func same(a, b Subscription) bool {
	return a.Type == b.Type && a.Version == b.Version && bytes.Equal(canonical(a.Condition), canonical(b.Condition))
}
func matches(sub, wanted Subscription, callback string) bool {
	return same(sub, wanted) && sub.Transport.Method == "webhook" && sub.Transport.Callback == callback
}
func find(list []Subscription, wanted Subscription, callback string) *Subscription {
	var pending *Subscription
	for _, sub := range list {
		if !matches(sub, wanted, callback) {
			continue
		}
		if sub.Status == "enabled" {
			found := sub
			return &found
		}
		if sub.Status == "webhook_callback_verification_pending" {
			found := sub
			pending = &found
		}
	}
	return pending
}
func byID(list []Subscription, id string) *Subscription {
	for _, sub := range list {
		if sub.ID == id {
			found := sub
			return &found
		}
	}
	return nil
}
func conditionUser(sub Subscription) string {
	var condition map[string]json.RawMessage
	json.Unmarshal(sub.Condition, &condition)
	for _, key := range []string{"broadcaster_user_id", "to_broadcaster_user_id", "from_broadcaster_user_id", "user_id", "moderator_user_id"} {
		var id string
		if json.Unmarshal(condition[key], &id) == nil && id != "" {
			return id
		}
	}
	return ""
}
func query(sub Subscription) url.Values {
	if id := conditionUser(sub); id != "" {
		return url.Values{"user_id": {id}}
	}
	return url.Values{"type": {sub.Type}}
}

// roomAfterSwap reports whether deleting a subscription of cost freed and
// creating its replacement keeps the client within max_total_cost.
func roomAfterSwap(total, max, freed int) bool {
	needed := freed
	if needed < 1 {
		needed = 1
	}
	return max <= 0 || total-freed+needed <= max
}

func (m *Migrator) originalID(id string) bool {
	if m.originals == nil {
		m.originals = map[string]bool{}
		for _, sub := range m.Snapshot.Subscriptions {
			m.originals[sub.ID] = true
		}
	}
	return m.originals[id]
}
func (m *Migrator) save(id string, progress Progress) error {
	m.Checkpoint.Entries[id] = progress
	if err := m.Save(id, progress); err != nil {
		return &checkpointError{err}
	}
	return nil
}
func (m *Migrator) now() time.Time {
	if m.Now != nil {
		return m.Now()
	}
	return time.Now()
}
func (m *Migrator) logf(format string, args ...interface{}) {
	if m.Log != nil {
		m.Log(format, args...)
	}
}

// liveID is the subscription currently standing in for a snapshot source.
func (m *Migrator) liveID(source Subscription) string {
	if restored := m.Checkpoint.Entries[source.ID].RestoredID; restored != "" {
		return restored
	}
	return source.ID
}
func (m *Migrator) done(source Subscription, rollback bool) bool {
	progress := m.Checkpoint.Entries[source.ID]
	if rollback {
		return progress.RolledBack
	}
	return progress.DeletedOld
}

func (m *Migrator) Run(ctx context.Context, limit int, rollback bool) (summary Summary, err error) {
	if err := m.Snapshot.Validate(m.API.ClientID); err != nil {
		return summary, err
	}
	if m.Checkpoint.SnapshotHash != m.Snapshot.hash() || m.Checkpoint.Entries == nil || m.Save == nil || m.Lock == nil {
		return summary, fmt.Errorf("durable checkpoint and distributed lock are required")
	}
	for _, secret := range []string{m.Secret, m.RestoreSecret} {
		if len(secret) < 10 || len(secret) > 100 {
			return summary, fmt.Errorf("callback signing secrets must contain 10 to 100 bytes")
		}
	}
	if limit < 0 {
		return summary, fmt.Errorf("batch limit must not be negative")
	}
	maxAttempts := m.MaxAttempts
	if maxAttempts <= 0 {
		maxAttempts = 3
	}
	skip := func(source Subscription) bool {
		return !m.RetryFailed && m.Checkpoint.Entries[source.ID].Attempts >= maxAttempts
	}
	planned := m.Snapshot.Planned()
	summary.Planned = len(planned)
	for _, source := range planned {
		progress := m.Checkpoint.Entries[source.ID]
		if !rollback && progress.RolledBack {
			return summary, fmt.Errorf("snapshot has rolled-back entries; take a new snapshot before another forward migration")
		}
		if m.done(source, rollback) {
			summary.AlreadyDone++
		} else if skip(source) {
			summary.SkippedFailed++
		}
	}
	m.originalID("")
	defer func() {
		summary.Remaining = 0
		for _, source := range planned {
			if !m.done(source, rollback) {
				summary.Remaining++
			}
		}
	}()

	queue := m.Snapshot.Order(m.Activity)
	for gi := 0; gi < len(queue); gi++ {
		group := queue[gi]
		var pending []Subscription
		for _, source := range group.Subscriptions {
			if !m.done(source, rollback) && !skip(source) {
				pending = append(pending, source)
			}
		}
		for len(pending) > 0 {
			allowed := 0
			if limit > 0 {
				if allowed = limit - summary.Migrated - summary.Failed; allowed <= 0 {
					return summary, nil
				}
			}
			if err := m.API.Pacer.Hold(ctx); err != nil {
				return summary, err
			}
			var out chunk
			ran := false
			err := m.Lock(ctx, group.Key, func(lctx context.Context) error {
				ran = true
				out = chunk{rest: pending}
				if rollback {
					m.rollbackChunk(ctx, lctx, &out, allowed)
				} else {
					m.forwardChunk(ctx, lctx, &out, allowed)
				}
				if out.fatal != nil {
					return out.fatal
				}
				// Keep the lease after an uncertain mutation, as everywhere else.
				return out.uncertain
			})
			summary.Migrated += out.migrated
			summary.Failed += out.failed
			summary.CostBlocked += out.costBlocked
			m.report(out, &summary)
			if out.fatal != nil {
				return summary, out.fatal
			}
			if ctx.Err() != nil {
				return summary, ctx.Err()
			}
			if err != nil && !ran {
				return summary, fmt.Errorf("broadcaster lease %s: %w", group.Key, err)
			}
			if len(out.rest) == len(pending) {
				return summary, fmt.Errorf("no progress under broadcaster lease %s", group.Key)
			}
			pending = out.rest
			if out.interrupted && len(pending) > 0 {
				// Retry the rest of this broadcaster after the others, once an
				// uncertain mutation's retained lease has had time to expire.
				queue = append(queue, Group{Key: group.Key, Broadcaster: group.Broadcaster, LastActive: group.LastActive, Subscriptions: pending})
				break
			}
		}
	}
	return summary, nil
}

func (m *Migrator) report(out chunk, summary *Summary) {
	m.sinceReport += out.migrated + out.failed
	if m.sinceReport >= 500 {
		m.sinceReport = 0
		m.logf("progress: migrated %d, failed %d, cost-blocked %d this run", summary.Migrated, summary.Failed, summary.CostBlocked)
	}
}

// chunk is the outcome of the work done under one lease.
type chunk struct {
	rest                          []Subscription
	start                         time.Time
	work                          int
	migrated, failed, costBlocked int
	interrupted                   bool
	fatal, uncertain              error
}

func (m *Migrator) chunkFull(out *chunk, allowed int) bool {
	size := m.ChunkSize
	if size <= 0 {
		size = 15
	}
	budget := m.ChunkBudget
	if budget <= 0 {
		budget = 15 * time.Second
	}
	if allowed > 0 && out.work >= allowed {
		return true
	}
	return out.work > 0 && (out.work >= size || m.now().Sub(out.start) > budget || m.API.Pacer.Throttled())
}

// settle records one subscription's outcome. A failure is checkpointed with
// its attempt count and the run moves on; only fatal errors stop the run.
func (m *Migrator) settle(ctx, lctx context.Context, out *chunk, source Subscription, err error) {
	if err == nil {
		out.migrated++
		return
	}
	if errors.Is(err, errCostBlocked) {
		out.costBlocked++
		if !m.costLogged {
			m.costLogged = true
			m.logf("cost cap: %s (%s v%s) and later subscriptions like it are skipped until total_cost <= max_total_cost (last seen %d/%d)", source.ID, source.Type, source.Version, m.API.Cost.Total, m.API.Cost.Max)
		}
		return
	}
	if ctx.Err() != nil || fatal(err) {
		out.fatal = err
		if ctx.Err() != nil {
			out.fatal = ctx.Err()
		}
		return
	}
	progress := m.Checkpoint.Entries[source.ID]
	progress.Attempts++
	progress.LastError = err.Error()
	if saveErr := m.save(source.ID, progress); saveErr != nil {
		out.fatal = saveErr
		return
	}
	out.failed++
	m.logf("FAILED %s (%s v%s, broadcaster %s, attempt %d): %v", source.ID, source.Type, source.Version, conditionUser(source), progress.Attempts, err)
	var uncertain *subscriptionlock.UncertainError
	if errors.As(err, &uncertain) {
		out.uncertain = err
		out.interrupted = true
	}
	if lctx.Err() != nil {
		out.interrupted = true
	}
}
func (out *chunk) stopped() bool { return out.fatal != nil || out.interrupted }

func (m *Migrator) replacement(ctx context.Context, source Subscription, callback, secret string, listing Listing) (Subscription, bool, error) {
	if existing := find(listing.Data, source, callback); existing != nil {
		return *existing, false, nil
	}
	duplicates := 0
	for _, sub := range listing.Data {
		if sub.Type == source.Type && bytes.Equal(canonical(sub.Condition), canonical(source.Condition)) && active(sub.Status) {
			duplicates++
		}
	}
	if duplicates >= 3 {
		return Subscription{}, false, fmt.Errorf("three-per-type/condition limit has no temporary slot; source retained")
	}
	// Cost-0 subscriptions (broadcaster authorized) never count toward the cap.
	if source.Cost > 0 && listing.MaxTotalCost > 0 && listing.TotalCost+source.Cost > listing.MaxTotalCost {
		return Subscription{}, false, fmt.Errorf("insufficient temporary cost headroom (%d + %d > %d); source retained: %w", listing.TotalCost, source.Cost, listing.MaxTotalCost, ErrCostLimit)
	}
	created, err := m.API.Create(ctx, source, callback, secret)
	if err != nil {
		var response *HTTPError
		if errors.As(err, &response) && response.Status == 409 {
			// A 409 proves a duplicate exists, not that it uses our callback or is
			// enabled. Never interpret the conflict as permission to delete source.
			current, listErr := m.API.List(ctx, query(source))
			if listErr != nil {
				return Subscription{}, false, listErr
			}
			if target := find(current.Data, source, callback); target != nil {
				return *target, false, nil
			}
			return Subscription{}, false, fmt.Errorf("409 without matching destination subscription; source retained")
		}
		return Subscription{}, false, err
	}
	if created.ID == "" || !matches(created, source, callback) || !active(created.Status) {
		return Subscription{}, false, fmt.Errorf("creation response does not match intended replacement; source retained")
	}
	return created, true, nil
}
func (m *Migrator) enabled(ctx context.Context, wanted Subscription, callback string) error {
	timeout := m.VerifyTimeout
	if timeout <= 0 {
		timeout = 10 * time.Second
	}
	interval := m.PollInterval
	if interval <= 0 {
		interval = time.Second
	}
	verify, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	for {
		listing, err := m.API.List(verify, url.Values{"subscription_id": {wanted.ID}})
		if err != nil {
			return fmt.Errorf("replacement verification failed: %w", err)
		}
		if current := byID(listing.Data, wanted.ID); current != nil {
			if !matches(*current, wanted, callback) {
				return fmt.Errorf("replacement identity changed")
			}
			if current.Status == "enabled" {
				return nil
			}
			if !active(current.Status) {
				return fmt.Errorf("replacement status %s", current.Status)
			}
		}
		if err = m.API.sleep(verify, interval); err != nil {
			return fmt.Errorf("replacement did not become enabled: %w", err)
		}
	}
}

// forwardChunk migrates up to one chunk of a broadcaster's subscriptions:
//
//  1. list the broadcaster's subscriptions once;
//  2. for each source, accept an existing destination or create one
//     (make-before-break), or set it aside for break-before-make;
//  3. poll the broadcaster's listing until the new destinations are enabled,
//     re-check each source's identity in that listing, and delete it;
//  4. run the set-aside break-before-make migrations one at a time.
func (m *Migrator) forwardChunk(ctx, lctx context.Context, out *chunk, allowed int) {
	out.start = m.now()
	subs := out.rest
	listing, err := m.API.List(lctx, query(subs[0]))
	if err != nil {
		out.rest, out.work = subs[1:], 1
		m.settle(ctx, lctx, out, subs[0], err)
		out.interrupted = true
		return
	}
	type move struct{ source, target Subscription }
	var moves []move
	var swaps []Subscription
	i := 0
	for ; i < len(subs) && !out.stopped() && !m.chunkFull(out, allowed); i++ {
		source := subs[i]
		target, swap, err := m.prepare(lctx, source, listing)
		if !errors.Is(err, errCostBlocked) {
			out.work++
		}
		switch {
		case err != nil:
			m.settle(ctx, lctx, out, source, err)
		case swap:
			swaps = append(swaps, source)
		default:
			moves = append(moves, move{source, target})
		}
	}
	out.rest = subs[i:]
	if out.fatal != nil {
		return
	}
	if len(moves) > 0 && lctx.Err() == nil {
		targets := make([]Subscription, len(moves))
		for j, mv := range moves {
			targets[j] = mv.target
		}
		live, failures := m.awaitEnabled(lctx, query(subs[0]), targets)
		for j, mv := range moves {
			err := failures[j]
			if err == nil {
				err = m.deleteSource(lctx, mv.source, live)
			}
			m.settle(ctx, lctx, out, mv.source, err)
			if out.fatal != nil {
				return
			}
		}
	} else {
		for _, mv := range moves {
			m.settle(ctx, lctx, out, mv.source, fmt.Errorf("lease expired before verification; source retained: %w", lctx.Err()))
		}
	}
	for j, source := range swaps {
		if out.stopped() || (j > 0 && m.now().Sub(out.start) > 2*m.budget()) {
			out.rest = append(append([]Subscription{}, swaps[j:]...), out.rest...)
			out.work -= len(swaps) - j
			return
		}
		m.settle(ctx, lctx, out, source, m.breakBeforeMake(lctx, source))
	}
}
func (m *Migrator) budget() time.Duration {
	if m.ChunkBudget > 0 {
		return m.ChunkBudget
	}
	return 15 * time.Second
}

// prepare finds or creates the replacement for source, or reports that it
// needs break-before-make.
func (m *Migrator) prepare(ctx context.Context, source Subscription, listing Listing) (Subscription, bool, error) {
	progress := m.Checkpoint.Entries[source.ID]
	current := byID(listing.Data, m.liveID(source))
	if current != nil && !matches(*current, source, source.Transport.Callback) {
		return Subscription{}, false, fmt.Errorf("source no longer matches backed-up descriptor")
	}
	// A destination already at TargetCallback is the replacement, whether an
	// earlier run of this command created it or the agent's own subscribe did
	// (since 2026-10-23 it creates subscriptions directly at TargetCallback).
	// Both sign with twitch-eventsub-secret, the secret the agent verifies
	// with and the same value the legacy callback's deliveries are verified
	// with after forwarding, so the destination is known to be compatible.
	if existing := find(listing.Data, source, TargetCallback); existing != nil {
		progress.TargetID = existing.ID
		progress.Created = progress.Created || !m.originalID(existing.ID)
		if err := m.save(source.ID, progress); err != nil {
			return Subscription{}, false, err
		}
		return *existing, false, nil
	}
	if progress.SourceDeleted && current == nil {
		// Crashed after deleting the source and before its replacement
		// existed: finish the break-before-make.
		return Subscription{}, true, nil
	}
	cost := source.Cost
	if current != nil {
		cost = current.Cost
	}
	total, max := listing.TotalCost, listing.MaxTotalCost
	if m.API.Cost.Known {
		total, max = m.API.Cost.Total, m.API.Cost.Max
	}
	if cost > 0 && max > 0 && total+cost > max {
		// No room to create first. Deleting first only helps if the freed cost
		// makes room; while the client is over its cap it does not.
		if current != nil && !roomAfterSwap(total, max, cost) {
			return Subscription{}, false, errCostBlocked
		}
		return Subscription{}, true, nil
	}
	sized := source
	sized.Cost = cost
	listing.TotalCost, listing.MaxTotalCost = total, max
	target, created, err := m.replacement(ctx, sized, TargetCallback, m.Secret, listing)
	if errors.Is(err, ErrCostLimit) {
		return Subscription{}, true, nil
	}
	if err != nil {
		return Subscription{}, false, err
	}
	progress.TargetID = target.ID
	progress.Created = progress.Created || created || !m.originalID(target.ID)
	if err = m.save(source.ID, progress); err != nil {
		return Subscription{}, false, fmt.Errorf("replacement exists but checkpoint failed; source retained: %w", err)
	}
	return target, false, nil
}

// awaitEnabled polls the broadcaster's listing until every target is enabled
// or has failed, returning the final listing and a per-target error.
func (m *Migrator) awaitEnabled(ctx context.Context, q url.Values, targets []Subscription) (Listing, []error) {
	timeout := m.VerifyTimeout
	if timeout <= 0 {
		timeout = 10 * time.Second
	}
	interval := m.PollInterval
	if interval <= 0 {
		interval = time.Second
	}
	verify, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	failures := make([]error, len(targets))
	resolved := make([]bool, len(targets))
	for {
		listing, err := m.API.List(verify, q)
		if err != nil {
			for j := range targets {
				if !resolved[j] {
					failures[j] = fmt.Errorf("replacement verification failed; source retained: %w", err)
				}
			}
			return listing, failures
		}
		left := 0
		for j, target := range targets {
			if resolved[j] {
				continue
			}
			current := byID(listing.Data, target.ID)
			switch {
			case current == nil:
				left++
			case !matches(*current, target, TargetCallback):
				resolved[j], failures[j] = true, fmt.Errorf("replacement identity changed; source retained")
			case current.Status == "enabled":
				resolved[j] = true
			case !active(current.Status):
				resolved[j], failures[j] = true, fmt.Errorf("replacement status %s; source retained", current.Status)
			default:
				left++
			}
		}
		if left == 0 {
			return listing, failures
		}
		if err = m.API.sleep(verify, interval); err != nil {
			for j := range targets {
				if !resolved[j] {
					failures[j] = fmt.Errorf("replacement did not become enabled; source retained: %w", err)
				}
			}
			return listing, failures
		}
	}
}

// deleteSource deletes the legacy source once its replacement is enabled,
// re-checking its identity in a listing taken after verification; IDs and
// descriptors are checked, so neither unrelated callbacks nor new IDs are
// deleted.
func (m *Migrator) deleteSource(ctx context.Context, source Subscription, live Listing) error {
	id := m.liveID(source)
	if current := byID(live.Data, id); current != nil {
		if !matches(*current, source, source.Transport.Callback) {
			return fmt.Errorf("source changed before deletion")
		}
		if err := m.API.Delete(ctx, id); err != nil {
			return err
		}
	}
	progress := m.Checkpoint.Entries[source.ID]
	progress.DeletedOld, progress.SourceDeleted, progress.LastError = true, false, ""
	return m.save(source.ID, progress)
}

// breakBeforeMake migrates a subscription that cannot get a temporary
// replacement because the client is at its EventSub cost cap: delete the
// source to free its cost, then immediately create the replacement. The
// deletion is checkpointed first, so a crash in between is finished on
// resume. If the replacement fails, the source is recreated at its legacy
// callback.
func (m *Migrator) breakBeforeMake(ctx context.Context, source Subscription) error {
	progress := m.Checkpoint.Entries[source.ID]
	id := m.liveID(source)
	live, err := m.API.List(ctx, url.Values{"subscription_id": {id}})
	if err != nil {
		return err
	}
	if current := byID(live.Data, id); current != nil {
		if !matches(*current, source, source.Transport.Callback) {
			return fmt.Errorf("source changed before deletion")
		}
		if !roomAfterSwap(live.TotalCost, live.MaxTotalCost, current.Cost) {
			return errCostBlocked
		}
		progress.SourceDeleted = true
		if err = m.save(source.ID, progress); err != nil {
			return err
		}
		if err = m.API.Delete(ctx, id); err != nil {
			return err
		}
	}
	created, err := m.API.Create(ctx, source, TargetCallback, m.Secret)
	if err == nil && (created.ID == "" || !matches(created, source, TargetCallback) || !active(created.Status)) {
		err = fmt.Errorf("creation response does not match intended replacement")
	}
	if err == nil {
		progress.TargetID, progress.Created = created.ID, true
		if err = m.save(source.ID, progress); err != nil {
			return err
		}
		if err = m.enabled(ctx, created, TargetCallback); err != nil {
			return m.restore(ctx, source, source.Transport.Callback, created.ID, err)
		}
		progress.DeletedOld, progress.SourceDeleted, progress.LastError = true, false, ""
		return m.save(source.ID, progress)
	}
	return m.restore(ctx, source, source.Transport.Callback, "", err)
}

// restore recreates a deleted subscription at callback after its replacement
// failed. A replacement that exists but never became enabled is removed first
// so it does not hold the cost the restore needs.
func (m *Migrator) restore(ctx context.Context, source Subscription, callback, failedID string, cause error) error {
	if fatal(cause) {
		return cause
	}
	// Restore even if the lease or invocation deadline is what failed.
	restoreCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 30*time.Second)
	defer cancel()
	if failedID != "" {
		m.API.Delete(restoreCtx, failedID)
	}
	restored, err := m.API.Create(restoreCtx, source, callback, m.RestoreSecret)
	if err == nil && (restored.ID == "" || !matches(restored, source, callback)) {
		err = fmt.Errorf("restore response does not match")
	}
	if err != nil {
		return fmt.Errorf("replacement failed after deleting the subscription, and recreating it at %s failed (%v); resume will retry: %w", callback, err, cause)
	}
	progress := m.Checkpoint.Entries[source.ID]
	progress.RestoredID, progress.SourceDeleted = restored.ID, false
	if saveErr := m.save(source.ID, progress); saveErr != nil {
		return saveErr
	}
	return fmt.Errorf("replacement failed after deleting the subscription; recreated it at %s as %s: %w", callback, restored.ID, cause)
}

func (m *Migrator) rollbackChunk(ctx, lctx context.Context, out *chunk, allowed int) {
	out.start = m.now()
	subs := out.rest
	i := 0
	for ; i < len(subs) && !out.stopped() && !m.chunkFull(out, allowed); i++ {
		err := m.rollback(lctx, subs[i])
		if !errors.Is(err, errCostBlocked) {
			out.work++
		}
		m.settle(ctx, lctx, out, subs[i], err)
	}
	out.rest = subs[i:]
}
func (m *Migrator) owned(listing Listing, source Subscription) []Subscription {
	var owned []Subscription
	for _, sub := range listing.Data {
		if matches(sub, source, TargetCallback) && !m.originalID(sub.ID) {
			owned = append(owned, sub)
		}
	}
	return owned
}
func (m *Migrator) rollback(ctx context.Context, source Subscription) error {
	listing, err := m.API.List(ctx, query(source))
	if err != nil {
		return err
	}
	progress := m.Checkpoint.Entries[source.ID]
	owned := m.owned(listing, source)
	if !progress.Created && !progress.DeletedOld && !progress.SourceDeleted && len(owned) == 0 {
		// No evidence that this migration touched the descriptor. Do not resurrect
		// an original that disappeared independently after the backup.
		progress.RolledBack = true
		return m.save(source.ID, progress)
	}
	destination, _, err := m.replacement(ctx, source, source.Transport.Callback, m.Secret, listing)
	if errors.Is(err, ErrCostLimit) {
		return m.rollbackBreakFirst(ctx, source, listing, owned)
	}
	if err != nil {
		return err
	}
	if err = m.enabled(ctx, destination, source.Transport.Callback); err != nil {
		return err
	}
	// Only replacements absent from the original backup are rollback-owned.
	// A destination that predated this migration must be preserved.
	for _, sub := range owned {
		if err = m.deleteOwned(ctx, sub, source); err != nil {
			return err
		}
	}
	progress = m.Checkpoint.Entries[source.ID]
	progress.RolledBack = true
	return m.save(source.ID, progress)
}
func (m *Migrator) deleteOwned(ctx context.Context, sub, source Subscription) error {
	live, err := m.API.List(ctx, url.Values{"subscription_id": {sub.ID}})
	if err != nil {
		return err
	}
	current := byID(live.Data, sub.ID)
	if current == nil {
		return nil
	}
	if !matches(*current, source, TargetCallback) {
		return fmt.Errorf("rollback source identity changed")
	}
	return m.API.Delete(ctx, sub.ID)
}

// rollbackBreakFirst is break-before-make in reverse, for a migrated
// subscription with no cost headroom to restore the legacy one first.
func (m *Migrator) rollbackBreakFirst(ctx context.Context, source Subscription, listing Listing, owned []Subscription) error {
	if len(owned) == 0 {
		return fmt.Errorf("no cost headroom and no migration-owned replacement to free it; legacy not restored: %w", ErrCostLimit)
	}
	freed := 0
	for _, sub := range owned {
		freed += sub.Cost
	}
	if listing.MaxTotalCost > 0 && listing.TotalCost-freed+1 > listing.MaxTotalCost {
		return errCostBlocked
	}
	progress := m.Checkpoint.Entries[source.ID]
	progress.SourceDeleted = true
	if err := m.save(source.ID, progress); err != nil {
		return err
	}
	for _, sub := range owned {
		if err := m.deleteOwned(ctx, sub, source); err != nil {
			return err
		}
	}
	created, err := m.API.Create(ctx, source, source.Transport.Callback, m.Secret)
	if err == nil && (created.ID == "" || !matches(created, source, source.Transport.Callback)) {
		err = fmt.Errorf("creation response does not match intended legacy subscription")
	}
	if err == nil {
		if err = m.enabled(ctx, created, source.Transport.Callback); err != nil {
			return m.restore(ctx, source, TargetCallback, created.ID, err)
		}
		progress = m.Checkpoint.Entries[source.ID]
		progress.RolledBack, progress.SourceDeleted = true, false
		return m.save(source.ID, progress)
	}
	return m.restore(ctx, source, TargetCallback, "", err)
}

// VerifyCompleted audits every checkpointed destination against live state.
// A completed checkpoint never substitutes for provider health verification.
func (m *Migrator) VerifyCompleted(live []Subscription) error {
	index := make(map[string]Subscription, len(live))
	for _, sub := range live {
		index[sub.ID] = sub
	}
	for _, source := range m.Snapshot.Planned() {
		progress := m.Checkpoint.Entries[source.ID]
		if !progress.DeletedOld || progress.RolledBack {
			continue
		}
		target, ok := index[progress.TargetID]
		if !ok || !matches(target, source, TargetCallback) || target.Status != "enabled" {
			return fmt.Errorf("completed destination %s is missing, changed, or not enabled; do not retire legacy receiver", progress.TargetID)
		}
	}
	return nil
}
