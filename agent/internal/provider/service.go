// Package provider shares OAuth credentials and JSON-string tokens with the legacy functions.
package provider

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"

	"cloud.google.com/go/firestore"
	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
	"github.com/muxable/rtchat/agent/internal/auth"
)

var ErrNoToken = errors.New("provider token unavailable")
var ErrRefreshBusy = errors.New("provider refresh in progress")

const (
	refreshWorkBudget    = 30 * time.Second
	refreshLeaseDuration = 60 * time.Second
	refreshLeaseSafety   = 30 * time.Second
)

// The lease outlives the entire operation, including a slow/retried Acquire.
// Its safety window also lets canceled remote requests settle before retrying.
func refreshLeaseExpiry(ctx context.Context, now time.Time) time.Time {
	until := now.Add(refreshLeaseDuration)
	if deadline, ok := ctx.Deadline(); ok && deadline.Add(refreshLeaseSafety).After(until) {
		until = deadline.Add(refreshLeaseSafety)
	}
	return until
}

type Credentials struct{ ClientID, ClientSecret string }
type SecretFetcher func(context.Context, string) (string, error)
type Store interface {
	Load(context.Context, string, string) (string, error)
	// Acquire atomically checks the serialized token and claims a bounded cross-instance lease.
	Acquire(context.Context, string, string, string, string, time.Time) (bool, error)
	Finish(context.Context, string, string, string, string, *string, bool) error
}
type Service struct {
	store       Store
	client      *http.Client
	fetch       SecretFetcher
	mu          sync.Mutex
	credentials map[string]Credentials
	appTokens   map[string]map[string]any
}

func NewService(db *firestore.Client, client *http.Client) *Service {
	return NewServiceWithStore(FirestoreStore{DB: db}, client, nil)
}
func NewServiceWithStore(store Store, client *http.Client, fetch SecretFetcher) *Service {
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	if fetch == nil {
		fetch = fetchSecret
	}
	return &Service{store: store, client: client, fetch: fetch, credentials: map[string]Credentials{}, appTokens: map[string]map[string]any{}}
}
func fetchSecret(ctx context.Context, name string) (string, error) {
	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		return "", err
	}
	defer client.Close()
	result, err := client.AccessSecretVersion(ctx, &secretmanagerpb.AccessSecretVersionRequest{Name: "projects/rtchat-47692/secrets/" + name + "/versions/latest"})
	if err != nil {
		return "", err
	}
	if len(result.GetPayload().GetData()) == 0 {
		return "", errors.New("empty provider secret")
	}
	return string(result.Payload.Data), nil
}
func (s *Service) Credentials(ctx context.Context, p string) (Credentials, error) {
	if _, ok := endpoints[p]; !ok {
		return Credentials{}, errors.New("unknown provider")
	}
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	s.mu.Lock()
	cached, ok := s.credentials[p]
	s.mu.Unlock()
	if ok {
		return cached, nil
	}
	prefix := p + "-client"
	if p == "youtube" {
		prefix = "youtube-oauth-client"
	}
	var c Credentials
	var err error
	if p == "twitch" {
		c.ClientID = auth.TwitchClientID()
	} else {
		c.ClientID, err = s.fetch(ctx, prefix+"-id")
		if err != nil {
			return c, err
		}
	}
	c.ClientSecret, err = s.fetch(ctx, prefix+"-secret")
	if err != nil {
		return Credentials{}, err
	}
	if c.ClientID == "" || c.ClientSecret == "" {
		return Credentials{}, errors.New("missing provider credentials")
	}
	s.mu.Lock()
	s.credentials[p] = c
	s.mu.Unlock()
	return c, nil
}

var endpoints = map[string]string{"twitch": "https://id.twitch.tv/oauth2/token", "kick": "https://id.kick.com/oauth/token", "youtube": "https://oauth2.googleapis.com/token", "streamlabs": "https://www.streamlabs.com/api/v1.0/token", "streamelements": "https://api.streamelements.com/oauth2/token"}

func decodeToken(encoded string) (map[string]any, error) {
	var token map[string]any
	if json.Unmarshal([]byte(encoded), &token) != nil || token == nil {
		return nil, errors.New("invalid stored provider token")
	}
	return token, nil
}
func tokenString(token map[string]any, key string) string { v, _ := token[key].(string); return v }
func valid(token map[string]any) bool {
	if tokenString(token, "access_token") == "" {
		return false
	}
	expiry := tokenString(token, "expires_at")
	if expiry == "" {
		return true
	} // Legacy grants without expiry remain usable until provider rejects them.
	t, err := time.Parse(time.RFC3339Nano, expiry)
	return err == nil && time.Until(t) > 300*time.Second
}

