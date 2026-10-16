package subscriptions

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestRateLimitCancellationAndNoAmbiguousPostRetry(t *testing.T) {
	calls := 0
	status := 429
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls++
		w.Header().Set("Retry-After", "30")
		w.WriteHeader(status)
	}))
	defer server.Close()
	api := &API{Tokens: fakeTokens{}, Client: server.Client(), KickURL: server.URL}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Millisecond)
	defer cancel()
	if err := api.request(ctx, "kick", "app-token", http.MethodPost, "/events/subscriptions", nil, map[string]string{"test": "payload"}, nil); err == nil {
		t.Fatal("rate-limit wait ignored cancellation")
	}
	if calls != 1 {
		t.Fatal(calls)
	}
	calls = 0
	status = 500
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
