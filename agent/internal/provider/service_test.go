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
	}{{"revoked", 400, `{"error":"invalid_grant"}`, true}, {"temporary", 503, `{"error":"unavailable","secret":"do-not-leak"}`, false}, {"bad JSON", 200, "invalid", false}} {
		t.Run(tc.name, func(t *testing.T) {
			store := &memoryStore{encoded: expired}
			s := newTestService(store, func(r *http.Request) (*http.Response, error) { return response(tc.code, tc.body), nil })
			_, err := s.AccessToken(context.Background(), "user", "kick")
			if err == nil || strings.Contains(err.Error(), "do-not-leak") || store.revoked != tc.revoked {
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
		var body map[string]string
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			t.Fatal(err)
		}
		if body["grant_type"] != "client_credentials" {
			t.Fatal(body)
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
		provider, host, secretPrefix, contentType string
	}{
		{"twitch", "id.twitch.tv", "twitch-client", "application/json"},
		{"kick", "id.kick.com", "kick-client", "application/x-www-form-urlencoded"},
		{"youtube", "oauth2.googleapis.com", "youtube-oauth-client", "application/x-www-form-urlencoded"},
		{"streamlabs", "www.streamlabs.com", "streamlabs-client", "application/json"},
		{"streamelements", "api.streamelements.com", "streamelements-client", "application/json"},
	} {
		t.Run(tc.provider, func(t *testing.T) {
			store := &memoryStore{encoded: expired}
			var fetched []string
			client := &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
				if r.URL.Host != tc.host || r.Header.Get("Content-Type") != tc.contentType {
					t.Fatalf("unexpected token request: %s %s", r.URL, r.Header.Get("Content-Type"))
				}
				var fields map[string]string
				if tc.contentType == "application/json" {
					if err := json.NewDecoder(r.Body).Decode(&fields); err != nil {
						t.Fatal(err)
					}
				} else {
					if err := r.ParseForm(); err != nil {
						t.Fatal(err)
					}
					fields = make(map[string]string)
					for key := range r.Form {
						fields[key] = r.Form.Get(key)
					}
				}
				if fields["grant_type"] != "refresh_token" || fields["refresh_token"] != "refresh-old" || fields["client_id"] == "" || fields["client_secret"] != tc.secretPrefix+"-secret" {
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
