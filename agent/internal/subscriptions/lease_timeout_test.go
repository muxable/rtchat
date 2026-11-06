package subscriptions

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/muxable/rtchat/agent/internal/callable"
)

func TestSubscribeReturnsRetryableErrorForBusyLease(t *testing.T) {
	for _, provider := range []string{"twitch", "kick"} {
		t.Run(provider, func(t *testing.T) {
			db := database(t)
			ctx := context.Background()
			if _, err := db.Collection("profiles").Doc("owner").Set(ctx, map[string]interface{}{"twitch": map[string]interface{}{"id": "123", "login": "owner"}}); err != nil {
				t.Fatal(err)
			}
			if _, err := db.Collection("subscriptionLeases").Doc(provider+":123").Set(ctx, map[string]interface{}{"owner": "reconcile-worker", "until": time.Now().Add(90 * time.Second)}); err != nil {
				t.Fatal(err)
			}
			upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { fmt.Fprint(w, `{"data":[{"id":"123","login":"owner"}]}`) }))
			defer upstream.Close()
			service := &Service{DB: db, TwitchSecret: "signing-secret", API: &API{Tokens: fakeTokens{}, Client: upstream.Client(), TwitchURL: upstream.URL}}
			service.Queue = NewTwitchQueue(service)
			server := callable.NewServer(func(context.Context, string) (string, error) { return "owner", nil })
			service.Register(server)
			bounded, cancel := context.WithTimeout(ctx, 12*time.Second)
			defer cancel()
			request := httptest.NewRequest(http.MethodPost, "/subscribe", strings.NewReader(fmt.Sprintf(`{"data":{"provider":%q,"channelId":"123"}}`, provider))).WithContext(bounded)
			request.Header.Set("Content-Type", "application/json")
			request.Header.Set("Authorization", "Bearer owner")
			response := httptest.NewRecorder()
			started := time.Now()
			server.ServeHTTP(response, request)
			if response.Code != http.StatusServiceUnavailable || !strings.Contains(response.Body.String(), "UNAVAILABLE") {
				t.Fatalf("busy subscribe returned %d after %s: %s", response.Code, time.Since(started), response.Body.String())
			}
			if elapsed := time.Since(started); elapsed > 11*time.Second {
				t.Fatalf("busy subscribe waited %s", elapsed)
			}
			lease, err := db.Collection("subscriptionLeases").Doc(provider + ":123").Get(context.Background())
			if err != nil {
				t.Fatal(err)
			}
			if lease.Data()["owner"] != "reconcile-worker" {
				t.Fatal("busy request changed lease owner", lease.Data())
			}
			if depth(service.Queue) != 0 {
				t.Fatal("busy subscription queued work without its lifecycle lease")
			}
			profile, err := db.Collection("profiles").Doc("owner").Get(context.Background())
			if err != nil {
				t.Fatal(err)
			}
			if profile.Data()["lastActiveAt"] != nil || profile.Data()["welcomePendingChannel"] != nil {
				t.Fatal("busy subscription changed profile", profile.Data())
			}

		})
	}
}

// A reconcile holds a broadcaster's lease for the EventSub creation an earlier
// open queued, often longer than subscribe waits. Subscribe does none of that
// work under the lease, so it runs beside a reconcile instead of failing.
func TestSubscribeRunsBesideReconcile(t *testing.T) {
	db := database(t)
	ctx := context.Background()
	if _, err := db.Collection("profiles").Doc("owner").Set(ctx, map[string]interface{}{"twitch": map[string]interface{}{"id": "123", "login": "owner"}, "lastActiveAt": time.Now()}); err != nil {
		t.Fatal(err)
	}
	lease := map[string]interface{}{"owner": "reconcile-worker", "until": time.Now().Add(90 * time.Second), "job": "reconcile"}
	if _, err := db.Collection("subscriptionLeases").Doc("twitch:123").Set(ctx, lease); err != nil {
		t.Fatal(err)
	}
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { fmt.Fprint(w, `{"data":[{"id":"123","login":"owner"}]}`) }))
	defer upstream.Close()
	service := &Service{DB: db, TwitchSecret: "signing-secret", API: &API{Tokens: fakeTokens{}, Client: upstream.Client(), TwitchURL: upstream.URL}}
	service.Queue = NewTwitchQueue(service)
	started := time.Now()
	response := call(service, "subscribe", "owner", `{"provider":"twitch","channelId":"123"}`)
	if response.Code != http.StatusOK || time.Since(started) > 2*time.Second {
		t.Fatalf("subscribe beside a reconcile returned %d after %s: %s", response.Code, time.Since(started), response.Body.String())
	}
	held, err := db.Collection("subscriptionLeases").Doc("twitch:123").Get(ctx)
	if err != nil || held.Data()["owner"] != "reconcile-worker" {
		t.Fatalf("subscribe took or released the reconcile's lease: %v %v", held.Data(), err)
	}
	if depth(service.Queue) != 1 {
		t.Fatal("subscribe beside a reconcile queued no follow-up reconcile")
	}
	channel, err := db.Collection("channels").Doc("twitch:123").Get(ctx)
	if err != nil || channel.Data()["lastActiveAt"] == nil {
		t.Fatalf("channel activity not recorded: %v", err)
	}
}
