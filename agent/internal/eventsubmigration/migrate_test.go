package eventsubmigration

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"sort"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"
)

type fixture struct {
	mu                                            sync.Mutex
	subscriptions                                 map[string]Subscription
	posts, deletes                                int
	conflict, conflictCreates, ambiguous, pending bool
	maxCost, totalCost                            int
	// dynamicCost computes total_cost from active subscriptions and rejects
	// creations over max_total_cost with Twitch's cost-limit 429.
	dynamicCost                 bool
	createCost                  int
	getFailures, deleteFailures int
	bodies                      []json.RawMessage
	secrets                     map[string]string
	// reject, when set, returns an HTTP status for a creation instead of
	// creating it.
	reject func(callback string, condition json.RawMessage) int
}

func source(id, kind, version, condition string) Subscription {
	return Subscription{ID: id, Type: kind, Version: version, Condition: json.RawMessage(condition), Status: "enabled", Cost: 1, Transport: Transport{Method: "webhook", Callback: LegacyCallback}}
}
func (f *fixture) total() int {
	if !f.dynamicCost {
		return f.totalCost
	}
	total := 0
	for _, sub := range f.subscriptions {
		if active(sub.Status) {
			total += sub.Cost
		}
	}
	return total
}
func (f *fixture) serve(w http.ResponseWriter, r *http.Request) {
	f.mu.Lock()
	defer f.mu.Unlock()
	switch r.Method {
	case http.MethodGet:
		if f.getFailures > 0 {
			f.getFailures--
			w.WriteHeader(503)
			return
		}
		data := []Subscription{}
		ids := []string{}
		for id := range f.subscriptions {
			ids = append(ids, id)
		}
		sort.Strings(ids)
		for _, id := range ids {
			if wanted := r.URL.Query().Get("subscription_id"); wanted != "" && wanted != id {
				continue
			}
			data = append(data, f.subscriptions[id])
		}
		json.NewEncoder(w).Encode(Listing{Data: data, TotalCost: f.total(), MaxTotalCost: f.maxCost})
	case http.MethodPost:
		f.posts++
		var body struct {
			Type, Version string
			Condition     json.RawMessage
			Transport     struct{ Method, Callback, Secret string }
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			w.WriteHeader(400)
			return
		}
		if body.Transport.Secret == "" {
			w.WriteHeader(400)
			return
		}
		if f.reject != nil {
			if status := f.reject(body.Transport.Callback, body.Condition); status != 0 {
				w.WriteHeader(status)
				return
			}
		}
		if f.dynamicCost && f.createCost > 0 && f.total()+f.createCost > f.maxCost {
			w.Header().Set("Ratelimit-Remaining", "700")
			w.WriteHeader(429)
			json.NewEncoder(w).Encode(map[string]interface{}{"error": "Too Many Requests", "status": 429, "message": "subscription limit exceeded"})
			return
		}
		if f.conflict && !f.conflictCreates {
			w.WriteHeader(409)
			return
		}
		sub := Subscription{ID: "created-" + strconv.Itoa(f.posts), Type: body.Type, Version: body.Version, Condition: body.Condition, Cost: f.createCost, Status: "enabled", Transport: Transport{Method: body.Transport.Method, Callback: body.Transport.Callback}}
		if !f.dynamicCost {
			sub.Cost = 1
		}
		if f.pending {
			sub.Status = "webhook_callback_verification_pending"
		}
		f.subscriptions[sub.ID] = sub
		f.bodies = append(f.bodies, body.Condition)
		if f.secrets == nil {
			f.secrets = map[string]string{}
		}
		f.secrets[sub.ID] = body.Transport.Secret
		if f.conflict {
			w.WriteHeader(409)
			return
		}
		if f.ambiguous {
			w.WriteHeader(500)
			return
		}
		w.WriteHeader(202)
		json.NewEncoder(w).Encode(Listing{Data: []Subscription{sub}})
	case http.MethodDelete:
		f.deletes++
		if f.deleteFailures > 0 {
			f.deleteFailures--
			w.WriteHeader(503)
			return
		}
		id := r.URL.Query().Get("id")
		if _, ok := f.subscriptions[id]; !ok {
			w.WriteHeader(404)
			return
		}
		delete(f.subscriptions, id)
		w.WriteHeader(204)
	default:
		w.WriteHeader(405)
	}
}
func harness(t *testing.T, f *fixture) (*Migrator, *Checkpoint) {
	t.Helper()
	server := httptest.NewServer(http.HandlerFunc(f.serve))
	t.Cleanup(server.Close)
	snapshot := Snapshot{Schema: 1, ClientID: "client", LegacyCallbacks: [2]string{LegacyCallback, AliasCallback}, TargetCallback: TargetCallback, CreatedAt: time.Now().UTC()}
	for _, sub := range f.subscriptions {
		snapshot.Subscriptions = append(snapshot.Subscriptions, sub)
	}
	sort.Slice(snapshot.Subscriptions, func(i, j int) bool { return snapshot.Subscriptions[i].ID < snapshot.Subscriptions[j].ID })
	checkpoint := Checkpoint{SnapshotHash: snapshot.hash(), Entries: map[string]Progress{}}
	migrator := &Migrator{API: &API{Client: server.Client(), BaseURL: server.URL, ClientID: "client", Token: "token", Pause: func(ctx context.Context, _ time.Duration) error { return ctx.Err() }}, Snapshot: snapshot, Checkpoint: checkpoint, Secret: "dedicated-secret", RestoreSecret: "legacy-client-secret", VerifyTimeout: 20 * time.Millisecond, PollInterval: time.Millisecond, Lock: func(ctx context.Context, _ string, fn func(context.Context) error) error { return fn(ctx) }}
	migrator.Save = func(id string, progress Progress) error { checkpoint.Entries[id] = progress; return nil }
	return migrator, &checkpoint
}
func mustRun(t *testing.T, m *Migrator, limit int, rollback bool) Summary {
	t.Helper()
	summary, err := m.Run(context.Background(), limit, rollback)
	if err != nil {
		t.Fatal(summary, err)
	}
	return summary
}
func TestForwardPreservesConditionsAndUnrelatedCallbacks(t *testing.T) {
	subs := []Subscription{
		source("incoming", "channel.raid", "1", `{"to_broadcaster_user_id":"123"}`),
		source("outgoing", "channel.raid", "1", `{"from_broadcaster_user_id":"123"}`),
		source("chat", "channel.chat.message", "1", `{"broadcaster_user_id":"123","user_id":"bot"}`),
	}
	f := &fixture{subscriptions: map[string]Subscription{}, maxCost: 100, totalCost: 3}
	for _, sub := range subs {
		f.subscriptions[sub.ID] = sub
	}
	unrelated := source("unrelated", "channel.raid", "1", `{"from_broadcaster_user_id":"123"}`)
	unrelated.Transport.Callback = "https://another.example/events"
	f.subscriptions[unrelated.ID] = unrelated
	m, _ := harness(t, f)
	if s := mustRun(t, m, 2, false); s.Migrated != 2 || s.Remaining != 1 {
		t.Fatal(s)
	}
	if s := mustRun(t, m, 2, false); s.Migrated != 1 || s.AlreadyDone != 2 || s.Remaining != 0 {
		t.Fatal(s)
	}
	if f.posts != 3 || f.deletes != 3 {
		t.Fatal(f.posts, f.deletes)
	}
	if _, ok := f.subscriptions["unrelated"]; !ok {
		t.Fatal("unrelated callback deleted")
	}
	for _, wanted := range subs {
		if find(values(f.subscriptions), wanted, TargetCallback) == nil {
			t.Fatal("descriptor lost", wanted)
		}
	}
	for id, secret := range f.secrets {
		if secret != "dedicated-secret" {
			t.Fatal("replacement signed with wrong secret", id)
		}
	}
	for _, raw := range f.bodies {
		if strings.Contains(string(raw), "secret") {
			t.Fatal("condition changed")
		}
	}
}
func values(subs map[string]Subscription) []Subscription {
	var result []Subscription
	for _, sub := range subs {
		result = append(result, sub)
	}
	return result
}
func Test409RequiresActualMatchingDestination(t *testing.T) {
	for _, creates := range []bool{false, true} {
		t.Run(fmt.Sprint(creates), func(t *testing.T) {
			f := &fixture{subscriptions: map[string]Subscription{"old": source("old", "stream.online", "1", `{"broadcaster_user_id":"123"}`)}, maxCost: 100, conflict: true, conflictCreates: creates}
			m, _ := harness(t, f)
			s := mustRun(t, m, 1, false)
			if creates {
				if s.Migrated != 1 || f.deletes != 1 {
					t.Fatal(s, f.deletes)
				}
			} else if s.Failed != 1 || f.deletes != 0 {
				t.Fatal("unverified conflict deleted source", s)
			}
		})
	}
}
func TestPendingReplacementKeepsOldAndCanResume(t *testing.T) {
	f := &fixture{subscriptions: map[string]Subscription{"old": source("old", "stream.online", "1", `{"broadcaster_user_id":"123"}`)}, maxCost: 100, pending: true}
	m, checkpoint := harness(t, f)
	if s := mustRun(t, m, 1, false); s.Failed != 1 || checkpoint.Entries["old"].Attempts != 1 {
		t.Fatal("pending replacement treated as enabled", s)
	}
	if f.deletes != 0 {
		t.Fatal("source removed before callback verified")
	}
	f.mu.Lock()
	replacement := f.subscriptions["created-1"]
	replacement.Status = "enabled"
	f.subscriptions[replacement.ID] = replacement
	f.mu.Unlock()
	if s := mustRun(t, m, 1, false); s.Migrated != 1 {
		t.Fatal(s)
	}
	if f.posts != 1 || f.deletes != 1 || checkpoint.Entries["old"].LastError != "" {
		t.Fatal(f.posts, f.deletes, checkpoint.Entries["old"])
	}
}
func TestAmbiguousPostAndCheckpointFailureResume(t *testing.T) {
	for _, mode := range []string{"ambiguous", "checkpoint"} {
		t.Run(mode, func(t *testing.T) {
			f := &fixture{subscriptions: map[string]Subscription{"old": source("old", "stream.online", "1", `{"broadcaster_user_id":"123"}`)}, maxCost: 100, ambiguous: mode == "ambiguous"}
			m, _ := harness(t, f)
			if mode == "checkpoint" {
				m.Save = func(string, Progress) error { return fmt.Errorf("disk full") }
				// An unwritable checkpoint stops the whole run.
				if _, err := m.Run(context.Background(), 1, false); err == nil {
					t.Fatal("failure hidden")
				}
			} else if s := mustRun(t, m, 1, false); s.Failed != 1 {
				t.Fatal("failure hidden", s)
			}
			if f.posts != 1 || f.deletes != 0 {
				t.Fatal(f.posts, f.deletes)
			}
			// Restart with only the original durable snapshot and no checkpoint. The
			// actual destination is discovered instead of another POST being issued.
			m.Checkpoint = Checkpoint{SnapshotHash: m.Snapshot.hash(), Entries: map[string]Progress{}}
			m.Save = func(string, Progress) error { return nil }
			f.ambiguous = false
			if s := mustRun(t, m, 1, false); s.Migrated != 1 {
				t.Fatal(s)
			}
			if f.posts != 1 || f.deletes != 1 {
				t.Fatal(f.posts, f.deletes)
			}
		})
	}
}
func TestRollbackRestoresBeforeDeletingOnlyOwnedReplacement(t *testing.T) {
	for _, preexisting := range []bool{false, true} {
		t.Run(fmt.Sprint(preexisting), func(t *testing.T) {
			old := source("old", "stream.online", "1", `{"broadcaster_user_id":"123"}`)
			f := &fixture{subscriptions: map[string]Subscription{"old": old}, maxCost: 100}
			if preexisting {
				next := old
				next.ID = "preexisting"
				next.Transport.Callback = TargetCallback
				f.subscriptions[next.ID] = next
			}
			m, _ := harness(t, f)
			if s := mustRun(t, m, 1, false); s.Migrated != 1 {
				t.Fatal(s)
			}
			if preexisting && f.posts != 0 {
				t.Fatal("preexisting destination not used as the replacement")
			}
			m.Secret, m.RestoreSecret = "legacy-client-secret", "dedicated-secret"
			if s := mustRun(t, m, 1, true); s.Migrated != 1 {
				t.Fatal(s)
			}
			if find(values(f.subscriptions), old, LegacyCallback) == nil {
				t.Fatal("rollback did not restore legacy")
			}
			existing := find(values(f.subscriptions), old, TargetCallback)
			if preexisting && existing == nil {
				t.Fatal("preexisting destination deleted")
			}
			if !preexisting && existing != nil {
				t.Fatal("migration-created destination not removed")
			}
		})
	}
}
func TestPreexistingDestinationIsAcceptedAsReplacement(t *testing.T) {
	for _, when := range []string{"in snapshot", "after snapshot"} {
		t.Run(when, func(t *testing.T) {
			old := source("old", "channel.follow", "2", `{"broadcaster_user_id":"123","moderator_user_id":"123"}`)
			old.Cost = 0
			other := source("other", "channel.cheer", "1", `{"broadcaster_user_id":"123"}`)
			other.Cost = 0
			f := &fixture{subscriptions: map[string]Subscription{old.ID: old, other.ID: other}, maxCost: 10000, totalCost: 11920}
			// The agent's own subscribe created this with twitch-eventsub-secret.
			agent := old
			agent.ID = "agent-created"
			agent.Transport.Callback = TargetCallback
			if when == "in snapshot" {
				f.subscriptions[agent.ID] = agent
			}
			m, checkpoint := harness(t, f)
			if when == "after snapshot" {
				f.subscriptions[agent.ID] = agent
			}
			if s := mustRun(t, m, 0, false); s.Migrated != 2 || s.Failed != 0 || s.Remaining != 0 {
				t.Fatal(s)
			}
			// Only the cost-0 "other" needed a new subscription, despite the
			// client being over its cost cap.
			if f.posts != 1 || f.deletes != 2 {
				t.Fatal(f.posts, f.deletes)
			}
			if _, ok := f.subscriptions["old"]; ok || checkpoint.Entries["old"].TargetID != "agent-created" {
				t.Fatal("legacy source kept", checkpoint.Entries["old"])
			}
			if _, ok := f.subscriptions["agent-created"]; !ok {
				t.Fatal("agent destination deleted")
			}
		})
	}
}
func TestPerSubscriptionFailureIsRecordedAndRunContinues(t *testing.T) {
	f := &fixture{subscriptions: map[string]Subscription{}, maxCost: 100}
	for _, id := range []string{"1", "2", "3"} {
		f.subscriptions["old-"+id] = source("old-"+id, "stream.online", "1", `{"broadcaster_user_id":"`+id+`"}`)
	}
	f.reject = func(callback string, condition json.RawMessage) int {
		if strings.Contains(string(condition), `"2"`) {
			return 403
		}
		return 0
	}
	m, checkpoint := harness(t, f)
	var logs []string
	m.Log = func(format string, args ...interface{}) { logs = append(logs, fmt.Sprintf(format, args...)) }
	s := mustRun(t, m, 0, false)
	if s.Migrated != 2 || s.Failed != 1 || s.Remaining != 1 {
		t.Fatal(s)
	}
	entry := checkpoint.Entries["old-2"]
	if entry.Attempts != 1 || !strings.Contains(entry.LastError, "403") || entry.DeletedOld {
		t.Fatal(entry)
	}
	if _, ok := f.subscriptions["old-2"]; !ok {
		t.Fatal("failed source deleted")
	}
	if len(logs) == 0 || !strings.Contains(strings.Join(logs, "\n"), "old-2") {
		t.Fatal("failure not logged", logs)
	}
	// Retried on later runs until MaxAttempts, then skipped.
	mustRun(t, m, 0, false)
	if s = mustRun(t, m, 0, false); s.Failed != 1 || s.AlreadyDone != 2 || checkpoint.Entries["old-2"].Attempts != 3 {
		t.Fatal(s, checkpoint.Entries["old-2"])
	}
	posts := f.posts
	if s = mustRun(t, m, 0, false); s.SkippedFailed != 1 || s.Failed != 0 || f.posts != posts {
		t.Fatal("exhausted entry retried", s)
	}
	f.reject = nil
	m.RetryFailed = true
	if s = mustRun(t, m, 0, false); s.Migrated != 1 || s.Remaining != 0 || checkpoint.Entries["old-2"].LastError != "" {
		t.Fatal(s, checkpoint.Entries["old-2"])
	}
}
func TestUnauthorizedAppTokenAbortsRun(t *testing.T) {
	f := &fixture{subscriptions: map[string]Subscription{}, maxCost: 100}
	for _, id := range []string{"1", "2"} {
		f.subscriptions["old-"+id] = source("old-"+id, "stream.online", "1", `{"broadcaster_user_id":"`+id+`"}`)
	}
	f.reject = func(string, json.RawMessage) int { return 401 }
	m, checkpoint := harness(t, f)
	s, err := m.Run(context.Background(), 0, false)
	if err == nil || f.posts != 1 || s.Failed != 0 || checkpoint.Entries["old-1"].Attempts != 0 {
		t.Fatal("401 did not abort the run", s, err, f.posts)
	}
}
func TestCostCapUsesBreakBeforeMake(t *testing.T) {
	// At the cap exactly: no room to create first, but deleting frees one.
	online := source("online", "stream.online", "1", `{"broadcaster_user_id":"9"}`)
	offline := source("offline", "stream.offline", "1", `{"broadcaster_user_id":"9"}`)
	f := &fixture{subscriptions: map[string]Subscription{online.ID: online, offline.ID: offline}, maxCost: 2, dynamicCost: true, createCost: 1}
	m, checkpoint := harness(t, f)
	if s := mustRun(t, m, 0, false); s.Migrated != 2 || s.Failed != 0 || s.Remaining != 0 {
		t.Fatal(s)
	}
	if f.posts != 2 || f.deletes != 2 || f.total() != 2 {
		t.Fatal(f.posts, f.deletes, f.total())
	}
	for _, old := range []Subscription{online, offline} {
		if find(values(f.subscriptions), old, TargetCallback) == nil || find(values(f.subscriptions), old, LegacyCallback) != nil {
			t.Fatal("not migrated", old.ID)
		}
		if entry := checkpoint.Entries[old.ID]; !entry.DeletedOld || entry.SourceDeleted {
			t.Fatal(entry)
		}
	}
}
func TestCostCapOverLimitLeavesSourcesUntouched(t *testing.T) {
	online := source("online", "stream.online", "1", `{"broadcaster_user_id":"9"}`)
	authorized := source("authorized", "channel.follow", "2", `{"broadcaster_user_id":"9","moderator_user_id":"9"}`)
	authorized.Cost = 0
	f := &fixture{subscriptions: map[string]Subscription{online.ID: online, authorized.ID: authorized}, maxCost: 10, totalCost: 12}
	m, checkpoint := harness(t, f)
	s := mustRun(t, m, 0, false)
	// Deleting one cost-1 subscription at 12/10 would not make room for its
	// replacement, so it stays; cost-0 subscriptions migrate regardless.
	if s.Migrated != 1 || s.CostBlocked != 1 || s.Failed != 0 || s.Remaining != 1 {
		t.Fatal(s)
	}
	if _, ok := f.subscriptions["online"]; !ok || checkpoint.Entries["online"].Attempts != 0 {
		t.Fatal("cost-blocked source changed", checkpoint.Entries["online"])
	}
	if f.posts != 1 || f.deletes != 1 {
		t.Fatal(f.posts, f.deletes)
	}
}
func TestCostLimit429IsNotRetriedAndKeepsSource(t *testing.T) {
	// Twitch reports the source as cost 0, but its replacement would cost 1
	// (the broadcaster's authorization lapsed) and the client is at its cap.
	follow := source("follow", "channel.follow", "2", `{"broadcaster_user_id":"9","moderator_user_id":"9"}`)
	follow.Cost = 0
	filler := source("filler", "stream.online", "1", `{"broadcaster_user_id":"8"}`)
	filler.Transport.Callback = "https://other.example/callback"
	f := &fixture{subscriptions: map[string]Subscription{follow.ID: follow, filler.ID: filler}, maxCost: 1, dynamicCost: true, createCost: 1}
	m, _ := harness(t, f)
	s := mustRun(t, m, 0, false)
	if s.CostBlocked != 1 || s.Failed != 0 || f.posts != 1 || f.deletes != 0 {
		t.Fatal("cost-limit 429 retried or source deleted without room", s, f.posts, f.deletes)
	}
}
func TestBreakBeforeMakeFailureRestoresSource(t *testing.T) {
	online := source("online", "stream.online", "1", `{"broadcaster_user_id":"9"}`)
	f := &fixture{subscriptions: map[string]Subscription{online.ID: online}, maxCost: 1, dynamicCost: true, createCost: 1}
	f.reject = func(callback string, _ json.RawMessage) int {
		if callback == TargetCallback {
			return 400
		}
		return 0
	}
	m, checkpoint := harness(t, f)
	if s := mustRun(t, m, 0, false); s.Failed != 1 || s.Migrated != 0 {
		t.Fatal(s)
	}
	entry := checkpoint.Entries["online"]
	restored := find(values(f.subscriptions), online, LegacyCallback)
	if restored == nil || entry.RestoredID != restored.ID || entry.SourceDeleted || entry.Attempts != 1 || !strings.Contains(entry.LastError, "recreated") {
		t.Fatal("legacy subscription not restored", entry)
	}
	if f.secrets[restored.ID] != "legacy-client-secret" {
		t.Fatal("restore used the wrong secret")
	}
	if find(values(f.subscriptions), online, TargetCallback) != nil {
		t.Fatal("unexpected destination")
	}
	// A later run migrates the restored subscription in its place.
	f.reject = nil
	if s := mustRun(t, m, 0, false); s.Migrated != 1 {
		t.Fatal(s)
	}
	if find(values(f.subscriptions), online, LegacyCallback) != nil || find(values(f.subscriptions), online, TargetCallback) == nil {
		t.Fatal("restored source not migrated")
	}
}
func TestBreakBeforeMakeResumesAfterCrashBetweenDeleteAndCreate(t *testing.T) {
	for _, mode := range []string{"crash", "restore failed"} {
		t.Run(mode, func(t *testing.T) {
			online := source("online", "stream.online", "1", `{"broadcaster_user_id":"9"}`)
			f := &fixture{subscriptions: map[string]Subscription{online.ID: online}, maxCost: 1, dynamicCost: true, createCost: 1}
			m, checkpoint := harness(t, f)
			if mode == "crash" {
				// The process died after checkpointing and deleting the source.
				checkpoint.Entries["online"] = Progress{SourceDeleted: true}
				m.Checkpoint.Entries["online"] = Progress{SourceDeleted: true}
				delete(f.subscriptions, "online")
			} else {
				f.reject = func(string, json.RawMessage) int { return 400 }
				if s := mustRun(t, m, 0, false); s.Failed != 1 {
					t.Fatal(s)
				}
				if entry := checkpoint.Entries["online"]; !entry.SourceDeleted || entry.RestoredID != "" || !strings.Contains(entry.LastError, "resume will retry") {
					t.Fatal(entry)
				}
				if len(f.subscriptions) != 0 {
					t.Fatal(f.subscriptions)
				}
				f.reject = nil
			}
			deletes := f.deletes
			if s := mustRun(t, m, 0, false); s.Migrated != 1 || s.Remaining != 0 {
				t.Fatal(s)
			}
			if f.deletes != deletes || find(values(f.subscriptions), online, TargetCallback) == nil {
				t.Fatal("replacement not created on resume")
			}
			if entry := checkpoint.Entries["online"]; !entry.DeletedOld || entry.SourceDeleted {
				t.Fatal(entry)
			}
		})
	}
}
func TestRollbackAtCostCapDeletesReplacementFirst(t *testing.T) {
	online := source("online", "stream.online", "1", `{"broadcaster_user_id":"9"}`)
	f := &fixture{subscriptions: map[string]Subscription{online.ID: online}, maxCost: 1, dynamicCost: true, createCost: 1}
	m, _ := harness(t, f)
	if s := mustRun(t, m, 0, false); s.Migrated != 1 {
		t.Fatal(s)
	}
	m.Secret, m.RestoreSecret = "legacy-client-secret", "dedicated-secret"
	if s := mustRun(t, m, 0, true); s.Migrated != 1 || s.Failed != 0 {
		t.Fatal(s)
	}
	if find(values(f.subscriptions), online, LegacyCallback) == nil || find(values(f.subscriptions), online, TargetCallback) != nil {
		t.Fatal("rollback did not swap back", f.subscriptions)
	}
}
func TestRunOrdersByBroadcasterActivity(t *testing.T) {
	f := &fixture{subscriptions: map[string]Subscription{}, maxCost: 100}
	for _, broadcaster := range []string{"old", "new", "unknown", "middle"} {
		for _, kind := range []string{"stream.online", "stream.offline"} {
			id := broadcaster + "-" + kind
			f.subscriptions[id] = source(id, kind, "1", `{"broadcaster_user_id":"`+broadcaster+`"}`)
		}
	}
	m, _ := harness(t, f)
	base := time.Date(2026, 10, 1, 0, 0, 0, 0, time.UTC)
	m.Activity = map[string]time.Time{"old": base, "middle": base.Add(time.Hour), "new": base.Add(2 * time.Hour)}
	var locks []string
	lock := m.Lock
	m.Lock = func(ctx context.Context, key string, fn func(context.Context) error) error {
		locks = append(locks, key)
		return lock(ctx, key, fn)
	}
	mustRun(t, m, 0, false)
	if fmt.Sprint(locks) != "[twitch:new twitch:middle twitch:old twitch:unknown]" {
		t.Fatal("wrong order or lease not shared per broadcaster", locks)
	}
	groups := m.Snapshot.Order(m.Activity)
	if len(groups) != 4 || groups[0].Broadcaster != "new" || len(groups[0].Subscriptions) != 2 || groups[0].Subscriptions[0].ID != "new-stream.offline" {
		t.Fatal(groups)
	}
}
func TestChunkSizeSplitsLargeBroadcaster(t *testing.T) {
	f := &fixture{subscriptions: map[string]Subscription{}, maxCost: 100}
	for i := 0; i < 5; i++ {
		id := fmt.Sprint("sub-", i)
		f.subscriptions[id] = source(id, fmt.Sprint("type.", i), "1", `{"broadcaster_user_id":"1"}`)
	}
	m, _ := harness(t, f)
	m.ChunkSize = 2
	leases := 0
	lock := m.Lock
	m.Lock = func(ctx context.Context, key string, fn func(context.Context) error) error {
		leases++
		return lock(ctx, key, fn)
	}
	if s := mustRun(t, m, 0, false); s.Migrated != 5 || leases != 3 {
		t.Fatal(s, leases)
	}
}
func TestIdempotentDeleteRetries(t *testing.T) {
	f := &fixture{subscriptions: map[string]Subscription{"old": source("old", "stream.online", "1", `{"broadcaster_user_id":"123"}`)}, maxCost: 100, getFailures: 2, deleteFailures: 2}
	m, _ := harness(t, f)
	if s := mustRun(t, m, 1, false); s.Migrated != 1 {
		t.Fatal(s)
	}
	if f.posts != 1 || f.deletes != 3 {
		t.Fatal(f.posts, f.deletes)
	}
	if err := m.API.Delete(context.Background(), "old"); err != nil {
		t.Fatal("404 delete not idempotent", err)
	}
}

