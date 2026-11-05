package provider

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

type memoryStore struct {
	mu             sync.Mutex
	encoded, owner string
	until          time.Time
	revoked        bool
}

func (m *memoryStore) Load(context.Context, string, string) (string, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.encoded == "" {
		return "", ErrNoToken
	}
	return m.encoded, nil
}
func (m *memoryStore) Acquire(_ context.Context, lease Lease) (bool, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.encoded != lease.Token || time.Now().Before(m.until) {
		return false, nil
	}
	m.owner = lease.Owner
	m.until = lease.Until
	return true, nil
}
func (m *memoryStore) Finish(_ context.Context, lease Lease, result RefreshResult) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.owner != lease.Owner {
		return ErrRefreshBusy
	}
	m.until = time.Time{}
	if m.encoded == lease.Token {
		if result.Token != "" {
			m.encoded = result.Token
		}
		if result.Revoked {
			m.revoked = true
			m.encoded = ""
		}
	}
	return nil
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }
func newTestService(store Store, transport roundTripFunc) *Service {
	return NewServiceWithStore(store, &http.Client{Transport: transport}, func(context.Context, string) (string, error) { return "secret", nil })
}

const expired = `{"access_token":"old","refresh_token":"refresh-old","expires_at":"2020-01-01T00:00:00.000Z","scope":["chat:read"],"custom":true}`

func response(code int, body string) *http.Response {
	return &http.Response{StatusCode: code, Body: io.NopCloser(strings.NewReader(body)), Header: make(http.Header)}
}

func TestConcurrentRefreshRetainsSchemaAndRotates(t *testing.T) {
	store := &memoryStore{encoded: expired}
	var calls atomic.Int32
	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		calls.Add(1)
		if err := r.ParseForm(); err != nil {
			t.Error(err)
		}
		if r.Form.Get("refresh_token") != "refresh-old" {
			t.Error("wrong refresh token")
		}
		return response(200, `{"access_token":"new","refresh_token":"rotated","expires_in":3600}`), nil
	})
	// Two distinct services represent separate MIG processes sharing the store.
	services := []*Service{newTestService(store, transport), newTestService(store, transport)}
	var wg sync.WaitGroup
	for i := 0; i < 12; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			token, err := services[i%2].AccessToken(context.Background(), "user", "kick")
			if err != nil || token != "new" {
				t.Errorf("%q %v", token, err)
			}
		}(i)
	}
	wg.Wait()
	if calls.Load() != 1 {
		t.Fatalf("refreshed %d times", calls.Load())
	}
	token, err := decodeToken(store.encoded)
	if err != nil {
		t.Fatal(err)
	}
	if tokenString(token, "refresh_token") != "rotated" || token["custom"] != true || token["scope"] == nil || !valid(token) {
		t.Fatalf("schema lost: %s", store.encoded)
	}
}
func TestRefreshRetainsGoogleRefreshToken(t *testing.T) {
	store := &memoryStore{encoded: expired}
	service := newTestService(store, func(r *http.Request) (*http.Response, error) {
		return response(200, `{"access_token":"new","expires_in":3600}`), nil
	})
	if _, err := service.AccessToken(context.Background(), "user", "youtube"); err != nil {
		t.Fatal(err)
	}
	token, _ := decodeToken(store.encoded)
	if tokenString(token, "refresh_token") != "refresh-old" {
		t.Fatal("refresh token lost")
	}
}
func TestRefreshFailurePolicy(t *testing.T) {
	for _, tc := range []struct {
		name    string
		code    int
		body    string
		revoked bool
	}{{"revoked", 400, `{"error":"invalid_grant"}`, true}, {"revoked twitch", 401, `{"message":"Invalid refresh token","secret":"do-not-leak"}`, true}, {"invalid client", 401, `{"error":"invalid_client"}`, false}, {"server-side grant error", 503, `{"error":"invalid_grant"}`, false}, {"temporary", 503, `{"error":"unavailable","secret":"do-not-leak"}`, false}, {"bad JSON", 200, "invalid", false}, {"missing access token", 200, `{"secret":"do-not-leak"}`, false}, {"short expiry", 200, `{"access_token":"new","expires_in":60}`, false}} {
		t.Run(tc.name, func(t *testing.T) {
			store := &memoryStore{encoded: expired}
			calls := 0
			s := newTestService(store, func(r *http.Request) (*http.Response, error) {
				calls++
				return response(tc.code, tc.body), nil
			})
			_, err := s.AccessToken(context.Background(), "user", "kick")
			if calls != 1 || err == nil || strings.Contains(err.Error(), "do-not-leak") || store.revoked != tc.revoked {
				t.Fatalf("err=%v revoked=%v", err, store.revoked)
			}
			if !tc.revoked && store.encoded != expired {
				t.Fatal("transient failure removed token")
			}
		})
	}
}
func TestCallbackWinsRefreshRace(t *testing.T) {
	store := &memoryStore{encoded: expired}
	s := newTestService(store, func(r *http.Request) (*http.Response, error) {
		store.mu.Lock()
		store.encoded = `{"access_token":"callback","expires_at":"2099-01-01T00:00:00Z"}`
		store.mu.Unlock()
		return response(200, `{"access_token":"stale","expires_in":3600}`), nil
	})
	token, err := s.AccessToken(context.Background(), "user", "kick")
	if err != nil || token != "callback" {
		t.Fatalf("callback overwritten: %q %v", token, err)
	}
}
func TestCancelledLeaseWait(t *testing.T) {
	store := &memoryStore{encoded: expired, until: time.Now().Add(time.Hour)}
	s := newTestService(store, nil)
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	_, err := s.AccessToken(ctx, "user", "kick")
	if !errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
}
func TestAppTokenCache(t *testing.T) {
	var calls int
	s := newTestService(nil, func(r *http.Request) (*http.Response, error) {
		calls++
		if err := r.ParseForm(); err != nil {
			t.Fatal(err)
		}
		if r.Form.Get("grant_type") != "client_credentials" {
			t.Fatal("wrong app token grant type")
		}
		return response(200, `{"access_token":"app","expires_in":3600}`), nil
	})
	for i := 0; i < 2; i++ {
		token, err := s.AppAccessToken(context.Background(), "twitch")
		if err != nil || token != "app" {
			t.Fatalf("%q %v", token, err)
		}
	}
	if calls != 1 {
		t.Fatal(calls)
	}
}

