package catalog

import (
	"context"
	"errors"
	"net/http"
	"net/url"
	"strings"
	"testing"
	"testing/synctest"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/clients"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"
)

func TestEmoteProviderFailureKeepsLogContextAndGenericResponse(t *testing.T) {
	for _, tc := range []struct {
		name, want string
		status     int
		body       string
		transport  bool
	}{
		{name: "rate limit", status: 429, body: `{"message":"secret-provider-body"}`, want: "provider returned HTTP 429"},
		{name: "upstream failure", status: 502, body: "secret-provider-body", want: "provider returned HTTP 502"},
		{name: "invalid JSON", status: 200, body: "secret-provider-body", want: "invalid provider response"},
		{name: "missing user", status: 200, body: `{"data":[]}`, want: "provider response missing user login"},
		{name: "transport failure", transport: true, want: "provider transport failure"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			s, _, tokens := fixture()
			tokens.user["uid:twitch"] = "secret-access-token"
			s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
				if r.URL.Host == "api.twitch.tv" {
					if tc.transport {
						return nil, errors.New("transport failed with secret-access-token")
					}
					return response(tc.status, tc.body), nil
				}
				return response(200, `{}`), nil
			})}
			core, logs := observer.New(zap.ErrorLevel)
			defer zap.ReplaceGlobals(zap.New(core))()
			status, result := invoke(t, s, "getEmotes", `{"provider":"twitch","channelId":"123"}`, "uid")
			failure := object(result["error"])
			if status != 503 || failure["status"] != "UNAVAILABLE" || failure["message"] != "provider temporarily unavailable" {
				t.Fatalf("client response changed: status=%d body=%v", status, result)
			}
			if logs.Len() != 1 {
				t.Fatalf("got %d error logs, want one", logs.Len())
			}
			message, _ := logs.All()[0].ContextMap()["error"].(string)
			if !strings.Contains(message, "twitch users") || !strings.Contains(message, tc.want) {
				t.Fatalf("upstream context missing: %q", message)
			}
			if strings.Contains(message, "secret-") {
				t.Fatalf("provider credentials or response body leaked: %q", message)
			}
		})
	}
}

func TestTwitchFailurePreservesErrorTypes(t *testing.T) {
	s, _, _ := fixture()
	s.HTTP = &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) {
		return response(503, `{}`), nil
	})}
	_, err := s.twitch(context.Background(), "users", "token", url.Values{})
	var apiError *callable.Error
	var upstream *clients.HTTPError
	if !errors.As(err, &apiError) || apiError.Code != "unavailable" || !errors.As(err, &upstream) || upstream.Status != 503 {
		t.Fatalf("error types lost: %v", err)
	}
}

// A token-store failure must remain distinguishable from a Twitch HTTP failure.
type errorTokens struct {
	Tokens
	cause error
}

func (f errorTokens) AccessToken(context.Context, string, string) (string, error) {
	return "", f.cause
}

func TestUserTokenFailurePreservesCause(t *testing.T) {
	s, _, _ := fixture()
	cause := errors.New("token storage unavailable")
	s.Tokens = errorTokens{Tokens: s.Tokens, cause: cause}
	_, err := s.userToken(context.Background(), "uid")
	var apiError *callable.Error
	if !errors.Is(err, cause) || !errors.As(err, &apiError) || apiError.Code != "unavailable" || !strings.Contains(err.Error(), "twitch access token") {
		t.Fatalf("token failure context lost: %v", err)
	}
}

func TestEmotesRecoverFromTransientProviderError(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		s, _, tokens := fixture()
		tokens.user["uid:twitch"] = "token"
		calls := 0
		s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
			if r.URL.Host != "api.twitch.tv" {
				return response(404, `{}`), nil
			}
			if r.URL.Path == "/helix/users" {
				calls++
				if calls == 1 {
					return response(503, `{}`), nil
				}
				return response(200, `{"data":[{"id":"7","login":"viewer"}]}`), nil
			}
			return response(200, `{"data":[]}`), nil
		})}
		core, logs := observer.New(zap.ErrorLevel)
		defer zap.ReplaceGlobals(zap.New(core))()
		status, result := invoke(t, s, "getEmotes", `{"provider":"twitch","channelId":"123"}`, "uid")
		if status != 200 || result["result"] == nil || calls != 2 || logs.Len() != 0 {
			t.Fatalf("status=%d response=%v calls=%d error logs=%d", status, result, calls, logs.Len())
		}
	})
}
