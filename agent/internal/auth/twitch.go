package auth

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"time"

	"cloud.google.com/go/firestore"
	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
	"github.com/muxable/rtchat/agent/internal/agent"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/clientcredentials"
	"golang.org/x/oauth2/twitch"
)

// TwitchClientID is public; the secret lives in Secret Manager.
func TwitchClientID() string {
	return "edfnh2q85za8phifif9jxt3ey6t9b9"
}

// TwitchClientSecret reads the secret from Secret Manager, which the deploy
// workflow controls.
func TwitchClientSecret() (string, error) {
	ctx := context.Background()

	c, err := secretmanager.NewClient(ctx)
	if err != nil {
		return "", err
	}
	defer c.Close()

	req := &secretmanagerpb.AccessSecretVersionRequest{
		Name: "projects/rtchat-47692/secrets/twitch-client-secret/versions/latest",
	}

	// Call the API.
	result, err := c.AccessSecretVersion(ctx, req)
	return secretPayload(result, err)
}

// ProviderTokens owns token refresh and conditional revocation cleanup.
type ProviderTokens interface {
	AccessToken(context.Context, string, string) (string, error)
}

type TwitchAuthProvider struct {
	tokens ProviderTokens
	userID string
	client *http.Client
}

func TwitchUserIDFromUsername(firestore *firestore.Client, clientID, clientSecret, username string) (string, error) {
	userDoc, err := agent.FirstDocument(firestore.Collection("profiles").Where("twitch.login", "==", username).Documents(context.Background()))
	if err == nil {
		return profileString(userDoc.Data(), "id")
	}
	// try fetching it from twitch.
	cfg := &clientcredentials.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		TokenURL:     twitch.Endpoint.TokenURL,
	}
	token, err := cfg.Token(context.Background())
	if err != nil {
		return "", fmt.Errorf("failed to fetch auth token: %w", err)
	}
	client := &http.Client{Timeout: 10 * time.Second}
	req := &http.Request{
		Method: "GET",
		URL: &url.URL{
			Scheme:   "https",
			Host:     "api.twitch.tv",
			Path:     "/helix/users",
			RawQuery: fmt.Sprintf("login=%s", username),
		},
		Header: http.Header{
			"Authorization": []string{fmt.Sprintf("Bearer %s", token.AccessToken)},
			"Client-Id":     []string{clientID},
		},
	}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to fetch user: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("failed to fetch user: %s", resp.Status)
	}

	var data struct {
		Data []struct {
			ID string `json:"id"`
		} `json:"data"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}
	if len(data.Data) == 0 {
		return "", fmt.Errorf("user not found: %s", username)
	}
	return data.Data[0].ID, nil
}

// NewTwitchTokenSource adapts the shared refresh service for IRC. In particular,
// revoked refresh grants clear the matching provider token and profile there.
func NewTwitchTokenSource(tokens ProviderTokens, userID string) *TwitchAuthProvider {
	return &TwitchAuthProvider{tokens: tokens, userID: userID, client: &http.Client{Timeout: 10 * time.Second}}
}

func (p *TwitchAuthProvider) Token() (*oauth2.Token, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	access, err := p.tokens.AccessToken(ctx, p.userID, "twitch")
	if err != nil {
		return nil, err
	}
	token := &oauth2.Token{AccessToken: access}
	if err := validateToken(p.client, token); err != nil {
		return nil, err
	}
	return token, nil
}

func profileString(data map[string]interface{}, field string) (string, error) {
	profile, ok := data["twitch"].(map[string]interface{})
	if !ok {
		return "", errors.New("invalid twitch profile")
	}
	value, ok := profile[field].(string)
	if !ok || value == "" {
		return "", fmt.Errorf("invalid twitch %s", field)
	}
	return value, nil
}

func validateToken(client *http.Client, token *oauth2.Token) error {
	// validate the token
	req := &http.Request{
		Method: "GET",
		URL: &url.URL{
			Scheme: "https",
			Host:   "id.twitch.tv",
			Path:   "/oauth2/validate",
		},
		Header: http.Header{
			"Authorization": []string{"OAuth " + token.AccessToken},
		},
	}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return errors.New("invalid token")
	}

	return nil
}

func secretPayload(result *secretmanagerpb.AccessSecretVersionResponse, err error) (string, error) {
	if err != nil {
		return "", err
	}
	if result == nil || result.Payload == nil {
		return "", errors.New("missing secret payload")
	}
	return string(result.Payload.Data), nil
}