func TestProviderRefreshRequests(t *testing.T) {
	for _, tc := range []struct {
		provider, host, secretPrefix string
	}{
		{"twitch", "id.twitch.tv", "twitch-client"},
		{"kick", "id.kick.com", "kick-client"},
		{"youtube", "oauth2.googleapis.com", "youtube-oauth-client"},
		{"streamlabs", "www.streamlabs.com", "streamlabs-client"},
		{"streamelements", "api.streamelements.com", "streamelements-client"},
	} {
		t.Run(tc.provider, func(t *testing.T) {
			store := &memoryStore{encoded: expired}
			var fetched []string
			client := &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
				if r.URL.Host != tc.host || r.Header.Get("Content-Type") != "application/x-www-form-urlencoded" {
					t.Fatalf("unexpected token request: %s %s", r.URL, r.Header.Get("Content-Type"))
				}
				if err := r.ParseForm(); err != nil {
					t.Fatal(err)
				}
				fields := r.Form

				if fields.Get("grant_type") != "refresh_token" || fields.Get("refresh_token") != "refresh-old" || fields.Get("client_id") == "" || fields.Get("client_secret") != tc.secretPrefix+"-secret" {
					t.Fatal("missing refresh credentials")
				}
				return response(200, `{"access_token":"new","expires_in":3600}`), nil
			})}
			service := NewServiceWithStore(store, client, func(_ context.Context, name string) (string, error) {
				fetched = append(fetched, name)
				return name, nil
			})
			if token, err := service.AccessToken(context.Background(), "user", tc.provider); err != nil || token != "new" {
				t.Fatalf("%q %v", token, err)
			}
			if _, err := service.Credentials(context.Background(), tc.provider); err != nil {
				t.Fatal(err)
			}
			want := tc.secretPrefix + "-id," + tc.secretPrefix + "-secret"
			if tc.provider == "twitch" {
				want = tc.secretPrefix + "-secret"
			}
			if strings.Join(fetched, ",") != want {
				t.Fatalf("secret reads: %v", fetched)
			}
		})
	}
}

func TestConcurrentAppTokenCache(t *testing.T) {
	service := newTestService(nil, func(*http.Request) (*http.Response, error) {
		return response(200, `{"access_token":"app","expires_in":3600}`), nil
	})
	var wg sync.WaitGroup
	for i := 0; i < 16; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if token, err := service.AppAccessToken(context.Background(), "twitch"); err != nil || token != "app" {
				t.Errorf("%q %v", token, err)
			}
		}()
	}
	wg.Wait()
}

func TestRefreshEncodesTokenAndUpdatesScope(t *testing.T) {
	const refresh = "refresh+old&= /"
	store := &memoryStore{encoded: strings.Replace(expired, "refresh-old", refresh, 1)}
	s := newTestService(store, func(r *http.Request) (*http.Response, error) {
		if err := r.ParseForm(); err != nil {
			t.Fatal(err)
		}
		if r.Form.Get("refresh_token") != refresh || r.Header.Get("Authorization") != "" {
			t.Fatal("refresh token or body authentication changed")
		}
		return response(200, `{"access_token":"new","refresh_token":"rotated+&= /","scope":["chat:write"],"expires_in":"3600"}`), nil
	})
	if token, err := s.AccessToken(context.Background(), "user", "twitch"); err != nil || token != "new" {
		t.Fatalf("%q %v", token, err)
	}
	var stored map[string]any
	if err := json.Unmarshal([]byte(store.encoded), &stored); err != nil {
		t.Fatal(err)
	}
	if stored["refresh_token"] != "rotated+&= /" || stored["scope"].([]any)[0] != "chat:write" || stored["custom"] != true || !valid(stored) {
		t.Fatal("refreshed grant lost fields")
	}
}

