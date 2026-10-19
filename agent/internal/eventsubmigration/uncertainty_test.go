package eventsubmigration

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
)

func TestMutationServerFailuresRemainUncertain(t *testing.T) {
	for _, method := range []string{http.MethodGet, http.MethodPost, http.MethodDelete} {
		t.Run(method, func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(503) }))
			defer server.Close()
			api := API{Client: server.Client(), BaseURL: server.URL, Pause: func(context.Context, time.Duration) error { return nil }}
			err := api.request(context.Background(), method, nil, nil, nil)
			var uncertain *subscriptionlock.UncertainError
			if err == nil || errors.As(err, &uncertain) != (method != http.MethodGet) {
				t.Fatalf("wrong uncertainty for %s: %v", method, err)
			}
			var status *HTTPError
			if !errors.As(err, &status) || status.Status != 503 {
				t.Fatalf("status lost: %v", err)
			}
		})
	}
}
