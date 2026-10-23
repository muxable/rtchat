package subscriptions

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

type fakeClock struct {
	mu  sync.Mutex
	now time.Time
}

func (c *fakeClock) Now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.now
}
func (c *fakeClock) Advance(d time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.now = c.now.Add(d)
}

// testQueue runs the worker against server without Firestore leases. Its
// clock starts at the real time so Ratelimit-Reset headers stay meaningful.
func testQueue(server *httptest.Server) (*TwitchQueue, *fakeClock) {
	clock := &fakeClock{now: time.Now()}
	service := &Service{TwitchSecret: "dedicated-secret", API: &API{Tokens: fakeTokens{}, Client: server.Client(), TwitchURL: server.URL}}
	queue := NewTwitchQueue(service)
	queue.now = clock.Now
	queue.lock = func(ctx context.Context, _ string, work func(context.Context) error) error { return work(ctx) }
	service.Queue = queue
	return queue, clock
}

// drain steps the worker, skipping the fake clock over every wait, and returns
// the total time waited.
func drain(t *testing.T, queue *TwitchQueue, clock *fakeClock) time.Duration {
	t.Helper()
	var waited time.Duration
	for i := 0; i < 100; i++ {
		if queue.depth() == 0 {
			return waited
		}
		delay := queue.step(context.Background())
		clock.Advance(delay)
		waited += delay
	}
	t.Fatal("queue did not drain")
	return waited
}

// fakeEventSub keeps created subscriptions and lets tests reject POSTs.
type fakeEventSub struct {
	mu    sync.Mutex
	state []twitchSubscription
	gets  int
	posts map[string]int
	reply func(w http.ResponseWriter, kind string, attempt int) bool
}

func (f *fakeEventSub) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.posts == nil {
		f.posts = map[string]int{}
	}
	if r.Method == http.MethodGet {
		f.gets++
		json.NewEncoder(w).Encode(map[string]interface{}{"data": append([]twitchSubscription{}, f.state...)})
		return
	}
	var body struct {
		Type, Version string
		Condition     map[string]string
	}
	json.NewDecoder(r.Body).Decode(&body)
	f.posts[body.Type]++
	if f.reply != nil && f.reply(w, body.Type, f.posts[body.Type]) {
		return
	}
	f.create(body.Type, body.Version, body.Condition)
	w.WriteHeader(202)
}
func (f *fakeEventSub) create(kind, version string, condition map[string]string) {
	sub := twitchSubscription{ID: fmt.Sprint(len(f.state)), Type: kind, Version: version, Status: "webhook_callback_verification_pending", Condition: condition}
	sub.Transport.Method, sub.Transport.Callback = "webhook", TwitchCallback
	f.state = append(f.state, sub)
}

func TestTwitchQueueDedupesPendingBroadcasters(t *testing.T) {
	fake := &fakeEventSub{}
	server := httptest.NewServer(fake)
	defer server.Close()
	queue, clock := testQueue(server)
	queue.capacity = 2
	for _, channel := range []string{"123", "123", "456", "123", "789"} {
		queue.Enqueue(channel)
	}
	if queue.depth() != 2 || queue.pending["789"] != nil {
		t.Fatal("expected one item per broadcaster and a full queue to drop", queue.pending)
	}
	drain(t, queue, clock)
	if fake.gets != 2 || len(fake.state) != 54 {
		t.Fatal(fake.gets, len(fake.state))
	}
}

