package jobs

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/muxable/rtchat/agent/internal/clients"
	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
)

type lifecycleTransport func(*http.Request) (*http.Response, error)

func (f lifecycleTransport) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func TestCleanupRetainsUncertaintyUntilDeleteIsSettled(t *testing.T) {
	for _, tc := range []struct {
		name, method         string
		statuses             []int
		wantError, uncertain bool
	}{
		{"lost delete response", "DELETE", []int{0}, true, true},
		{"server failure then rate budget", "DELETE", []int{500, 429}, true, true},
		{"only rate rejection", "DELETE", []int{429}, true, false},
		{"get never mutates", "GET", []int{500, 429}, true, false},
		{"delete retries exhausted", "DELETE", []int{500, 500, 500, 500}, true, true},
		{"delete eventually settled", "DELETE", []int{500, 204}, false, false},
		{"already absent", "DELETE", []int{500, 404}, false, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			attempt := 0
			client := clients.Client{BaseURL: "https://provider.invalid", HTTP: &http.Client{Transport: lifecycleTransport(func(*http.Request) (*http.Response, error) {
				status := tc.statuses[attempt]
				attempt++
				if status == 0 {
					return nil, errors.New("response lost")
				}
				delay := "0"
				if status == 429 {
					delay = "61"
				}
				return &http.Response{StatusCode: status, Header: http.Header{"Retry-After": {delay}}, Body: io.NopCloser(strings.NewReader(""))}, nil
			})}}
			err := request(context.Background(), &client, tc.method, "/events/subscriptions", nil)
			var uncertain *subscriptionlock.UncertainError
			if (err != nil) != tc.wantError || errors.As(err, &uncertain) != tc.uncertain {
				t.Fatalf("error=%v, uncertainty=%t", err, uncertain != nil)
			}
			if attempt != len(tc.statuses) {
				t.Fatalf("unexpected retry count %d", attempt)
			}
		})
	}
}
