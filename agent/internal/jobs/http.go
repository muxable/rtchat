package jobs

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"time"
)

type HTTPError struct {
	Provider, Path string
	Status         int
}

func (e *HTTPError) Error() string {
	return fmt.Sprintf("%s %s: HTTP %d", e.Provider, e.Path, e.Status)
}

type Tokens interface {
	AppAccessToken(context.Context, string) (string, error)
}
type API struct {
	Tokens             Tokens
	Client             *http.Client
	TwitchClientID     string
	TwitchURL, KickURL string
}

// Requests are serial (bounded concurrency = 1), context-bound, and retry only
// transient errors. Both supported operations, GET and DELETE, are idempotent.
func (a *API) request(ctx context.Context, provider, method, path string, query url.Values, out interface{}) error {
	token, err := a.Tokens.AppAccessToken(ctx, provider)
	if err != nil {
		return err
	}
	base := a.KickURL
	if base == "" {
		base = "https://api.kick.com/public/v1"
	}
	if provider == "twitch" {
		base = a.TwitchURL
		if base == "" {
			base = "https://api.twitch.tv/helix"
		}
	}
	client := a.Client
	if client == nil {
		client = &http.Client{Timeout: 15 * time.Second}
	}
	for attempt := 0; attempt < 4; attempt++ {
		req, err := http.NewRequestWithContext(ctx, method, base+path+"?"+query.Encode(), nil)
		if err != nil {
			return err
		}
		req.Header.Set("Authorization", "Bearer "+token)
		if provider == "twitch" {
			req.Header.Set("Client-ID", a.TwitchClientID)
		}
		resp, err := client.Do(req)
		if err != nil {
			return err
		}
		if resp.StatusCode >= 200 && resp.StatusCode < 300 {
			defer resp.Body.Close()
			if out == nil {
				return nil
			}
			return json.NewDecoder(io.LimitReader(resp.Body, 8<<20)).Decode(out)
		}
		io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
		resp.Body.Close()
		if method == http.MethodDelete && resp.StatusCode == http.StatusNotFound {
			return nil
		}
		if resp.StatusCode != 429 && resp.StatusCode < 500 {
			return &HTTPError{provider, path, resp.StatusCode}
		}
		delay := time.Duration(1<<attempt) * time.Second
		if seconds, e := strconv.Atoi(resp.Header.Get("Retry-After")); e == nil && seconds > 0 {
			delay = time.Duration(seconds) * time.Second
		} else if at, e := http.ParseTime(resp.Header.Get("Retry-After")); e == nil && time.Until(at) > 0 {
			delay = time.Until(at)
		}
		if reset, e := strconv.ParseInt(resp.Header.Get("Ratelimit-Reset"), 10, 64); e == nil && time.Until(time.Unix(reset, 0)) > delay {
			delay = time.Until(time.Unix(reset, 0))
		}
		if delay > time.Minute {
			return fmt.Errorf("%s %s: rate limit retry exceeds job budget", provider, path)
		}
		timer := time.NewTimer(delay)
		select {
		case <-ctx.Done():
			timer.Stop()
			return ctx.Err()
		case <-timer.C:
		}
	}
	return fmt.Errorf("%s %s: retry limit reached", provider, path)
}
func params(key string, ids []string) url.Values {
	v := url.Values{}
	for _, id := range ids {
		v.Add(key, id)
	}
	return v
}
