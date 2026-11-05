package clients_test

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"
	"testing"
	"testing/synctest"
	"time"

	"github.com/muxable/rtchat/agent/internal/clients"
	"github.com/muxable/rtchat/agent/internal/clients/twitch"
)

type retryBody struct {
	io.Reader
	closed bool
}

func (b *retryBody) Close() error { b.closed = true; return nil }

func TestGetRecoversFromServerErrors(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		var calls []time.Time
		var bodies []*retryBody
		statuses := []int{500, 502, 503, 200}
		client := twitch.New(&http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
			if len(bodies) > 0 && !bodies[len(bodies)-1].closed {
				t.Fatal("previous response was not closed before retry")
			}
			if r.Header.Get("Authorization") != "Bearer token" || r.URL.RequestURI() != "/helix/users?id=123" {
				t.Fatal("retry changed the provider request")
			}
			status := statuses[len(calls)]
			calls = append(calls, time.Now())
			body := &retryBody{Reader: strings.NewReader(`{"id":"123"}`)}
			bodies = append(bodies, body)
			return &http.Response{StatusCode: status, Header: http.Header{}, Body: body}, nil
		})}, "client", "token")
		var result struct{ ID string }
		if err := client.Get(context.Background(), "/users?id=123", &result); err != nil || result.ID != "123" {
			t.Fatalf("recovery failed: result=%+v err=%v", result, err)
		}
		if len(calls) != 4 {
			t.Fatalf("got %d requests, want initial plus three retries", len(calls))
		}
		for i := 1; i < len(calls); i++ {
			if delay := calls[i].Sub(calls[i-1]); delay != time.Second<<uint(i-1) {
				t.Fatalf("retry %d delay = %s", i, delay)
			}
		}
		for _, body := range bodies {
			if !body.closed {
				t.Fatal("response body left open")
			}
		}
	})
}

func TestGetStopsAfterThreeRetries(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		calls := 0
		client := clients.Client{BaseURL: "https://provider.test", HTTP: &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) {
			calls++
			return &http.Response{StatusCode: 504, Body: io.NopCloser(strings.NewReader("secret provider body"))}, nil
		})}}
		err := client.Get(context.Background(), "/users", new(any))
		var upstream *clients.HTTPError
		if calls != 4 || !errors.As(err, &upstream) || upstream.Status != 504 || strings.Contains(err.Error(), "secret") {
			t.Fatalf("calls=%d err=%v", calls, err)
		}
	})
}

func TestGetHonorsRetryAfter(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		calls := 0
		client := clients.Client{BaseURL: "https://provider.test", HTTP: &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) {
			calls++
			if calls == 1 {
				return &http.Response{StatusCode: 503, Header: http.Header{"Retry-After": {"3"}}, Body: io.NopCloser(strings.NewReader(""))}, nil
			}
			return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(`{}`))}, nil
		})}}
		start := time.Now()
		if err := client.Get(context.Background(), "/users", new(any)); err != nil || calls != 2 || time.Since(start) != 3*time.Second {
			t.Fatalf("calls=%d elapsed=%s err=%v", calls, time.Since(start), err)
		}
	})
}

func TestGetRetryWaitRespectsContext(t *testing.T) {
	for _, deadline := range []bool{false, true} {
		t.Run(strconv.FormatBool(deadline), func(t *testing.T) {
			synctest.Test(t, func(t *testing.T) {
				ctx, cancel := context.WithTimeout(context.Background(), 250*time.Millisecond)
				want := context.DeadlineExceeded
				if !deadline {
					time.AfterFunc(100*time.Millisecond, cancel)
					want = context.Canceled
				}
				defer cancel()
				calls := 0
				client := clients.Client{BaseURL: "https://provider.test", HTTP: &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) {
					calls++
					return &http.Response{StatusCode: 503, Body: io.NopCloser(strings.NewReader(""))}, nil
				})}}
				if err := client.Get(ctx, "/users", new(any)); !errors.Is(err, want) || calls != 1 {
					t.Fatalf("calls=%d err=%v", calls, err)
				}
			})
		})
	}
}

func TestGetDoesNotRetryClientOrDecodeErrors(t *testing.T) {
	for _, status := range []int{200, 400, 401, 403, 404, 429} {
		t.Run(strconv.Itoa(status), func(t *testing.T) {
			calls := 0
			client := clients.Client{BaseURL: "https://provider.test", HTTP: &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) {
				calls++
				return &http.Response{StatusCode: status, Body: io.NopCloser(strings.NewReader("not JSON"))}, nil
			})}}
			if err := client.Get(context.Background(), "/users", new(any)); err == nil || calls != 1 {
				t.Fatalf("calls=%d err=%v", calls, err)
			}
		})
	}
}
