package subscriptions

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

// pagedEventSub filters subscriptions like Helix, by user_id or type, and
// pages them.
type pagedEventSub struct {
	mu       sync.Mutex
	state    []twitchSubscription
	pageSize int
	gets     []listQuery
	deleted  []string
	posts    []map[string]interface{}
	// reply may answer a request itself.
	reply func(w http.ResponseWriter, r *http.Request) bool
}

type listQuery struct{ userID, kind, after string }

func (f *pagedEventSub) add(id, kind, status, callback string, condition map[string]string) {
	sub := twitchSubscription{ID: id, Type: kind, Version: "1", Status: status, Condition: condition}
	sub.Transport.Method, sub.Transport.Callback = "webhook", callback
	f.state = append(f.state, sub)
}

func (f *pagedEventSub) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.reply != nil && f.reply(w, r) {
		return
	}
	query := r.URL.Query()
	switch r.Method {
	case http.MethodGet:
		f.gets = append(f.gets, listQuery{query.Get("user_id"), query.Get("type"), query.Get("after")})
		var matched []twitchSubscription
		for _, sub := range f.state {
			match := query.Get("type") == "" || sub.Type == query.Get("type")
			if id := query.Get("user_id"); id != "" {
				found := false
				for _, value := range sub.Condition {
					found = found || value == id
				}
				match = match && found
			}
			if match {
				matched = append(matched, sub)
			}
		}
		start, _ := strconv.Atoi(query.Get("after"))
		size := f.pageSize
		if size == 0 {
			size = 100
		}
		end := start + size
		cursor := strconv.Itoa(end)
		if end >= len(matched) {
			end, cursor = len(matched), ""
		}
		json.NewEncoder(w).Encode(map[string]interface{}{"data": append([]twitchSubscription{}, matched[start:end]...), "pagination": map[string]string{"cursor": cursor}})
	case http.MethodDelete:
		id := query.Get("id")
		for i, sub := range f.state {
			if sub.ID == id {
				f.state = append(f.state[:i], f.state[i+1:]...)
				f.deleted = append(f.deleted, id)
				w.WriteHeader(204)
				return
			}
		}
		w.WriteHeader(404)
	case http.MethodPost:
		var body map[string]interface{}
		json.NewDecoder(r.Body).Decode(&body)
		f.posts = append(f.posts, body)
		condition := map[string]string{}
		for key, value := range body["condition"].(map[string]interface{}) {
			condition[key] = value.(string)
		}
		transport := body["transport"].(map[string]interface{})
		f.add(fmt.Sprint("new-", len(f.posts)), body["type"].(string), "webhook_callback_verification_pending", transport["callback"].(string), condition)
		w.WriteHeader(202)
	}
}

func (f *pagedEventSub) ids() []string {
	f.mu.Lock()
	defer f.mu.Unlock()
	var ids []string
	for _, sub := range f.state {
		ids = append(ids, sub.ID)
	}
	sort.Strings(ids)
	return ids
}

func deauthorizedState() *pagedEventSub {
	f := &pagedEventSub{pageSize: 2}
	f.add("online", "stream.online", "enabled", TwitchCallback, map[string]string{"broadcaster_user_id": "123"})
	f.add("update", "channel.update", "enabled", LegacyTwitchCallback, map[string]string{"broadcaster_user_id": "123"})
	f.add("raid-in", "channel.raid", "enabled", TwitchCallback, map[string]string{"to_broadcaster_user_id": "123"})
	f.add("raid-out", "channel.raid", "enabled", TwitchCallback, map[string]string{"from_broadcaster_user_id": "123"})
	f.add("cheer", "channel.cheer", "authorization_revoked", TwitchCallback, map[string]string{"broadcaster_user_id": "123"})
	// Not ours: another transport, another broadcaster, or a broadcaster the
	// deauthorized user only moderates.
	f.add("foreign", "channel.chat.message", "enabled", "https://other.example/eventsub", map[string]string{"broadcaster_user_id": "123"})
	f.add("other", "stream.online", "enabled", TwitchCallback, map[string]string{"broadcaster_user_id": "456"})
	f.add("moderated", "channel.follow", "enabled", TwitchCallback, map[string]string{"broadcaster_user_id": "456", "moderator_user_id": "123"})
	return f
}

func TestTwitchQueueRemovesOwnSubscriptionsForBroadcaster(t *testing.T) {
	fake := deauthorizedState()
	server := httptest.NewServer(fake)
	defer server.Close()
	queue, clock := testQueue(server)
	queue.EnqueueRemove("123")
	drain(t, queue, clock)
	if got := fmt.Sprint(fake.ids()); got != "[foreign moderated other]" {
		t.Fatal("kept", got)
	}
	sort.Strings(fake.deleted)
	if got := fmt.Sprint(fake.deleted); got != "[cheer online raid-in raid-out update]" {
		t.Fatal("deleted", got)
	}
	// Seven subscriptions name the broadcaster, in pages of two.
	if len(fake.gets) != 4 || fake.gets[0] != (listQuery{"123", "", ""}) || fake.gets[3].after != "6" || len(fake.posts) != 0 {
		t.Fatal(fake.gets, fake.posts)
	}
}