func TestRollbackDoesNotResurrectUntouchedSource(t *testing.T) {
	f := &fixture{subscriptions: map[string]Subscription{"old": source("old", "stream.online", "1", `{"broadcaster_user_id":"123"}`)}, maxCost: 100}
	m, _ := harness(t, f)
	delete(f.subscriptions, "old")
	mustRun(t, m, 1, true)
	if f.posts != 0 || f.deletes != 0 {
		t.Fatal("rollback changed untouched descriptor", f.posts, f.deletes)
	}
}
func TestCompletedDestinationsAreAudited(t *testing.T) {
	f := &fixture{subscriptions: map[string]Subscription{"old": source("old", "stream.online", "1", `{"broadcaster_user_id":"123"}`)}, maxCost: 100}
	m, _ := harness(t, f)
	mustRun(t, m, 1, false)
	if err := m.VerifyCompleted(values(f.subscriptions)); err != nil {
		t.Fatal(err)
	}
	sub := f.subscriptions["created-1"]
	sub.Status = "notification_failures_exceeded"
	f.subscriptions[sub.ID] = sub
	if err := m.VerifyCompleted(values(f.subscriptions)); err == nil {
		t.Fatal("revoked completed destination accepted")
	}
}

func TestAliasCallbackMigrationAndExactRollback(t *testing.T) {
	old := source("alias-old", "channel.raid", "1", `{"to_broadcaster_user_id":"123"}`)
	old.Transport.Callback = AliasCallback
	f := &fixture{subscriptions: map[string]Subscription{old.ID: old}, maxCost: 100}
	m, _ := harness(t, f)
	if len(m.Snapshot.Planned()) != 1 {
		t.Fatal("CF-backed alias omitted from plan")
	}
	mustRun(t, m, 1, false)
	if find(values(f.subscriptions), old, TargetCallback) == nil {
		t.Fatal("alias callback not migrated")
	}
	m.Secret, m.RestoreSecret = "legacy-client-secret", "dedicated-secret"
	mustRun(t, m, 1, true)
	if find(values(f.subscriptions), old, AliasCallback) == nil || find(values(f.subscriptions), old, LegacyCallback) != nil {
		t.Fatal("rollback changed original callback")
	}
}

func TestThreePerConditionCapLeavesAllCallbacksIntact(t *testing.T) {
	old := source("old", "stream.online", "1", `{"broadcaster_user_id":"123"}`)
	f := &fixture{subscriptions: map[string]Subscription{old.ID: old}, maxCost: 100}
	for i := 0; i < 2; i++ {
		other := old
		other.ID = fmt.Sprint("other-", i)
		other.Transport.Callback = fmt.Sprintf("https://other-%d.example/callback", i)
		f.subscriptions[other.ID] = other
	}
	m, _ := harness(t, f)
	if s := mustRun(t, m, 1, false); s.Failed != 1 {
		t.Fatal("per-condition cap ignored", s)
	}
	if f.posts != 0 || f.deletes != 0 || len(f.subscriptions) != 3 {
		t.Fatal(f.posts, f.deletes, len(f.subscriptions))
	}
}
