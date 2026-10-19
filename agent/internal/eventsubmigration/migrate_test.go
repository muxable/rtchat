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
	getFailures, deleteFailures                   int
	bodies                                        []json.RawMessage
}

func source(id, kind, version, condition string) Subscription {
	return Subscription{ID: id, Type: kind, Version: version, Condition: json.RawMessage(condition), Status: "enabled", Cost: 1, Transport: Transport{Method: "webhook", Callback: LegacyCallback}}
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
		json.NewEncoder(w).Encode(Listing{Data: data, TotalCost: f.totalCost, MaxTotalCost: f.maxCost})
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
		if f.conflict && !f.conflictCreates {
			w.WriteHeader(409)
			return
		}
		sub := Subscription{ID: "created-" + strconv.Itoa(f.posts), Type: body.Type, Version: body.Version, Condition: body.Condition, Cost: 1, Status: "enabled", Transport: Transport{Method: body.Transport.Method, Callback: body.Transport.Callback}}
		if f.pending {
			sub.Status = "webhook_callback_verification_pending"
		}
		f.subscriptions[sub.ID] = sub
		f.bodies = append(f.bodies, body.Condition)
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
	migrator := &Migrator{API: &API{Client: server.Client(), BaseURL: server.URL, ClientID: "client", Token: "token", Pause: func(ctx context.Context, _ time.Duration) error { return ctx.Err() }}, Snapshot: snapshot, Checkpoint: checkpoint, Secret: "dedicated-secret", VerifyTimeout: 20 * time.Millisecond, PollInterval: time.Millisecond, Lock: func(ctx context.Context, _ string, fn func(context.Context) error) error { return fn(ctx) }}
	migrator.Save = func(state Checkpoint) error { checkpoint = state; return nil }
	return migrator, &checkpoint
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
	processed, err := m.Run(context.Background(), 2, false)
	if err != nil || processed != 2 {
		t.Fatal(processed, err)
	}
	processed, err = m.Run(context.Background(), 2, false)
	if err != nil || processed != 1 {
		t.Fatal(processed, err)
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
			_, err := m.Run(context.Background(), 1, false)
			if creates {
				if err != nil || f.deletes != 1 {
					t.Fatal(err, f.deletes)
				}
			} else {
				if err == nil || f.deletes != 0 {
					t.Fatal("unverified conflict deleted source", err)
				}
			}
		})
	}
}
func TestPendingReplacementKeepsOldAndCanResume(t *testing.T) {
	f := &fixture{subscriptions: map[string]Subscription{"old": source("old", "stream.online", "1", `{"broadcaster_user_id":"123"}`)}, maxCost: 100, pending: true}
	m, _ := harness(t, f)
	if _, err := m.Run(context.Background(), 1, false); err == nil {
		t.Fatal("pending replacement treated as enabled")
	}
	if f.deletes != 0 {
		t.Fatal("source removed before callback verified")
	}
	f.mu.Lock()
	replacement := f.subscriptions["created-1"]
	replacement.Status = "enabled"
	f.subscriptions[replacement.ID] = replacement
	f.mu.Unlock()
	if _, err := m.Run(context.Background(), 1, false); err != nil {
		t.Fatal(err)
	}
	if f.posts != 1 || f.deletes != 1 {
		t.Fatal(f.posts, f.deletes)
	}
}
func TestAmbiguousPostAndCheckpointFailureResume(t *testing.T) {
	for _, mode := range []string{"ambiguous", "checkpoint"} {
		t.Run(mode, func(t *testing.T) {
			f := &fixture{subscriptions: map[string]Subscription{"old": source("old", "stream.online", "1", `{"broadcaster_user_id":"123"}`)}, maxCost: 100, ambiguous: mode == "ambiguous"}
			m, _ := harness(t, f)
			if mode == "checkpoint" {
				m.Save = func(Checkpoint) error { return fmt.Errorf("disk full") }
			}
			if _, err := m.Run(context.Background(), 1, false); err == nil {
				t.Fatal("failure hidden")
			}
			if f.posts != 1 || f.deletes != 0 {
				t.Fatal(f.posts, f.deletes)
			}
			// Restart with only the original durable snapshot and no checkpoint. The
			// actual destination is discovered instead of another POST being issued.
			m.Checkpoint = Checkpoint{SnapshotHash: m.Snapshot.hash(), Entries: map[string]Progress{}}
			m.Save = func(Checkpoint) error { return nil }
			f.ambiguous = false
			if _, err := m.Run(context.Background(), 1, false); err != nil {
				t.Fatal(err)
			}
			if f.posts != 1 || f.deletes != 1 {
				t.Fatal(f.posts, f.deletes)
			}
		})
	}
}
func TestCapacityStopsWithoutDeletingSource(t *testing.T) {
	f := &fixture{subscriptions: map[string]Subscription{"old": source("old", "stream.online", "1", `{"broadcaster_user_id":"123"}`)}, maxCost: 10, totalCost: 10}
	m, _ := harness(t, f)
	if _, err := m.Run(context.Background(), 1, false); err == nil {
		t.Fatal("cost limit ignored")
	}
	if f.posts != 0 || f.deletes != 0 {
		t.Fatal(f.posts, f.deletes)
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
			if preexisting {
				if _, err := m.Run(context.Background(), 1, false); err == nil {
					t.Fatal("preexisting destination signing secret assumed compatible")
				}
				if f.posts != 0 || f.deletes != 0 {
					t.Fatal("preexisting signing-secret gate mutated provider")
				}
				// Rollback must leave a destination that predated this command intact.
			} else if _, err := m.Run(context.Background(), 1, false); err != nil {
				t.Fatal(err)
			}
			m.Secret = "legacy-client-secret"
			if _, err := m.Run(context.Background(), 1, true); err != nil {
				t.Fatal(err)
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
func TestIdempotentDeleteRetries(t *testing.T) {
	f := &fixture{subscriptions: map[string]Subscription{"old": source("old", "stream.online", "1", `{"broadcaster_user_id":"123"}`)}, maxCost: 100, getFailures: 2, deleteFailures: 2}
	m, _ := harness(t, f)
	if _, err := m.Run(context.Background(), 1, false); err != nil {
		t.Fatal(err)
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
	if _, err := m.Run(context.Background(), 1, true); err != nil {
		t.Fatal(err)
	}
	if f.posts != 0 || f.deletes != 0 {
		t.Fatal("rollback changed untouched descriptor", f.posts, f.deletes)
	}
}
func TestCompletedDestinationsAreAudited(t *testing.T) {
	f := &fixture{subscriptions: map[string]Subscription{"old": source("old", "stream.online", "1", `{"broadcaster_user_id":"123"}`)}, maxCost: 100}
	m, _ := harness(t, f)
	if _, err := m.Run(context.Background(), 1, false); err != nil {
		t.Fatal(err)
	}
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
	if _, err := m.Run(context.Background(), 1, false); err != nil {
		t.Fatal(err)
	}
	if find(values(f.subscriptions), old, TargetCallback) == nil {
		t.Fatal("alias callback not migrated")
	}
	m.Secret = "legacy-client-secret"
	if _, err := m.Run(context.Background(), 1, true); err != nil {
		t.Fatal(err)
	}
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
	if _, err := m.Run(context.Background(), 1, false); err == nil {
		t.Fatal("per-condition cap ignored")
	}
	if f.posts != 0 || f.deletes != 0 || len(f.subscriptions) != 3 {
		t.Fatal(f.posts, f.deletes, len(f.subscriptions))
	}
}
