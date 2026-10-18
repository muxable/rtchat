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

type Credentials struct{ ClientID, ClientSecret string }
type SecretFetcher func(context.Context, string) (string, error)

// Lease identifies the refresh owner and the grant it is allowed to replace.
type Lease struct {
	UID, Provider, Token, Owner string
	Until                       time.Time
}

// RefreshResult replaces a token, revokes a grant, or simply releases the lease.
type RefreshResult struct {
	Token   string
	Revoked bool
}

type Store interface {
	Load(context.Context, string, string) (string, error)
	// Acquire atomically checks the serialized token and claims a bounded cross-instance lease.
	Acquire(context.Context, Lease) (bool, error)
	Finish(context.Context, Lease, RefreshResult) error
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
	if _, ok := providers[p]; !ok {
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
	config := providers[p]
	var c Credentials
	var err error
	c.ClientID = config.clientID
	if c.ClientID == "" {
		c.ClientID, err = s.fetch(ctx, config.secretPrefix+"-id")
		if err != nil {
			return c, err
		}
	}
	c.ClientSecret, err = s.fetch(ctx, config.secretPrefix+"-secret")
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

type providerConfig struct {
	endpoint     string
	secretPrefix string
	clientID     string // Set when the public client ID is already known.
	jsonBody     bool
	appToken     bool
}

var providers = map[string]providerConfig{
	"twitch":         {endpoint: "https://id.twitch.tv/oauth2/token", secretPrefix: "twitch-client", clientID: auth.TwitchClientID(), jsonBody: true, appToken: true},
	"kick":           {endpoint: "https://id.kick.com/oauth/token", secretPrefix: "kick-client", appToken: true},
	"youtube":        {endpoint: "https://oauth2.googleapis.com/token", secretPrefix: "youtube-oauth-client"},
	"streamlabs":     {endpoint: "https://www.streamlabs.com/api/v1.0/token", secretPrefix: "streamlabs-client", jsonBody: true},
	"streamelements": {endpoint: "https://api.streamelements.com/oauth2/token", secretPrefix: "streamelements-client", jsonBody: true},
}

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
	if _, ok := providers[p]; !ok {
		return "", errors.New("unknown provider")
	}
	if uid == "" || strings.Contains(uid, "/") {
		return "", ErrNoToken
	}
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
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
		lease := Lease{UID: uid, Provider: p, Token: encoded, Owner: newLeaseID(), Until: time.Now().Add(20 * time.Second)}
		acquired, err := s.store.Acquire(ctx, lease)
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
		refreshed, revoked, err := s.refresh(ctx, p, token)
		if err != nil {
			releaseErr := s.release(lease, revoked)
			if revoked && releaseErr != nil {
				return "", releaseErr
			}
			if revoked {
				return "", ErrNoToken
			}
			return "", err
		}
		data, err := json.Marshal(refreshed)
		if err != nil {
			_ = s.release(lease, false)
			return "", err
		}
		if err = s.store.Finish(ctx, lease, RefreshResult{Token: string(data)}); err != nil {
			return "", err
		}
		// Re-read in case an OAuth callback replaced the document during refresh.
	}
}
func (s *Service) release(lease Lease, revoked bool) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	return s.store.Finish(ctx, lease, RefreshResult{Revoked: revoked})
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
	if !providers[p].appToken {
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
	if providers[p].jsonBody {
		values := map[string]string{}
		for k, v := range form {
			values[k] = v[0]
		}
		data, _ := json.Marshal(values)
		body = strings.NewReader(string(data))
		contentType = "application/json"
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, providers[p].endpoint, body)
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
