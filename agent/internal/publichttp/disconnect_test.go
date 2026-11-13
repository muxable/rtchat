package publichttp

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/muxable/rtchat/agent/internal/webhook"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"
)

// The app's WebView aborts /embed when the preview closes or switches
// channel. The provider lookup then fails at once on the canceled request;
// a caller that left is not a server failure.
func TestEmbedAbortedByClientIsNotAnError(t *testing.T) {
	core, logs := observer.New(zap.InfoLevel)
	defer zap.ReplaceGlobals(zap.New(core))()
	s, _, mux := fixture()
	s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		if err := r.Context().Err(); err != nil {
			return nil, err
		}
		return response(200, `{"data":[{"id":"1","login":"streamer"}]}`), nil
	})}
	ctx, hangUp := context.WithCancel(context.Background())
	hangUp()
	request := httptest.NewRequestWithContext(ctx, http.MethodGet, "/embed?provider=twitch&channelId=1", nil)
	webhook.LoggingMiddleware(mux).ServeHTTP(httptest.NewRecorder(), request)
	entries := logs.FilterMessage("http request").All()
	if len(entries) != 1 || entries[0].Level != zap.InfoLevel || entries[0].ContextMap()["status"] != int64(499) {
		t.Fatalf("aborted embed logged as %v", entries)
	}
}
