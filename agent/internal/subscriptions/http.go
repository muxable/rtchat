package subscriptions

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"time"

	"github.com/muxable/rtchat/agent/internal/provider"
)

type Tokens interface {
	AppAccessToken(context.Context, string) (string, error)
	AccessToken(context.Context, string, string) (string, error)
	Credentials(context.Context, string) (provider.Credentials, error)
}
type API struct {
	Tokens             Tokens
	Client             *http.Client
	TwitchURL, KickURL string
}
type APIError struct {
	Provider, Path string
	Status         int
}

func (e *APIError) Error() string { return fmt.Sprintf("%s %s: HTTP %d", e.Provider, e.Path, e.Status) }

// Mutating requests are not automatically retried after ambiguous failures:
// the caller re-lists subscriptions before retrying, avoiding duplicate POSTs.
func (a *API) request(ctx context.Context, p, token, method, path string, q url.Values, body, out interface{}) error {
	base := a.KickURL
	if base == "" {
		base = "https://api.kick.com/public/v1"
	}
	if p == "twitch" {
		base = a.TwitchURL
		if base == "" {
			base = "https://api.twitch.tv/helix"
		}
	}
	var payload []byte
	var err error
	if body != nil {
		payload, err = json.Marshal(body)
		if err != nil {
			return err
		}
	}
	client := a.Client
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	for attempt := 0; attempt < 3; attempt++ {
		req, err := http.NewRequestWithContext(ctx, method, base+path+"?"+q.Encode(), bytes.NewReader(payload))
		if err != nil {
			return err
		}
		req.Header.Set("Authorization", "Bearer "+token)
		req.Header.Set("Content-Type", "application/json")
		if p == "twitch" {
			credentials, err := a.Tokens.Credentials(ctx, p)
			if err != nil {
				return err
			}
			req.Header.Set("Client-ID", credentials.ClientID)
		}
		response, err := client.Do(req)
		if err != nil {
			return err
		}
		if response.StatusCode >= 200 && response.StatusCode < 300 {
			defer response.Body.Close()
			if out == nil {
				return nil
			}
			return json.NewDecoder(io.LimitReader(response.Body, 8<<20)).Decode(out)
		}
		io.Copy(io.Discard, io.LimitReader(response.Body, 4096))
		response.Body.Close()
		if response.StatusCode == 429 || (method == http.MethodGet && response.StatusCode >= 500) {
			delay := time.Duration(1<<attempt) * time.Second
			if seconds, err := strconv.Atoi(response.Header.Get("Retry-After")); err == nil && seconds > 0 {
				delay = time.Duration(seconds) * time.Second
			}
			if at, err := http.ParseTime(response.Header.Get("Retry-After")); err == nil && time.Until(at) > delay {
				delay = time.Until(at)
			}
			if reset, err := strconv.ParseInt(response.Header.Get("Ratelimit-Reset"), 10, 64); err == nil && time.Until(time.Unix(reset, 0)) > delay {
				delay = time.Until(time.Unix(reset, 0))
			}
			if attempt == 2 || delay > 30*time.Second {
				return &APIError{p, path, response.StatusCode}
			}
			timer := time.NewTimer(delay)
			select {
			case <-ctx.Done():
				timer.Stop()
				return ctx.Err()
			case <-timer.C:
			}
			continue
		}
		return &APIError{p, path, response.StatusCode}
	}
	return fmt.Errorf("provider retry limit reached")
}
