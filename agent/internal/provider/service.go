// Package provider shares OAuth credentials and JSON-string tokens with the legacy functions.
package provider

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"cloud.google.com/go/firestore"
	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
	"github.com/muxable/rtchat/agent/internal/auth"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/clientcredentials"
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
	credentials sync.Map // provider -> Credentials
	appTokens   sync.Map // provider -> decoded token
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
	return &Service{store: store, client: client, fetch: fetch}
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
	if cached, ok := s.credentials.Load(p); ok {
		return cached.(Credentials), nil
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
	s.credentials.Store(p, c)
	return c, nil
}

type providerConfig struct {
	endpoint     string
	secretPrefix string
	clientID     string // Set when the public client ID is already known.
	appToken     bool
}

var providers = map[string]providerConfig{
	"twitch":         {endpoint: "https://id.twitch.tv/oauth2/token", secretPrefix: "twitch-client", clientID: auth.TwitchClientID(), appToken: true},
	"kick":           {endpoint: "https://id.kick.com/oauth/token", secretPrefix: "kick-client", appToken: true},
	"youtube":        {endpoint: "https://oauth2.googleapis.com/token", secretPrefix: "youtube-oauth-client"},
	"streamlabs":     {endpoint: "https://www.streamlabs.com/api/v1.0/token", secretPrefix: "streamlabs-client"},
	"streamelements": {endpoint: "https://api.streamelements.com/oauth2/token", secretPrefix: "streamelements-client"},
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
	result, revoked, err := s.requestToken(ctx, p, refresh)
	if err != nil {
		return nil, revoked, err
	}
	for k, v := range result {
		previous[k] = v
	}
	if _, ok := result["expires_at"]; !ok {
		delete(previous, "expires_at")
	}
	return previous, false, nil
}
func (s *Service) AppAccessToken(ctx context.Context, p string) (string, error) {
	if !providers[p].appToken {
		return "", errors.New("provider has no app token")
	}
	cached, _ := s.appTokens.Load(p)
	token, _ := cached.(map[string]any)
	if valid(token) {
		return tokenString(token, "access_token"), nil
	}
	result, _, err := s.requestToken(ctx, p, "")
	if err != nil {
		return "", err
	}
	s.appTokens.Store(p, result)
	return tokenString(result, "access_token"), nil
}

// An empty refresh token requests an app token; refresh rejects missing grants locally.
func (s *Service) requestToken(ctx context.Context, p, refresh string) (map[string]any, bool, error) {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	credentials, err := s.Credentials(ctx, p)
	if err != nil {
		return nil, false, err
	}
	ctx = context.WithValue(ctx, oauth2.HTTPClient, s.client)
	endpoint := oauth2.Endpoint{TokenURL: providers[p].endpoint, AuthStyle: oauth2.AuthStyleInParams}
	var token *oauth2.Token
	if refresh == "" {
		config := clientcredentials.Config{ClientID: credentials.ClientID, ClientSecret: credentials.ClientSecret, TokenURL: endpoint.TokenURL, AuthStyle: endpoint.AuthStyle}
		token, err = config.Token(ctx)
	} else {
		config := oauth2.Config{ClientID: credentials.ClientID, ClientSecret: credentials.ClientSecret, Endpoint: endpoint}
		token, err = config.TokenSource(ctx, &oauth2.Token{RefreshToken: refresh}).Token()
	}
	if err != nil {
		// RetrieveError includes the raw response body. Classify revoked grants,
		// then return a redacted error so credentials cannot reach callers/logs.
		var response *oauth2.RetrieveError
		if errors.As(err, &response) {
			var body map[string]any
			_ = json.Unmarshal(response.Body, &body)
			revoked := body["error"] == "invalid_grant" || body["message"] == "Invalid refresh token"
			return nil, revoked, fmt.Errorf("provider token request returned HTTP %d", response.Response.StatusCode)
		}
		return nil, false, errors.New("provider token request failed")
	}
	if !token.Expiry.IsZero() && time.Until(token.Expiry) <= 5*time.Minute {
		return nil, false, errors.New("provider token expiry too short")
	}
	// Adapt library tokens to the existing Firestore schema. OAuth2 already
	// retains the previous refresh token when a provider omits it.
	result := map[string]any{"access_token": token.AccessToken, "refresh_token": token.RefreshToken}
	for _, key := range []string{"scope", "token_type", "expires_in"} {
		if value := token.Extra(key); value != nil {
			result[key] = value
		}
	}
	if !token.Expiry.IsZero() {
		result["expires_at"] = token.Expiry.UTC().Format(time.RFC3339Nano)
	}
	return result, false, nil
}