func TestTwitchQueueWaitsForRateLimitReset(t *testing.T) {
	fake := &fakeEventSub{}
	server := httptest.NewServer(fake)
	defer server.Close()
	queue, clock := testQueue(server)
	reset := strconv.FormatInt(clock.Now().Add(2*time.Minute).Unix(), 10)
	later := strconv.FormatInt(clock.Now().Add(4*time.Minute).Unix(), 10)
	fake.reply = func(w http.ResponseWriter, kind string, attempt int) bool {
		switch {
		case kind == "channel.cheer" && attempt == 1:
			// Another replica spent the shared bucket.
			w.Header().Set("Ratelimit-Remaining", "0")
			w.Header().Set("Ratelimit-Reset", reset)
			w.WriteHeader(429)
			return true
		case kind == "channel.raid" && attempt == 1:
			// The queue stops short of the reserve left for user-facing calls.
			w.Header().Set("Ratelimit-Remaining", "50")
			w.Header().Set("Ratelimit-Reset", later)
		}
		return false
	}
	queue.Enqueue("123")
	if delay := queue.step(context.Background()); delay != 0 {
		t.Fatal(delay)
	}
	if queue.depth() != 1 || fake.posts["channel.raid"] != 0 {
		t.Fatal("rate-limited item not kept", queue.depth(), fake.posts)
	}
	waited := drain(t, queue, clock)
	if waited < 3*time.Minute {
		t.Fatal("did not wait for Ratelimit-Reset", waited)
	}
	if fake.posts["channel.cheer"] != 2 || len(fake.state) != 27 {
		t.Fatal(fake.posts, len(fake.state))
	}
	for kind, count := range fake.posts {
		if kind != "channel.cheer" && kind != "channel.raid" && count != 1 {
			t.Fatal("created twice", kind, count)
		}
	}
	// channel.raid has two conditions: the first left a low budget, so the
	// second waited for the next reset.
	if fake.posts["channel.raid"] != 2 {
		t.Fatal(fake.posts["channel.raid"])
	}
}

func TestTwitchQueueHoldsCostLimitedTypesUntilHeadroom(t *testing.T) {
	fake := &fakeEventSub{}
	var mu sync.Mutex
	full := true
	checks := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		defer mu.Unlock()
		if r.Method == http.MethodGet && r.URL.Query().Get("first") == "1" {
			checks++
			cost := 10000
			if !full {
				cost = 9990
			}
			fmt.Fprintf(w, `{"data":[],"total":180000,"total_cost":%d,"max_total_cost":10000}`, cost)
			return
		}
		fake.ServeHTTP(w, r)
	}))
	defer server.Close()
	fake.reply = func(w http.ResponseWriter, kind string, _ int) bool {
		if kind != "stream.online" || !full {
			return false
		}
		w.Header().Set("Ratelimit-Remaining", "700")
		w.WriteHeader(429)
		fmt.Fprint(w, `{"error":"Too Many Requests","status":429,"message":"subscription limit exceeded"}`)
		return true
	}
	queue, clock := testQueue(server)
	queue.Enqueue("123")
	queue.step(context.Background())
	if queue.depth() != 1 || len(fake.state) != 26 {
		t.Fatal("cost-limited item not held", queue.depth(), len(fake.state))
	}
	// Twitch still reports no headroom: the item stays held.
	delay := queue.step(context.Background())
	if delay != twitchCostCheckInterval {
		t.Fatal(delay)
	}
	clock.Advance(delay)
	if delay := queue.step(context.Background()); delay != twitchCostCheckInterval {
		t.Fatal(delay)
	}
	mu.Lock()
	if checks != 1 || fake.posts["stream.online"] != 1 || queue.depth() != 1 {
		t.Fatal(checks, fake.posts["stream.online"], queue.depth())
	}
	full = false
	mu.Unlock()
	drain(t, queue, clock)
	if checks != 2 || fake.posts["stream.online"] != 2 || len(fake.state) != 27 {
		t.Fatal(checks, fake.posts["stream.online"], len(fake.state))
	}
}

func TestTwitchQueueDropsRejectedTypes(t *testing.T) {
	fake := &fakeEventSub{reply: func(w http.ResponseWriter, kind string, _ int) bool {
		switch {
		case strings.HasPrefix(kind, "channel.hype_train."):
			w.WriteHeader(400)
			fmt.Fprint(w, `{"error":"Bad Request","status":400,"message":"invalid subscription type and version"}`)
		case kind == "channel.subscribe":
			w.WriteHeader(403)
		default:
			return false
		}
		return true
	}}
	server := httptest.NewServer(fake)
	defer server.Close()
	queue, clock := testQueue(server)
	queue.Enqueue("123")
	if waited := drain(t, queue, clock); waited != 0 {
		t.Fatal(waited)
	}
	if fake.posts["channel.hype_train.begin"] != 1 || fake.posts["channel.subscribe"] != 1 {
		t.Fatal("rejected types were retried", fake.posts)
	}
	if len(fake.state) != 23 {
		t.Fatal("types after a rejection were not created", len(fake.state))
	}
}

