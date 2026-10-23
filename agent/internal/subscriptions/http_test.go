package subscriptions

import (
	"context"
	"encoding/json"
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
	if err := api.kick(ctx, "app-token", http.MethodPost, "/events/subscriptions", nil, map[string]string{"test": "payload"}, nil); !errors.Is(err, context.Canceled) {
		t.Fatalf("rate-limit wait ignored cancellation: %v", err)
	}
	if calls != 1 {
		t.Fatal(calls)
	}
	calls, status = 0, 500
	if err := api.kick(context.Background(), "app-token", http.MethodPost, "/events/subscriptions", nil, nil, nil); !isStatus(err, 500) {
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

func TestTwitchLegacyFunctionCallbackCountsAsPresent(t *testing.T) {
	var subs []map[string]interface{}
	for i, wanted := range twitchConditions("123") {
		subs = append(subs, map[string]interface{}{"id": fmt.Sprint("legacy-", i), "type": wanted.Type, "version": wanted.Version, "status": "enabled", "condition": wanted.Condition, "transport": map[string]string{"method": "webhook", "callback": LegacyTwitchCallback}})
	}
	list, err := json.Marshal(map[string]interface{}{"data": subs})
	if err != nil {
		t.Fatal(err)
	}
	mutations := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			mutations++
			w.WriteHeader(202)
			return
		}
		w.Write(list)
	}))
	defer server.Close()
	service := &Service{TwitchSecret: "dedicated-secret", API: &API{Tokens: fakeTokens{}, Client: server.Client(), TwitchURL: server.URL}}
	if err := service.ensureTwitch(context.Background(), "123", "app-token"); err != nil {
		t.Fatal(err)
	}
	if mutations != 0 {
		t.Fatal("changed subscriptions that the legacy function forwards", mutations)
	}
}

func TestTwitchRejectedTypesDoNotFailTheRest(t *testing.T) {
	posts := map[string]int{}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			fmt.Fprint(w, `{"data":[]}`)
			return
		}
		var body struct {
			Type string `json:"type"`
		}
		json.NewDecoder(r.Body).Decode(&body)
		posts[body.Type]++
		switch {
		case strings.HasPrefix(body.Type, "channel.hype_train."):
			w.WriteHeader(400)
			fmt.Fprint(w, `{"error":"Bad Request","status":400,"message":"invalid subscription type and version"}`)
		case body.Type == "stream.online":
			// the cost limit is full, with rate-limit budget left.
			w.Header().Set("Ratelimit-Remaining", "700")
			w.WriteHeader(429)
			fmt.Fprint(w, `{"error":"Too Many Requests","status":429,"message":"subscription limit exceeded"}`)
		default:
			w.WriteHeader(202)
		}
	}))
	defer server.Close()
	service := &Service{TwitchSecret: "dedicated-secret", API: &API{Tokens: fakeTokens{}, Client: server.Client(), TwitchURL: server.URL}}
	if err := service.ensureTwitch(context.Background(), "123", "app-token"); err != nil {
		t.Fatal(err)
	}
	if posts["stream.online"] != 1 || posts["channel.hype_train.begin"] != 1 {
		t.Fatal("rejected types were retried", posts)
	}
	if posts["channel.follow"] != 1 || posts["stream.offline"] != 1 {
		t.Fatal("types after a rejection were not created", posts)
	}
}
