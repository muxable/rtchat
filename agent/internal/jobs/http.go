package jobs

import (
	"context"
	"errors"
	"net/http"
	"net/url"
	"time"

	"github.com/muxable/rtchat/agent/internal/clients"
	"github.com/muxable/rtchat/agent/internal/clients/kick"
	"github.com/muxable/rtchat/agent/internal/clients/twitch"
	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
)

type HTTPError = clients.HTTPError

type Tokens interface {
	AppAccessToken(context.Context, string) (string, error)
}
type API struct {
	Tokens             Tokens
	Client             *http.Client
	TwitchClientID     string
	TwitchURL, KickURL string
}

func (a *API) twitch(ctx context.Context, method, path string, query url.Values, out any) error {
	token, err := a.Tokens.AppAccessToken(ctx, "twitch")
	if err != nil {
		return err
	}
	client := twitch.New(a.Client, a.TwitchClientID, token)
	if a.TwitchURL != "" {
		client.BaseURL = a.TwitchURL
	}
	return request(ctx, &client.Client, method, path+"?"+query.Encode(), out)
}

func (a *API) kick(ctx context.Context, method, path string, query url.Values, out any) error {
	token, err := a.Tokens.AppAccessToken(ctx, "kick")
	if err != nil {
		return err
	}
	client := kick.New(a.Client, token)
	if a.KickURL != "" {
		client.BaseURL = a.KickURL
	}
	return request(ctx, &client.Client, method, path+"?"+query.Encode(), out)
}

// Job requests are serial and idempotent; deleting an absent subscription succeeds.
func request(ctx context.Context, client *clients.Client, method, path string, out any) error {
	uncertain := false
	failure := func(err error) error {
		if uncertain {
			return &subscriptionlock.UncertainError{Err: err}
		}
		return err
	}
	for attempt := 0; attempt < 4; attempt++ {
		response, err := client.Do(ctx, method, path, nil)
		if err != nil {
			if method == http.MethodDelete {
				uncertain = true
			}
			return failure(err)
		}
		if response.Err() == nil {
			return response.Decode(out)
		}
		if method == http.MethodDelete && response.StatusCode == http.StatusNotFound {
			return nil
		}
		if response.StatusCode != 429 && response.StatusCode < 500 {
			return failure(response.Err())
		}
		if method == http.MethodDelete && response.StatusCode >= 500 {
			uncertain = true
		}
		delay := clients.RetryDelay(response.Header, attempt)
		if delay > time.Minute {
			return failure(errors.New("rate limit retry exceeds job budget"))
		}
		if err := clients.Wait(ctx, delay); err != nil {
			return failure(err)
		}
	}
	return failure(errors.New("provider retry limit reached"))
}

func params(key string, ids []string) url.Values {
	v := url.Values{}
	for _, id := range ids {
		v.Add(key, id)
	}
	return v
}