func TestTwitchQueueListsBeforeRetryingUncertainPost(t *testing.T) {
	fake := &fakeEventSub{}
	fake.reply = func(w http.ResponseWriter, kind string, attempt int) bool {
		if kind != "channel.cheer" || attempt != 1 {
			return false
		}
		// Twitch created the subscription but the response was lost.
		fake.create(kind, "1", map[string]string{"broadcaster_user_id": "123"})
		w.WriteHeader(503)
		return true
	}
	server := httptest.NewServer(fake)
	defer server.Close()
	queue, clock := testQueue(server)
	queue.Enqueue("123")
	if waited := drain(t, queue, clock); waited < 90*time.Second {
		t.Fatal("retried within the uncertain lease", waited)
	}
	if fake.gets != 2 || fake.posts["channel.cheer"] != 1 || len(fake.state) != 27 {
		t.Fatal(fake.gets, fake.posts["channel.cheer"], len(fake.state))
	}
}

func TestTwitchQueueGivesUpAfterRepeatedFailures(t *testing.T) {
	var gets atomic.Int32
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gets.Add(1)
		w.WriteHeader(401)
	}))
	defer server.Close()
	queue, clock := testQueue(server)
	queue.Enqueue("123")
	if waited := drain(t, queue, clock); waited < 15*time.Minute {
		t.Fatal("retries did not back off", waited)
	}
	if gets.Load() != twitchMaxAttempts {
		t.Fatal(gets.Load())
	}
}

func TestTwitchQueueRunStopsOnCancel(t *testing.T) {
	fake := &fakeEventSub{}
	server := httptest.NewServer(fake)
	defer server.Close()
	queue, _ := testQueue(server)
	queue.now = time.Now
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan struct{})
	go func() { queue.Run(ctx); close(done) }()
	queue.Enqueue("123")
	deadline := time.Now().Add(5 * time.Second)
	for {
		fake.mu.Lock()
		created := len(fake.state)
		fake.mu.Unlock()
		if created == 27 {
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("worker did not wake for an enqueue", created)
		}
		time.Sleep(10 * time.Millisecond)
	}
	cancel()
	select {
	case <-done:
	case <-time.After(5 * time.Second):
		t.Fatal("worker did not stop")
	}
}

func TestTwitchPaginationPreflightsAllLegacyCallbacks(t *testing.T) {
	gets := 0
	mutations := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			mutations++
			w.WriteHeader(202)
			return
		}
		gets++
		if r.URL.Query().Get("after") == "" {
			fmt.Fprint(w, `{"data":[],"pagination":{"cursor":"next"}}`)
			return
		}
		fmt.Fprint(w, `{"data":[{"id":"legacy","type":"stream.offline","version":"1","status":"enabled","condition":{"broadcaster_user_id":"123"},"transport":{"method":"webhook","callback":"https://legacy.example/eventsub"}}]}`)
	}))
	defer server.Close()
	queue, clock := testQueue(server)
	queue.Enqueue("123")
	drain(t, queue, clock)
	if gets != 2 || mutations != 0 {
		t.Fatal(gets, mutations)
	}
}

func TestTwitchLegacyFunctionCallbackCountsAsPresent(t *testing.T) {
	var subs []map[string]interface{}
	for i, wanted := range twitchConditions("123") {
		subs = append(subs, map[string]interface{}{"id": fmt.Sprint("legacy-", i), "type": wanted.Type, "version": wanted.Version, "status": "enabled", "condition": wanted.Condition, "transport": map[string]string{"method": "webhook", "callback": LegacyTwitchCallback}})
	}
	list, err := json.Marshal(map[string]interface{}{"data": subs})
	if err != nil {
		t.Fatal(err)
	}
	mutations := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			mutations++
			w.WriteHeader(202)
			return
		}
		w.Write(list)
	}))
	defer server.Close()
	queue, clock := testQueue(server)
	queue.Enqueue("123")
	drain(t, queue, clock)
	if mutations != 0 {
		t.Fatal("changed subscriptions that the legacy function forwards", mutations)
	}
}
