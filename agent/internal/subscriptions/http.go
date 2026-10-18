package subscriptions

import (
	"context"
	"errors"
	"net/http"
	"net/url"
	"time"

	"github.com/muxable/rtchat/agent/internal/clients"
	"github.com/muxable/rtchat/agent/internal/clients/kick"
	"github.com/muxable/rtchat/agent/internal/clients/twitch"
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
type APIError = clients.HTTPError

func (a *API) twitch(ctx context.Context, token, method, path string, q url.Values, body, out any) error {
	credentials, err := a.Tokens.Credentials(ctx, "twitch")
	if err != nil {
		return err
	}
	client := twitch.New(a.Client, credentials.ClientID, token)
	if a.TwitchURL != "" {
		client.BaseURL = a.TwitchURL
	}
	return request(ctx, &client.Client, method, path+"?"+q.Encode(), body, out)
}

func (a *API) kick(ctx context.Context, token, method, path string, q url.Values, body, out any) error {
	client := kick.New(a.Client, token)
	if a.KickURL != "" {
		client.BaseURL = a.KickURL
	}
	return request(ctx, &client.Client, method, path+"?"+q.Encode(), body, out)
}

// Only an explicit rate-limit rejection or an idempotent GET may be retried.
func request(ctx context.Context, client *clients.Client, method, path string, body, out any) error {
	for attempt := 0; attempt < 3; attempt++ {
		response, err := client.Do(ctx, method, path, body)
		if err != nil {
			return err
		}
		if response.Err() == nil {
			return response.Decode(out)
		}
		if response.StatusCode == 429 || (method == http.MethodGet && response.StatusCode >= 500) {
			delay := clients.RetryDelay(response.Header, attempt)
			if attempt == 2 || delay > 30*time.Second {
				return response.Err()
			}
			if err := clients.Wait(ctx, delay); err != nil {
				return err
			}
			continue
		}
		return response.Err()
	}
	return errors.New("provider retry limit reached")
}
