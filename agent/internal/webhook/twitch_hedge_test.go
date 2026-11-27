package webhook

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"sync/atomic"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/hedge"
	"google.golang.org/api/option"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type emulatorAdmin struct{}

func (emulatorAdmin) GetRequestMetadata(context.Context, ...string) (map[string]string, error) {
	return map[string]string{"authorization": "Bearer owner"}, nil
}
func (emulatorAdmin) RequireTransportSecurity() bool { return false }

// The production alert: one EventSub write's Firestore commit hung until the
// client's 60s timeout, long after Twitch had stopped waiting.
func TestTwitchEventSubSurvivesStalledCommit(t *testing.T) {
	address := os.Getenv("FIRESTORE_EMULATOR_HOST")
	if address == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST")
	}
	for _, hedged := range []bool{false, true} {
		t.Run(fmt.Sprint("hedged=", hedged), func(t *testing.T) {
			var commits atomic.Int32
			stallFirst := func(ctx context.Context, method string, req, reply any, cc *grpc.ClientConn, invoker grpc.UnaryInvoker, opts ...grpc.CallOption) error {
				if method == "/google.firestore.v1.Firestore/Commit" && commits.Add(1) == 1 {
					<-ctx.Done()
					return ctx.Err()
				}
				return invoker(ctx, method, req, reply, cc, opts...)
			}
			chain := []grpc.UnaryClientInterceptor{stallFirst}
			if hedged {
				chain = []grpc.UnaryClientInterceptor{hedge.Interceptor, stallFirst}
			}
			conn, err := grpc.NewClient(address, grpc.WithTransportCredentials(insecure.NewCredentials()), grpc.WithPerRPCCredentials(emulatorAdmin{}), grpc.WithChainUnaryInterceptor(chain...))
			if err != nil {
				t.Fatal(err)
			}
			db, err := firestore.NewClient(context.Background(), fmt.Sprintf("eventsub-%d", time.Now().UnixNano()), option.WithGRPCConn(conn))
			if err != nil {
				t.Fatal(err)
			}
			defer db.Close()
			handler := &TwitchHandler{Secret: "secret", Store: twitchFirestoreStore{client: db}}
			body := `{"subscription":{"type":"stream.online","version":"1","status":"enabled"},"event":{"broadcaster_user_id":"1337"}}`
			// Twitch stops waiting within a few seconds.
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()
			request := signedTwitchRequest(body, "notification", time.Now().UTC().Format(time.RFC3339Nano)).WithContext(ctx)
			response := httptest.NewRecorder()
			started := time.Now()
			handler.ServeHTTP(response, request)
			if hedged != (response.Code == http.StatusOK) || (hedged && time.Since(started) > 4*time.Second) {
				t.Fatalf("hedged=%v: status %d after %v", hedged, response.Code, time.Since(started))
			}
			if !hedged {
				return
			}
			for _, path := range []string{"channels/twitch:1337/messages/twitch:message-id", "channels/twitch:1337"} {
				if _, err := db.Doc(path).Get(context.Background()); err != nil {
					t.Fatalf("%s not written: %v", path, err)
				}
			}
		})
	}
}
