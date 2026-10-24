package subscriptions

import (
	"context"
	"errors"
	"io"
	"net/http"
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
