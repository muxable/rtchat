// Package eventsubmigration moves app-owned EventSub callbacks without deleting
// an old subscription before its replacement is enabled.
package eventsubmigration

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
)

const LegacyCallback = "https://us-central1-rtchat-47692.cloudfunctions.net/eventsub"
const AliasCallback = "https://rtchat-api.rtirl.com/eventsub"
const TargetCallback = "https://rtchat-api.rtirl.com/twitch/eventsub"

type Transport struct {
	Method   string `json:"method"`
	Callback string `json:"callback,omitempty"`
}
type Subscription struct {
	ID        string          `json:"id"`
	Status    string          `json:"status"`
	Type      string          `json:"type"`
	Version   string          `json:"version"`
	Condition json.RawMessage `json:"condition"`
	Cost      int             `json:"cost"`
	Transport Transport       `json:"transport"`
}
type Listing struct {
	Data         []Subscription `json:"data"`
	TotalCost    int            `json:"total_cost"`
	MaxTotalCost int            `json:"max_total_cost"`
	Pagination   struct {
		Cursor string `json:"cursor"`
	} `json:"pagination"`
}
type API struct {
	Client                   *http.Client
	BaseURL, ClientID, Token string
	Pause                    func(context.Context, time.Duration) error
}
type HTTPError struct{ Status int }

func (e *HTTPError) Error() string { return fmt.Sprintf("Twitch EventSub HTTP %d", e.Status) }
func pause(ctx context.Context, delay time.Duration) error {
	timer := time.NewTimer(delay)
	defer timer.Stop()
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-timer.C:
		return nil
	}
}
func (a *API) sleep(ctx context.Context, delay time.Duration) error {
	if a.Pause != nil {
		return a.Pause(ctx, delay)
	}
	return pause(ctx, delay)
}
func (a *API) request(ctx context.Context, method string, q url.Values, body, out interface{}) error {
	base := a.BaseURL
	if base == "" {
		base = "https://api.twitch.tv/helix"
	}
	client := a.Client
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	var encoded []byte
	var err error
	if body != nil {
		encoded, err = json.Marshal(body)
		if err != nil {
			return err
		}
	}
	for attempt := 0; attempt < 4; attempt++ {
		req, err := http.NewRequestWithContext(ctx, method, base+"/eventsub/subscriptions?"+q.Encode(), bytes.NewReader(encoded))
		if err != nil {
			return err
		}
		req.Header.Set("Client-ID", a.ClientID)
		req.Header.Set("Authorization", "Bearer "+a.Token)
		req.Header.Set("Content-Type", "application/json")
		response, err := client.Do(req)
		if err != nil {
			// POST may have succeeded before a transport error. Let resume discover
			// the replacement instead of creating a second subscription blindly.
			if method == http.MethodPost || attempt == 3 || ctx.Err() != nil {
				return fmt.Errorf("Twitch EventSub transport failure")
			}
			if err := a.sleep(ctx, time.Duration(1<<attempt)*time.Second); err != nil {
				return err
			}
			continue
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
		if response.StatusCode == 404 && method == http.MethodDelete {
			return nil
		}
		// 429 may indicate the three-per-condition cap. Bound retries and leave
		// the source intact. Retry GET/DELETE server errors, never ambiguous POSTs.
		if attempt < 3 && (response.StatusCode == 429 || (response.StatusCode >= 500 && method != http.MethodPost)) {
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
			if delay > 30*time.Second {
				return &HTTPError{response.StatusCode}
			}
			if err := a.sleep(ctx, delay); err != nil {
				return err
			}
			continue
		}
		return &HTTPError{response.StatusCode}
	}
	return fmt.Errorf("Twitch EventSub retries exhausted")
}
func (a *API) List(ctx context.Context, q url.Values) (Listing, error) {
	if q == nil {
		q = url.Values{}
	}
	var all Listing
	seen := map[string]bool{}
	ids := map[string]bool{}
	for {
		var page Listing
		if err := a.request(ctx, http.MethodGet, q, nil, &page); err != nil {
			return all, err
		}
		if page.Data == nil {
			return all, fmt.Errorf("Twitch subscriptions response missing data")
		}
		all.TotalCost = page.TotalCost
		all.MaxTotalCost = page.MaxTotalCost
		for _, sub := range page.Data {
			if !ids[sub.ID] {
				all.Data = append(all.Data, sub)
				ids[sub.ID] = true
			}
		}
		cursor := page.Pagination.Cursor
		if cursor == "" {
			return all, nil
		}
		if seen[cursor] {
			return all, fmt.Errorf("Twitch pagination cursor repeated")
		}
		seen[cursor] = true
		q.Set("after", cursor)
	}
}
func (a *API) Create(ctx context.Context, source Subscription, callback, secret string) (Subscription, error) {
	body := map[string]interface{}{"type": source.Type, "version": source.Version, "condition": source.Condition, "transport": map[string]interface{}{"method": "webhook", "callback": callback, "secret": secret}}
	var result Listing
	if err := a.request(ctx, http.MethodPost, nil, body, &result); err != nil {
		return Subscription{}, err
	}
	if len(result.Data) != 1 {
		return Subscription{}, fmt.Errorf("Twitch creation response must contain one subscription")
	}
	return result.Data[0], nil
}
func (a *API) Delete(ctx context.Context, id string) error {
	return a.request(ctx, http.MethodDelete, url.Values{"id": {id}}, nil, nil)
}