func TestTwitchQueueRemovalKeepsRateLimitReserve(t *testing.T) {
	fake := deauthorizedState()
	clock := &fakeClock{now: time.Now()}
	reset := strconv.FormatInt(clock.Now().Add(2*time.Minute).Unix(), 10)
	low := true
	fake.reply = func(w http.ResponseWriter, r *http.Request) bool {
		if r.Method == http.MethodDelete && low {
			// Another replica spent the shared bucket down to the reserve.
			low = false
			w.Header().Set("Ratelimit-Remaining", strconv.Itoa(twitchBudgetReserve))
			w.Header().Set("Ratelimit-Reset", reset)
		}
		return false
	}
	server := httptest.NewServer(fake)
	defer server.Close()
	queue, _ := testQueue(server)
	queue.now = clock.Now
	queue.EnqueueRemove("123")
	queue.step(context.Background())
	if depth(queue) != 1 || len(fake.deleted) != 1 {
		t.Fatal("removal spent the reserve", depth(queue), fake.deleted)
	}
	if waited := drain(t, queue, clock); waited < 2*time.Minute-time.Second {
		t.Fatal("did not wait for Ratelimit-Reset", waited)
	}
	if len(fake.deleted) != 5 || len(fake.ids()) != 3 {
		t.Fatal(fake.deleted, fake.ids())
	}
}

func TestTwitchQueueRemovalRetriesFailures(t *testing.T) {
	fake := deauthorizedState()
	failed := false
	fake.reply = func(w http.ResponseWriter, r *http.Request) bool {
		if r.Method == http.MethodDelete && !failed {
			failed = true
			w.WriteHeader(500)
			return true
		}
		return false
	}
	server := httptest.NewServer(fake)
	defer server.Close()
	queue, clock := testQueue(server)
	queue.EnqueueRemove("123")
	if waited := drain(t, queue, clock); waited < 90*time.Second {
		t.Fatal("retried within the uncertain lease", waited)
	}
	if len(fake.deleted) != 5 {
		t.Fatal(fake.deleted)
	}
}

func TestTwitchQueueLatestIntentWins(t *testing.T) {
	t.Run("deauthorized after subscribe", func(t *testing.T) {
		fake := deauthorizedState()
		server := httptest.NewServer(fake)
		defer server.Close()
		queue, clock := testQueue(server)
		queue.Enqueue("123")
		queue.EnqueueRemove("123")
		drain(t, queue, clock)
		if len(fake.posts) != 0 || len(fake.deleted) != 5 {
			t.Fatal(fake.posts, fake.deleted)
		}
	})
	t.Run("subscribed after deauthorization", func(t *testing.T) {
		fake := deauthorizedState()
		server := httptest.NewServer(fake)
		defer server.Close()
		queue, clock := testQueue(server)
		queue.EnqueueRemove("123")
		queue.Enqueue("123")
		drain(t, queue, clock)
		// Only the revoked cheer is replaced; nothing enabled is removed.
		if len(fake.deleted) != 1 || fake.deleted[0] != "cheer" || len(fake.posts) == 0 {
			t.Fatal(fake.posts, fake.deleted)
		}
	})
	t.Run("deauthorized during reconcile", func(t *testing.T) {
		fake := deauthorizedState()
		server := httptest.NewServer(fake)
		defer server.Close()
		queue, clock := testQueue(server)
		fake.reply = func(w http.ResponseWriter, r *http.Request) bool {
			if r.Method == http.MethodPost {
				queue.EnqueueRemove("123")
			}
			return false
		}
		queue.Enqueue("123")
		queue.step(context.Background())
		queue.mu.Lock()
		item := queue.pending["123"]
		queue.mu.Unlock()
		if item == nil || item.job != twitchRemoveJob || item.running || item.attempts != 0 {
			t.Fatal("removal lost to the running reconcile", item)
		}
		fake.reply = nil
		drain(t, queue, clock)
		if got := fmt.Sprint(fake.ids()); got != "[foreign moderated other]" {
			t.Fatal("kept", got)
		}
	})
	t.Run("removal while cost limit is full", func(t *testing.T) {
		fake := deauthorizedState()
		server := httptest.NewServer(fake)
		defer server.Close()
		queue, clock := testQueue(server)
		queue.cappedUntil = clock.Now().Add(time.Minute)
		queue.Enqueue("123")
		queue.EnqueueRemove("123")
		if depth(queue) != 1 {
			t.Fatal("removals free cost and must not wait for headroom")
		}
		drain(t, queue, clock)
		if len(fake.deleted) != 5 {
			t.Fatal(fake.deleted)
		}
	})
}

