package clients_test

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/muxable/rtchat/agent/internal/clients"
	"github.com/muxable/rtchat/agent/internal/clients/kick"
	"github.com/muxable/rtchat/agent/internal/clients/twitch"
	"github.com/muxable/rtchat/agent/internal/clients/youtube"
)

type transport func(*http.Request) (*http.Response, error)

func (f transport) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func TestProviderRequests(t *testing.T) {
	for _, provider := range []string{"twitch", "kick", "youtube", "youtube-key"} {
		t.Run(provider, func(t *testing.T) {
			httpClient := &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
				wantAuth := "Bearer token"
				if provider == "youtube-key" {
					wantAuth = ""
				}
				if r.Header.Get("Authorization") != wantAuth || r.Header.Get("Accept") != "application/json" {
					t.Fatal("wrong authentication or content negotiation")
				}
				if provider == "twitch" && r.Header.Get("Client-Id") != "client-id" {
					t.Fatal("missing Twitch client ID")
				}
				if provider != "twitch" && r.Header.Get("Client-Id") != "" {
					t.Fatal("Twitch credentials leaked to another provider")
				}
				if !strings.HasSuffix(r.URL.Path, "/channels") || r.URL.Query().Get("id") != "a+b&c" {
					t.Fatal("request URL changed")
				}
				return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(`{"id":"123"}`))}, nil
			})}
			var client clients.Client
			switch provider {
			case "twitch":
				client = twitch.New(httpClient, "client-id", "token").Client
			case "kick":
				client = kick.New(httpClient, "token").Client
			case "youtube":
				client = youtube.New(httpClient, "token").Client
			case "youtube-key":
				client = youtube.New(httpClient, "").Client
			}
			var out struct{ ID string }
			if err := client.Get(context.Background(), "/channels?id=a%2Bb%26c", &out); err != nil || out.ID != "123" {
				t.Fatalf("%+v %v", out, err)
			}
		})
	}
}

func TestTwitchValidationUsesOAuth(t *testing.T) {
	client := twitch.New(&http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		if r.URL.String() != "https://id.twitch.tv/oauth2/validate" || r.Header.Get("Authorization") != "OAuth user-token" {
			t.Fatal("wrong Twitch validation request")
		}
		return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(`{"user_id":"123"}`))}, nil
	})}, "client-id", "other-token")
	var result map[string]any
	if err := client.Validate(context.Background(), "user-token", &result); err != nil || result["user_id"] != "123" {
		t.Fatal(result, err)
	}
	if client.Headers.Get("Authorization") != "Bearer other-token" {
		t.Fatal("validation mutated the API client's token")
	}
}

func TestResponsesAndNoAutomaticPostRetry(t *testing.T) {
	for _, tc := range []struct {
		status int
		body   string
	}{
		{204, ""}, {500, "secret provider error"}, {200, "invalid JSON"}, {200, strings.Repeat("x", (8<<20)+1)},
	} {
		calls := 0
		client := kick.New(&http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
			calls++
			body, _ := io.ReadAll(r.Body)
			if string(body) != `{"message":"hello"}` || r.Header.Get("Content-Type") != "application/json" {
				t.Fatal("wrong JSON request")
			}
			return &http.Response{StatusCode: tc.status, Body: io.NopCloser(strings.NewReader(tc.body))}, nil
		})}, "token")
		_, _, err := client.DoJSON(context.Background(), http.MethodPost, "/chat", map[string]string{"message": "hello"})
		if calls != 1 || (err != nil && strings.Contains(err.Error(), "secret")) || (err == nil) != (tc.status == 204) {
			t.Fatalf("status %d, calls %d, err %v", tc.status, calls, err)
		}
	}
}

func TestCanceledRequestAndRetryWait(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	client := twitch.New(&http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		return nil, r.Context().Err()
	})}, "client-id", "token")
	if err := client.Get(ctx, "/users", new(any)); !errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
	if err := clients.Wait(ctx, time.Hour); !errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
	if delay := clients.RetryDelay(http.Header{"Retry-After": {"30"}}, 0); delay != 30*time.Second {
		t.Fatal(delay)
	}
}
