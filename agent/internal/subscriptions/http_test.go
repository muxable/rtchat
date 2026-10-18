package subscriptions

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func TestRateLimitCancellationAndNoAmbiguousPostRetry(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	calls, status := 0, 429
	client := &http.Client{Transport: roundTripFunc(func(*http.Request) (*http.Response, error) {
		calls++
		if status == 429 {
			cancel() // Cancel once the rate-limit response arrives, without a timing race.
		}
		return &http.Response{StatusCode: status, Header: http.Header{"Retry-After": {"30"}}, Body: io.NopCloser(strings.NewReader(""))}, nil
	})}
	api := &API{Tokens: fakeTokens{}, Client: client, KickURL: "https://kick.invalid"}
	if err := api.request(ctx, "kick", "app-token", http.MethodPost, "/events/subscriptions", nil, map[string]string{"test": "payload"}, nil); !errors.Is(err, context.Canceled) {
		t.Fatalf("rate-limit wait ignored cancellation: %v", err)
	}
	if calls != 1 {
		t.Fatal(calls)
	}
	calls, status = 0, 500
	if err := api.request(context.Background(), "kick", "app-token", http.MethodPost, "/events/subscriptions", nil, nil, nil); !isStatus(err, 500) {
		t.Fatal(err)
	}
	if calls != 1 {
		t.Fatal("ambiguous POST repeated", calls)
	}
}
func TestTwitchPaginationPreflightsAllLegacyCallbacks(t *testing.T) {
	gets := 0
	mutations := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			mutations++
			w.WriteHeader(202)
			return
		}
		gets++
		if r.URL.Query().Get("after") == "" {
			fmt.Fprint(w, `{"data":[],"pagination":{"cursor":"next"}}`)
			return
		}
		fmt.Fprint(w, `{"data":[{"id":"legacy","type":"stream.offline","version":"1","status":"enabled","condition":{"broadcaster_user_id":"123"},"transport":{"method":"webhook","callback":"https://legacy.example/eventsub"}}]}`)
	}))
	defer server.Close()
	service := &Service{TwitchSecret: "dedicated-secret", API: &API{Tokens: fakeTokens{}, Client: server.Client(), TwitchURL: server.URL}}
	if err := service.ensureTwitch(context.Background(), "123", "app-token"); err == nil {
		t.Fatal("legacy callback accepted")
	}
	if gets != 2 || mutations != 0 {
		t.Fatal(gets, mutations)
	}
}