func TestTwitchAppAuthorizationSubscription(t *testing.T) {
	appCondition := map[string]string{"client_id": "client"}
	for _, test := range []struct {
		name    string
		setup   func(*pagedEventSub)
		created bool
		deleted string
	}{
		{name: "missing", created: true},
		{name: "enabled", setup: func(f *pagedEventSub) {
			f.add("app", twitchAppType, "enabled", TwitchCallback, appCondition)
		}},
		{name: "verifying", setup: func(f *pagedEventSub) {
			f.add("app", twitchAppType, "webhook_callback_verification_pending", TwitchCallback, appCondition)
		}},
		{name: "failed", created: true, deleted: "app", setup: func(f *pagedEventSub) {
			f.add("app", twitchAppType, "notification_failures_exceeded", TwitchCallback, appCondition)
		}},
		{name: "other callback or client", created: true, setup: func(f *pagedEventSub) {
			f.add("legacy", twitchAppType, "enabled", LegacyTwitchCallback, appCondition)
			f.add("client", twitchAppType, "enabled", TwitchCallback, map[string]string{"client_id": "other"})
		}},
	} {
		t.Run(test.name, func(t *testing.T) {
			fake := &pagedEventSub{pageSize: 1}
			fake.add("online", "stream.online", "enabled", TwitchCallback, map[string]string{"broadcaster_user_id": "123"})
			if test.setup != nil {
				test.setup(fake)
			}
			server := httptest.NewServer(fake)
			defer server.Close()
			queue, clock := testQueue(server)
			// Two replicas start; the second finds the first's subscription.
			for i := 0; i < 2; i++ {
				queue.enqueue(twitchAppKey, twitchAppJob)
				drain(t, queue, clock)
			}
			if fake.gets[0].kind != twitchAppType {
				t.Fatal("listed without the type filter", fake.gets)
			}
			if test.created != (len(fake.posts) == 1) || len(fake.posts) > 1 {
				t.Fatal("posts", fake.posts)
			}
			if strings.Join(fake.deleted, ",") != test.deleted {
				t.Fatal("deleted", fake.deleted)
			}
			if !test.created {
				return
			}
			body, _ := json.Marshal(fake.posts[0])
			want := `{"condition":{"client_id":"client"},"transport":{"callback":"` + TwitchCallback + `","method":"webhook","secret":"dedicated-secret"},"type":"user.authorization.revoke","version":"1"}`
			if string(body) != want {
				t.Fatal(string(body))
			}
		})
	}
}

func TestTwitchAppAuthorizationWaitsForCostHeadroom(t *testing.T) {
	fake := &pagedEventSub{}
	full := true
	checks := 0
	fake.reply = func(w http.ResponseWriter, r *http.Request) bool {
		switch {
		case r.Method == http.MethodGet && r.URL.Query().Get("first") == "1":
			checks++
			cost := 10000
			if !full {
				cost = 9000
			}
			fmt.Fprintf(w, `{"data":[],"total_cost":%d,"max_total_cost":10000}`, cost)
		case r.Method == http.MethodPost && full:
			w.Header().Set("Ratelimit-Remaining", "700")
			w.WriteHeader(429)
		default:
			return false
		}
		return true
	}
	server := httptest.NewServer(fake)
	defer server.Close()
	queue, clock := testQueue(server)
	queue.enqueue(twitchAppKey, twitchAppJob)
	queue.step(context.Background())
	queue.mu.Lock()
	held := queue.pending[twitchAppKey] != nil && queue.pending[twitchAppKey].costHeld
	queue.mu.Unlock()
	if !held || len(fake.posts) != 0 {
		t.Fatal("cost-limited app subscription not held")
	}
	// Held until a cost check, not retried in a loop.
	if delay := queue.step(context.Background()); delay != twitchCostCheckInterval {
		t.Fatal(delay)
	}
	fake.mu.Lock()
	full = false
	fake.mu.Unlock()
	drain(t, queue, clock)
	if checks != 1 || len(fake.posts) != 1 {
		t.Fatal(checks, fake.posts)
	}
}

func TestTwitchQueueRunEnsuresAppSubscription(t *testing.T) {
	fake := &pagedEventSub{}
	server := httptest.NewServer(fake)
	defer server.Close()
	queue, _ := testQueue(server)
	queue.now = time.Now
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan struct{})
	go func() { queue.Run(ctx); close(done) }()
	defer func() { cancel(); <-done }()
	for deadline := time.Now().Add(5 * time.Second); time.Now().Before(deadline); time.Sleep(10 * time.Millisecond) {
		fake.mu.Lock()
		created := len(fake.posts) == 1 && fake.posts[0]["type"] == twitchAppType
		fake.mu.Unlock()
		if created {
			return
		}
	}
	t.Fatal("worker did not create the app subscription")
}