func (s *Service) AccessToken(ctx context.Context, uid, p string) (string, error) {
	if _, ok := endpoints[p]; !ok {
		return "", errors.New("unknown provider")
	}
	if uid == "" || strings.Contains(uid, "/") {
		return "", ErrNoToken
	}
	ctx, cancel := context.WithTimeout(ctx, refreshWorkBudget)
	defer cancel()
	for {
		encoded, err := s.store.Load(ctx, uid, p)
		if err != nil {
			return "", err
		}
		token, err := decodeToken(encoded)
		if err != nil {
			return "", err
		}
		if valid(token) {
			return tokenString(token, "access_token"), nil
		}
		// A fresh unique document ID is used only as an opaque lease owner.
		owner := newLeaseID()
		leaseUntil := refreshLeaseExpiry(ctx, time.Now())
		acquired, err := s.store.Acquire(ctx, uid, p, encoded, owner, leaseUntil)
		if err != nil {
			return "", err
		}
		if !acquired {
			select {
			case <-ctx.Done():
				return "", ctx.Err()
			case <-time.After(100 * time.Millisecond):
				continue
			}
		}
		// Acquire can return after transaction retries. Never start a remote rotation
		// after cancellation or if the lease cannot cover the remaining work budget.
		if err := ctx.Err(); err != nil {
			_ = s.release(uid, p, encoded, owner, nil, false)
			return "", err
		}
		deadline, _ := ctx.Deadline()
		if leaseUntil.Before(deadline.Add(refreshLeaseSafety)) || time.Until(leaseUntil) <= refreshLeaseSafety {
			_ = s.release(uid, p, encoded, owner, nil, false)
			return "", ErrRefreshBusy
		}
		refreshed, revoked, err := s.refresh(ctx, p, token)
		if err != nil {
			if revoked {
				if releaseErr := s.release(uid, p, encoded, owner, nil, true); releaseErr != nil {
					return "", releaseErr
				}
				return "", ErrNoToken
			}
			// Missing refresh_token is a local failure: no provider call was attempted.
			if errors.Is(err, ErrNoToken) {
				_ = s.release(uid, p, encoded, owner, nil, false)
			}
			// Other failures may have consumed a rotating token despite a canceled or
			// lost response. Keep the lease through its safety window; leave the grant
			// and profile intact so transient errors never sign the user out.
			return "", err
		}
		data, err := json.Marshal(refreshed)
		if err != nil {
			return "", err
		}
		next := string(data)
		if err = s.store.Finish(ctx, uid, p, encoded, owner, &next, false); err != nil {
			return "", err
		}
		// Re-read in case an OAuth callback replaced the document during refresh.
	}
}
func (s *Service) release(uid, p, encoded, owner string, next *string, revoked bool) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	return s.store.Finish(ctx, uid, p, encoded, owner, next, revoked)
}
func (s *Service) refresh(ctx context.Context, p string, previous map[string]any) (map[string]any, bool, error) {
	refresh := tokenString(previous, "refresh_token")
	if refresh == "" {
		return nil, false, ErrNoToken
	}
	result, revoked, err := s.requestToken(ctx, p, url.Values{"grant_type": {"refresh_token"}, "refresh_token": {refresh}})
	if err != nil {
		return nil, revoked, err
	}
	merged := map[string]any{}
	for k, v := range previous {
		merged[k] = v
	}
	for k, v := range result {
		merged[k] = v
	}
	if _, ok := result["expires_at"]; !ok {
		delete(merged, "expires_at")
	}
	if tokenString(result, "refresh_token") == "" {
		merged["refresh_token"] = refresh
	}
	return merged, false, nil
}
func (s *Service) AppAccessToken(ctx context.Context, p string) (string, error) {
	if p != "twitch" && p != "kick" {
		return "", errors.New("provider has no app token")
	}
	// Cache protected separately from credential loading to avoid locking recursively.
	s.mu.Lock()
	cached := s.appTokens[p]
	if valid(cached) {
		result := tokenString(cached, "access_token")
		s.mu.Unlock()
		return result, nil
	}
	s.mu.Unlock()
	result, _, err := s.requestToken(ctx, p, url.Values{"grant_type": {"client_credentials"}})
	if err != nil {
		return "", err
	}
	s.mu.Lock()
	s.appTokens[p] = result
	s.mu.Unlock()
	return tokenString(result, "access_token"), nil
}
func (s *Service) requestToken(ctx context.Context, p string, form url.Values) (map[string]any, bool, error) {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	credentials, err := s.Credentials(ctx, p)
	if err != nil {
		return nil, false, err
	}
	form.Set("client_id", credentials.ClientID)
	form.Set("client_secret", credentials.ClientSecret)
	var body io.Reader = strings.NewReader(form.Encode())
	contentType := "application/x-www-form-urlencoded"
	if p == "twitch" || p == "streamlabs" || p == "streamelements" {
		values := map[string]string{}
		for k, v := range form {
			values[k] = v[0]
		}
		data, _ := json.Marshal(values)
		body = strings.NewReader(string(data))
		contentType = "application/json"
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoints[p], body)
	if err != nil {
		return nil, false, err
	}
	req.Header.Set("Content-Type", contentType)
	resp, err := s.client.Do(req)
	if err != nil {
		return nil, false, errors.New("provider token request failed")
	}
	defer resp.Body.Close()
	var result map[string]any
	err = json.NewDecoder(io.LimitReader(resp.Body, 1024*1024)).Decode(&result)
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		revoked := result["error"] == "invalid_grant" || result["message"] == "Invalid refresh token"
		return nil, revoked, fmt.Errorf("provider token request returned HTTP %d", resp.StatusCode)
	}
	if err != nil || tokenString(result, "access_token") == "" {
		return nil, false, errors.New("invalid provider token response")
	}
	if seconds, ok := result["expires_in"].(float64); ok {
		if seconds <= 300 {
			return nil, false, errors.New("provider token expiry too short")
		}
		result["expires_at"] = time.Now().Add(time.Duration(seconds * float64(time.Second))).UTC().Format(time.RFC3339Nano)
	} else if expiry := tokenString(result, "expires_at"); expiry != "" {
		if _, err := time.Parse(time.RFC3339Nano, expiry); err != nil {
			return nil, false, errors.New("invalid provider token expiry")
		}
	}
	return result, false, nil
}
