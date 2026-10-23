// Package eventsubmigration moves app-owned EventSub callbacks without deleting
// an old subscription before its replacement is enabled, except where the
// EventSub cost cap forces a checkpointed break-before-make.
package eventsubmigration

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/muxable/rtchat/agent/internal/clients"
	"github.com/muxable/rtchat/agent/internal/clients/twitch"
	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
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
	// Pacer, when set, spaces every request and yields to production when the
	// shared app-token bucket runs low.
	Pacer *Pacer
	// Cost is the most recent total_cost/max_total_cost Twitch reported.
	Cost struct {
		Known      bool
		Total, Max int
	}
}
type HTTPError = clients.HTTPError

// ErrCostLimit means Twitch rejected a creation because the client is at its
// EventSub max_total_cost (HTTP 429 "subscription limit exceeded"). It is a
// definite rejection, not a rate limit, so it is never retried.
var ErrCostLimit = errors.New("EventSub cost limit reached")

// costLimited distinguishes Twitch's cost-cap 429 from a rate-limit 429: the
// former names the subscription limit, and arrives with points still left in
// the rate-limit bucket.
func costLimited(response *clients.Response) bool {
	var body struct{ Message string }
	json.Unmarshal(response.Body, &body)
	message := strings.ToLower(body.Message)
	if strings.Contains(message, "subscription limit") || strings.Contains(message, "cost") {
		return true
	}
	remaining, err := strconv.Atoi(response.Header.Get("Ratelimit-Remaining"))
	return err == nil && remaining > 0
}

func (a *API) sleep(ctx context.Context, delay time.Duration) error {
	if a.Pause != nil {
		return a.Pause(ctx, delay)
	}
	return clients.Wait(ctx, delay)
}
func (a *API) request(ctx context.Context, method string, q url.Values, body, out interface{}) error {
	client := twitch.New(a.Client, a.ClientID, a.Token)
	if a.BaseURL != "" {
		client.BaseURL = a.BaseURL
	}
	uncertain := false
	failure := func(err error) error {
		if uncertain {
			return &subscriptionlock.UncertainError{Err: err}
		}
		return err
	}
	for attempt := 0; attempt < 4; attempt++ {
		if err := a.Pacer.Wait(ctx); err != nil {
			return failure(err)
		}
		response, err := client.Do(ctx, method, "/eventsub/subscriptions?"+q.Encode(), body)
		if err != nil {
			if method != http.MethodGet {
				uncertain = true
			}
			// A lost POST response may hide a successful creation. Resume must discover it.
			if method == http.MethodPost || attempt == 3 || ctx.Err() != nil {
				return failure(fmt.Errorf("Twitch EventSub transport failure"))
			}
			if err := a.sleep(ctx, time.Duration(1<<attempt)*time.Second); err != nil {
				return failure(err)
			}
			continue
		}
		a.Pacer.Observe(response.Header)
		if response.Err() == nil {
			return response.Decode(out)
		}
		if response.StatusCode == 404 && method == http.MethodDelete {
			return nil
		}
		if response.StatusCode == 429 && method == http.MethodPost && costLimited(response) {
			return failure(fmt.Errorf("%w (HTTP 429)", ErrCostLimit))
		}
		if method != http.MethodGet && response.StatusCode >= 500 {
			uncertain = true
		}
		// An explicit 429 is retryable; ambiguous POST server errors are not.
		if attempt < 3 && (response.StatusCode == 429 || (response.StatusCode >= 500 && method != http.MethodPost)) {
			delay := clients.RetryDelay(response.Header, attempt)
			if delay > 30*time.Second {
				return failure(response.Err())
			}
			if err := a.sleep(ctx, delay); err != nil {
				return failure(err)
			}
			continue
		}
		return failure(response.Err())
	}
	return failure(fmt.Errorf("Twitch EventSub retries exhausted"))
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
		a.Cost.Known, a.Cost.Total, a.Cost.Max = true, page.TotalCost, page.MaxTotalCost
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