// delayedAcquireStore advances only its lease clock to model a slow transaction
// without spending 25 seconds in a unit test. The second replica attempts to
// acquire while the first remote refresh is still in flight.
type delayedAcquireStore struct {
	memoryStore
	once          sync.Once
	delayedNow    time.Time
	secondAttempt chan struct{}
	secondOnce    sync.Once
}

func (s *delayedAcquireStore) Acquire(ctx context.Context, lease Lease) (bool, error) {
	deadline, ok := ctx.Deadline()
	if !ok || lease.Until.Before(deadline.Add(refreshLeaseSafety)) {
		return false, errors.New("lease ends before work safety window")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.owner != "" {
		s.secondOnce.Do(func() { close(s.secondAttempt) })
	}
	if s.encoded != lease.Token || s.delayedNow.Before(s.until) {
		return false, nil
	}
	s.owner = lease.Owner
	s.until = lease.Until
	s.once.Do(func() { s.delayedNow = time.Now().Add(25 * time.Second) })
	return true, nil
}
func TestDelayedAcquisitionCannotOverlapRefresh(t *testing.T) {
	store := &delayedAcquireStore{memoryStore: memoryStore{encoded: expired}, secondAttempt: make(chan struct{})}
	var calls atomic.Int32
	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		calls.Add(1)
		select {
		case <-store.secondAttempt:
		case <-time.After(time.Second):
			return nil, errors.New("second replica never attempted acquisition")
		}
		return response(200, `{"access_token":"new","refresh_token":"rotated","expires_in":3600}`), nil
	})
	services := []*Service{newTestService(store, transport), newTestService(store, transport)}
	var wg sync.WaitGroup
	for _, service := range services {
		wg.Add(1)
		go func(service *Service) {
			defer wg.Done()
			token, err := service.AccessToken(context.Background(), "user", "kick")
			if err != nil || token != "new" {
				t.Errorf("%q %v", token, err)
			}
		}(service)
	}
	wg.Wait()
	if calls.Load() != 1 {
		t.Fatalf("%d concurrent rotations after delayed acquisition", calls.Load())
	}
}
func TestLeaseCoversEntireWorkDeadline(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), refreshWorkBudget)
	defer cancel()
	now := time.Now()
	until := refreshLeaseExpiry(ctx, now)
	deadline, _ := ctx.Deadline()
	if until.Before(now.Add(60*time.Second)) || until.Before(deadline.Add(refreshLeaseSafety)) {
		t.Fatalf("lease %s does not cover work %s", until, deadline)
	}
}
func TestUncertainRefreshKeepsLeaseAndGrant(t *testing.T) {
	for _, failure := range []string{"network", "cancelled", "invalid response", "temporary"} {
		t.Run(failure, func(t *testing.T) {
			store := &memoryStore{encoded: expired}
			var calls atomic.Int32
			service := newTestService(store, func(r *http.Request) (*http.Response, error) {
				calls.Add(1)
				switch failure {
				case "network":
					return nil, errors.New("response lost")
				case "cancelled":
					return nil, context.Canceled
				case "invalid response":
					return response(200, `invalid`), nil
				default:
					return response(503, `{"error":"unavailable"}`), nil
				}
			})
			if _, err := service.AccessToken(context.Background(), "user", "kick"); err == nil {
				t.Fatal("expected refresh failure")
			}
			store.mu.Lock()
			held := store.until.After(time.Now())
			grant := store.encoded
			revoked := store.revoked
			store.mu.Unlock()
			if !held || grant != expired || revoked {
				t.Fatal("uncertain result released lease or removed grant")
			}
			replica := newTestService(store, func(*http.Request) (*http.Response, error) {
				calls.Add(1)
				return response(200, `{"access_token":"wrong","expires_in":3600}`), nil
			})
			ctx, cancel := context.WithTimeout(context.Background(), 20*time.Millisecond)
			defer cancel()
			if _, err := replica.AccessToken(ctx, "user", "kick"); !errors.Is(err, context.DeadlineExceeded) {
				t.Fatalf("second replica bypassed lease: %v", err)
			}
			if calls.Load() != 1 {
				t.Fatal("retried ambiguous rotation before lease expiration")
			}
		})
	}
}

type cancelledAcquireStore struct {
	memoryStore
	cancel context.CancelFunc
}

func (s *cancelledAcquireStore) Acquire(ctx context.Context, lease Lease) (bool, error) {
	acquired, err := s.memoryStore.Acquire(ctx, lease)
	s.cancel()
	return acquired, err
}
func TestNoRefreshStartsAfterAcquireCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	store := &cancelledAcquireStore{memoryStore: memoryStore{encoded: expired}, cancel: cancel}
	var calls int
	service := newTestService(store, func(*http.Request) (*http.Response, error) {
		calls++
		return response(200, `{"access_token":"new","expires_in":3600}`), nil
	})
	if _, err := service.AccessToken(ctx, "user", "kick"); !errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
	if calls != 0 {
		t.Fatal("refresh started after cancellation")
	}
	store.mu.Lock()
	held := store.until.After(time.Now())
	store.mu.Unlock()
	if held {
		t.Fatal("local cancellation before refresh leaked lease")
	}
}
