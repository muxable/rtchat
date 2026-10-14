package youtube

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"sync"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type memoryStore struct {
	mu                                       sync.Mutex
	owner                                    string
	expires                                  time.Time
	acquisitions, renewals, releases, writes int
	messages                                 map[string]map[string]interface{}
	online                                   []*time.Time
	writeFailures                            int
	failRenew                                bool
}

func (s *memoryStore) Acquire(ctx context.Context, channel, owner string, now, expires time.Time) (bool, error) {
	if err := ctx.Err(); err != nil {
		return false, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	s.acquisitions++
	if s.owner == owner {
		s.renewals++
		if s.failRenew {
			return false, errors.New("lease unavailable")
		}
	}
	if s.owner != "" && !leaseAvailable(s.owner, owner, s.expires, now) {
		return false, nil
	}
	s.owner, s.expires = owner, expires
	return true, nil
}
func (s *memoryStore) Release(ctx context.Context, channel, owner string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.releases++
	if s.owner == owner {
		s.owner = ""
		s.expires = time.Time{}
	}
	return nil
}
func (s *memoryStore) Create(ctx context.Context, channel, id string, data map[string]interface{}) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	s.writes++
	if s.writeFailures > 0 {
		s.writeFailures--
		return errors.New("transient write failure")
	}
	if s.messages == nil {
		s.messages = make(map[string]map[string]interface{})
	}
	if _, ok := s.messages[id]; ok {
		return status.Error(codes.AlreadyExists, "duplicate")
	}
	s.messages[id] = data
	return nil
}
func (s *memoryStore) SetOnline(ctx context.Context, channel string, at *time.Time) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	s.online = append(s.online, at)
	return nil
}
func testClient(t *testing.T, server *testServer, store Store) *Client {
	t.Helper()
	c, err := newClient("channel", server.Client(), store)
	if err != nil {
		t.Fatal(err)
	}
	c.baseURL = server.URL
	c.minPoll = 20 * time.Millisecond
	c.maxPoll = 20 * time.Millisecond
	c.retryInitial = 10 * time.Millisecond
	c.retryMax = 40 * time.Millisecond
	c.renewInterval = 10 * time.Millisecond
	c.leaseTTL = 100 * time.Millisecond
	c.acquireInterval = 15 * time.Millisecond
	c.pollInterval = time.Hour
	return c
}
func eventually(t *testing.T, predicate func() bool) {
	t.Helper()
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		if predicate() {
			return
		}
		time.Sleep(time.Millisecond)
	}
	t.Fatal("condition did not become true")
}
func closeClient(t *testing.T, c *Client) {
	t.Helper()
	closed := make(chan struct{})
	go func() { c.Close(); close(closed) }()
	select {
	case <-closed:
	case <-time.After(time.Second):
		t.Fatal("Close did not join goroutines")
	}
	select {
	case <-c.done:
	default:
		t.Fatal("reader still running")
	}
	c.Close() // idempotent
}
func TestLeaseLifecycle(t *testing.T) {
	s := &memoryStore{}
	ctx := context.Background()
	now := time.Now()
	acquire := func(owner string, at time.Time, want bool) {
		t.Helper()
		got, err := s.Acquire(ctx, "channel", owner, at, at.Add(time.Minute))
		if err != nil || got != want {
			t.Fatal(got, err)
		}
	}
	acquire("a", now, true)
	acquire("b", now, false)
	acquire("a", now.Add(30*time.Second), true)
	acquire("b", now.Add(61*time.Second), false) // renewed expiry
	acquire("b", now.Add(91*time.Second), true)
	if err := s.Release(ctx, "channel", "a"); err != nil {
		t.Fatal(err)
	}
	acquire("a", now.Add(92*time.Second), false) // old owner cannot release new owner
	if err := s.Release(ctx, "channel", "b"); err != nil {
		t.Fatal(err)
	}
	acquire("a", now.Add(92*time.Second), true)
}
func TestPollingBackoffAndEnd(t *testing.T) {
	initial := htmlFixture(t, `var ytInitialData = `)
	followup := fixture(t, "innertube_get_live_chat.json")
	var mu sync.Mutex
	var initialAt time.Time
	var polls []time.Time
	store := &memoryStore{writeFailures: 1}
	server := newTestServer(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/channel/channel/live":
			io.WriteString(w, `<link rel="canonical" href="https://www.youtube.com/watch?v=abcdefghijk">`)
		case "/live_chat":
			mu.Lock()
			initialAt = time.Now()
			mu.Unlock()
			io.WriteString(w, initial)
		default:
			mu.Lock()
			polls = append(polls, time.Now())
			n := len(polls)
			mu.Unlock()
			switch n {
			case 1, 2:
				w.WriteHeader(429)
			case 3:
				io.WriteString(w, `{bad`)
			case 4:
				w.Write(followup)
			default:
				io.WriteString(w, `{}`)
			}
		}
	}))
	defer server.Close()
	c := testClient(t, server, store)
	c.start()
	defer c.Close()
	eventually(t, func() bool {
		store.mu.Lock()
		defer store.mu.Unlock()
		return len(store.online) >= 2 && store.online[len(store.online)-1] == nil
	})
	closeClient(t, c)
	mu.Lock()
	defer mu.Unlock()
	if len(polls) != 5 {
		t.Fatalf("polls %d", len(polls))
	}
	if polls[0].Sub(initialAt) < 20*time.Millisecond {
		t.Fatal("did not honor initial poll delay")
	}
	for i, want := range []time.Duration{10 * time.Millisecond, 20 * time.Millisecond, 40 * time.Millisecond, 20 * time.Millisecond} {
		if polls[i+1].Sub(polls[i]) < want {
			t.Fatalf("poll %d retried too soon: %v", i+1, polls[i+1].Sub(polls[i]))
		}
	}
	if c.counts.rateLimits.Load() != 2 || c.counts.parseFailures.Load() != 1 || c.counts.skipped.Load() < 2 {
		t.Fatalf("bad counters: 429=%d parse=%d skip=%d", c.counts.rateLimits.Load(), c.counts.parseFailures.Load(), c.counts.skipped.Load())
	}
	store.mu.Lock()
	defer store.mu.Unlock()
	if store.owner != "" || store.renewals == 0 || store.releases != 1 || store.online[0] == nil || len(store.messages) == 0 || store.writes <= len(store.messages) {
		t.Fatalf("incorrect lifecycle: %+v", store)
	}
}
func TestLeaseExclusionTakeoverAndClose(t *testing.T) {
	requests := make(chan struct{}, 100)
	server := newTestServer(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requests <- struct{}{}
		io.WriteString(w, `<html>offline</html>`)
	}))
	defer server.Close()
	store := &memoryStore{}
	a, b := testClient(t, server, store), testClient(t, server, store)
	a.start()
	defer a.Close()
	eventually(t, func() bool {
		store.mu.Lock()
		defer store.mu.Unlock()
		return store.owner == a.owner && len(store.online) > 0
	})
	b.start()
	defer b.Close()
	eventually(t, func() bool { store.mu.Lock(); defer store.mu.Unlock(); return store.acquisitions >= 5 })
	if len(requests) != 1 {
		t.Fatal("contending reader made HTTP requests")
	}
	closeClient(t, a)
	eventually(t, func() bool {
		store.mu.Lock()
		defer store.mu.Unlock()
		return store.owner == b.owner && len(store.online) == 2
	})
	closeClient(t, b)
	if len(requests) != 2 {
		t.Fatal("new owner did not discover")
	}
}
func TestLostLeaseCancelsHTTP(t *testing.T) {
	entered := make(chan struct{}, 1)
	canceled := make(chan struct{}, 1)
	server := newTestServer(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		entered <- struct{}{}
		<-r.Context().Done()
		canceled <- struct{}{}
	}))
	defer server.Close()
	store := &memoryStore{}
	c := testClient(t, server, store)
	c.acquireInterval = time.Hour
	c.start()
	defer c.Close()
	select {
	case <-entered:
	case <-time.After(time.Second):
		t.Fatal("request did not begin")
	}
	store.mu.Lock()
	store.owner = "new-owner"
	store.expires = time.Now().Add(time.Minute)
	store.mu.Unlock()
	select {
	case <-canceled:
	case <-time.After(time.Second):
		t.Fatal("lease loss did not cancel HTTP")
	}
	closeClient(t, c)
	store.mu.Lock()
	defer store.mu.Unlock()
	if store.owner != "new-owner" {
		t.Fatal("released another owner's lease")
	}
}
func TestCloseCancelsBlockedHTTP(t *testing.T) {
	entered := make(chan struct{}, 1)
	server := newTestServer(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { entered <- struct{}{}; <-r.Context().Done() }))
	defer server.Close()
	c := testClient(t, server, &memoryStore{})
	c.start()
	select {
	case <-entered:
	case <-time.After(time.Second):
		t.Fatal("no request")
	}
	closeClient(t, c)
}
func TestDiscoveryBackoffAndOfflineInterval(t *testing.T) {
	var mu sync.Mutex
	var times []time.Time
	server := newTestServer(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		times = append(times, time.Now())
		n := len(times)
		mu.Unlock()
		if n <= 3 {
			w.WriteHeader(503)
			return
		}
		io.WriteString(w, `<html>offline</html>`)
	}))
	defer server.Close()
	c := testClient(t, server, &memoryStore{})
	c.pollInterval = 25 * time.Millisecond
	c.start()
	defer c.Close()
	eventually(t, func() bool { mu.Lock(); defer mu.Unlock(); return len(times) >= 5 })
	closeClient(t, c)
	mu.Lock()
	defer mu.Unlock()
	for i, want := range []time.Duration{10 * time.Millisecond, 20 * time.Millisecond, 40 * time.Millisecond, 25 * time.Millisecond} {
		if times[i+1].Sub(times[i]) < want {
			t.Fatalf("retry %d: %v", i, times[i+1].Sub(times[i]))
		}
	}
}
func TestPollingWithoutActionsAndStreamEnd(t *testing.T) {
	for _, ending := range []string{`{}`, `{"continuationContents":{}}`, `{"continuationContents":{"liveChatContinuation":{}}}`} {
		t.Run(ending, func(t *testing.T) {
			var mu sync.Mutex
			calls := 0
			server := newTestServer(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				mu.Lock()
				calls++
				n := calls
				mu.Unlock()
				if n == 1 {
					io.WriteString(w, `{"continuationContents":{"liveChatContinuation":{"continuations":[{"timedContinuationData":{"continuation":"next","timeoutMs":1}}]}}}`)
				} else {
					io.WriteString(w, ending)
				}
			}))
			defer server.Close()
			c := testClient(t, server, &memoryStore{})
			var page chatPage
			json.Unmarshal([]byte(`{"continuations":[{"reloadContinuationData":{"continuation":"first","timeoutMs":1}}]}`), &page)
			ctx, cancel := context.WithTimeout(context.Background(), time.Second)
			defer cancel()
			c.stream(ctx, "video", "key", "version", page)
			mu.Lock()
			defer mu.Unlock()
			if calls != 2 || ctx.Err() != nil {
				t.Fatal("did not end empty stream", calls, ctx.Err())
			}
		})
	}
}

func TestRenewalErrorStopsReader(t *testing.T) {
	entered := make(chan struct{}, 1)
	canceled := make(chan struct{}, 1)
	server := newTestServer(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		entered <- struct{}{}
		<-r.Context().Done()
		canceled <- struct{}{}
	}))
	defer server.Close()
	store := &memoryStore{failRenew: true}
	c := testClient(t, server, store)
	c.acquireInterval = time.Hour
	c.start()
	defer c.Close()
	select {
	case <-entered:
	case <-time.After(time.Second):
		t.Fatal("request did not begin")
	}
	select {
	case <-canceled:
	case <-time.After(time.Second):
		t.Fatal("renewal error did not cancel reader")
	}
	closeClient(t, c)
	store.mu.Lock()
	defer store.mu.Unlock()
	if store.owner != "" || store.releases != 1 {
		t.Fatal("failed to release lease after renewal error")
	}
}
