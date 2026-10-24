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
	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
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

func (a *API) twitchClient(ctx context.Context, token string) (*clients.Client, error) {
	credentials, err := a.Tokens.Credentials(ctx, "twitch")
	if err != nil {
		return nil, err
	}
	client := twitch.New(a.Client, credentials.ClientID, token)
	if a.TwitchURL != "" {
		client.BaseURL = a.TwitchURL
	}
	return &client.Client, nil
}

func (a *API) twitch(ctx context.Context, token, method, path string, q url.Values, body, out any) error {
	client, err := a.twitchClient(ctx, token)
	if err != nil {
		return err
	}
	return request(ctx, client, method, path+"?"+q.Encode(), body, out)
}

// twitchOnce sends a single request and passes its headers to observe. Callers
// schedule any retry themselves from a returned *retryError.
func (a *API) twitchOnce(ctx context.Context, token, method, path string, q url.Values, body, out any, observe func(http.Header)) error {
	client, err := a.twitchClient(ctx, token)
	if err != nil {
		return err
	}
	return requestOnce(ctx, client, method, path+"?"+q.Encode(), body, out, observe)
}

func (a *API) kick(ctx context.Context, token, method, path string, q url.Values, body, out any) error {
	client := kick.New(a.Client, token)
	if a.KickURL != "" {
		client.BaseURL = a.KickURL
	}
	return request(ctx, &client.Client, method, path+"?"+q.Encode(), body, out)
}

// costLimitError is Twitch's 429 for a full EventSub cost limit. It leaves
// rate-limit budget, and retrying cannot succeed until there is headroom.
type costLimitError struct{ Err error }

func (e *costLimitError) Error() string { return e.Err.Error() }
func (e *costLimitError) Unwrap() error { return e.Err }

// retryError is a rejection that may be retried later: a rate-limit 429 or a
// 5xx for an idempotent GET. Header carries Retry-After and Ratelimit-Reset.
type retryError struct {
	Err    error
	Header http.Header
}

func (e *retryError) Error() string { return e.Err.Error() }
func (e *retryError) Unwrap() error { return e.Err }

// requestOnce sends one request. Only an explicit rate-limit rejection or an
// idempotent GET is reported as retryable.
func requestOnce(ctx context.Context, client *clients.Client, method, path string, body, out any, observe func(http.Header)) error {
	response, err := client.Do(ctx, method, path, body)
	if err != nil {
		if method != http.MethodGet {
			return &subscriptionlock.UncertainError{Err: err}
		}
		return err
	}
	if observe != nil {
		observe(response.Header)
	}
	if response.Err() == nil {
		return response.Decode(out)
	}
	// Twitch also answers 429 when the EventSub cost limit is full, with
	// rate-limit budget left. Retrying that cannot succeed.
	if response.StatusCode == 429 && response.Header.Get("Ratelimit-Remaining") != "" && response.Header.Get("Ratelimit-Remaining") != "0" {
		return &costLimitError{Err: response.Err()}
	}
	if response.StatusCode == 429 || (method == http.MethodGet && response.StatusCode >= 500) {
		return &retryError{Err: response.Err(), Header: response.Header}
	}
	if method != http.MethodGet && response.StatusCode >= 500 {
		return &subscriptionlock.UncertainError{Err: response.Err()}
	}
	return response.Err()
}

// request retries short server-requested delays for synchronous callers.
func request(ctx context.Context, client *clients.Client, method, path string, body, out any) error {
	for attempt := 0; attempt < 3; attempt++ {
		err := requestOnce(ctx, client, method, path, body, out, nil)
		var retry *retryError
		if !errors.As(err, &retry) {
			return err
		}
		delay := clients.RetryDelay(retry.Header, attempt)
		if attempt == 2 || delay > 30*time.Second {
			return retry.Err
		}
		if err := clients.Wait(ctx, delay); err != nil {
			return err
		}
	}
	return errors.New("provider retry limit reached")
}
