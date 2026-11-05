package jobs

import (
	"context"
	"errors"
	"io"
	"net/http"
	"net/url"
	"strings"
	"testing"
	"testing/synctest"
	"time"
)

func TestRetryExhaustionPreservesProviderStatusAndEndpoint(t *testing.T) {
	for _, provider := range []string{"twitch", "kick"} {
		for _, code := range []int{429, 503} {
			t.Run(provider+http.StatusText(code), func(t *testing.T) {
				synctest.Test(t, func(t *testing.T) {
					calls := 0
					a := &API{Tokens: testTokens{}, Client: &http.Client{Transport: lifecycleTransport(func(r *http.Request) (*http.Response, error) {
						calls++
						return &http.Response{StatusCode: code, Header: http.Header{}, Body: io.NopCloser(strings.NewReader(`{"secret":"private-provider-detail"}`))}, nil
					})}}
					fetch := a.twitch
					if provider == "kick" {
						fetch = a.kick
					}
					started := time.Now()
					err := fetch(context.Background(), http.MethodGet, "/channels", url.Values{"broadcaster_id": {"private-query-value"}}, nil)
					var response *HTTPError
					if !errors.As(err, &response) || response.Status != code || calls != 4 {
						t.Fatalf("calls=%d error=%v", calls, err)
					}
					if !strings.Contains(err.Error(), "GET /channels") || !strings.Contains(strings.ToLower(err.Error()), provider) || strings.Contains(err.Error(), "private-") {
						t.Fatal(err)
					}
					if time.Since(started) != 7*time.Second {
						t.Fatalf("waited after final attempt: %s", time.Since(started))
					}
				})
			})
		}
	}
}

func TestOverBudgetRetryRetainsHTTPError(t *testing.T) {
	a := &API{Tokens: testTokens{}, Client: &http.Client{Transport: lifecycleTransport(func(*http.Request) (*http.Response, error) {
		return &http.Response{StatusCode: 429, Header: http.Header{"Retry-After": {"61"}}, Body: io.NopCloser(strings.NewReader(`{}`))}, nil
	})}}
	err := a.twitch(context.Background(), http.MethodGet, "/channels/followers", nil, nil)
	var response *HTTPError
	if !errors.As(err, &response) || response.Status != 429 || !strings.Contains(err.Error(), "job budget") {
		t.Fatal(err)
	}
}

func TestPollingCancellationStillUnwraps(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	a := &API{Tokens: testTokens{}, Client: &http.Client{Transport: lifecycleTransport(func(*http.Request) (*http.Response, error) {
		return nil, context.Canceled
	})}}
	if err := a.kick(ctx, http.MethodGet, "/channels", nil, nil); !errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
}
