package subscriptions

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/provider"
	"google.golang.org/api/option"
)

type fakeTokens struct{ Missing bool }

func (fakeTokens) AppAccessToken(context.Context, string) (string, error) { return "app-token", nil }
func (f fakeTokens) AccessToken(context.Context, string, string) (string, error) {
	if f.Missing {
		return "", provider.ErrNoToken
	}
	return "user-token", nil
}
func (fakeTokens) Credentials(context.Context, string) (provider.Credentials, error) {
	return provider.Credentials{ClientID: "client"}, nil
}
func database(t *testing.T) *firestore.Client {
	t.Helper()
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST to run subscription integration tests")
	}
	db, err := firestore.NewClient(context.Background(), fmt.Sprintf("subscriptions-%d", time.Now().UnixNano()), option.WithoutAuthentication())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { db.Close() })
	return db
}
func call(s *Service, route, uid, payload string) *httptest.ResponseRecorder {
	server := callable.NewServer(func(_ context.Context, token string) (string, error) {
		if token == "invalid" {
			return "", errors.New("invalid identity")
		}
		return token, nil
	})
	s.Register(server)
	request := httptest.NewRequest(http.MethodPost, "/"+route, strings.NewReader(`{"data":`+payload+`}`))
	request.Header.Set("Content-Type", "application/json")
	if uid != "" {
		request.Header.Set("Authorization", "Bearer "+uid)
	}
	recorder := httptest.NewRecorder()
	server.ServeHTTP(recorder, request)
	return recorder
}
func TestValidationAndAuthentication(t *testing.T) {
	service := &Service{}
	for _, payload := range []string{`{}`, `{"provider":"unknown","channelId":"1"}`, `{"provider":"youtube","channelId":"../../users"}`, `{"provider":"kick","channelId":"9007199254740992"}`, `{"provider":"kick","channelId":"0"}`, `{"provider":"twitch","channelId":"1/2"}`, `{"provider":"kick","channelId":true}`} {
		response := call(service, "subscribe", "", payload)
		if response.Code != 400 || !strings.Contains(response.Body.String(), "INVALID_ARGUMENT") {
			t.Fatal(payload, response.Code, response.Body.String())
		}
	}
	response := call(service, "subscribe", "invalid", `{"provider":"twitch","channelId":"123"}`)
	if response.Code != 401 {
		t.Fatal(response.Code)
	}
	for _, address := range []string{"", "0x1", strings.Repeat("1", 40), "0x" + strings.Repeat("g", 40)} {
		if validAddress(address) {
			t.Error(address)
		}
	}
	if !validAddress("0x" + strings.Repeat("A", 40)) {
		t.Fatal("valid address rejected")
	}
	conditions := twitchConditions("123")
	if len(conditions) != 27 {
		t.Fatal(len(conditions))
	}
	raids := 0
	for _, condition := range conditions {
		if condition.Type == "channel.raid" {
			raids++
		}
		if condition.Type == "channel.follow" && (condition.Version != "2" || condition.Condition["moderator_user_id"] != "123") {
			t.Fatal(condition)
		}
	}
	if raids != 2 {
		t.Fatal(raids)
	}
}
func TestGuestYouTubeAndTwitchAssignments(t *testing.T) {
	db := database(t)
	calls := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls++
		if r.URL.Path != "/users" || r.URL.Query().Get("id") != "123" {
			t.Error(r.URL)
		}
		fmt.Fprint(w, `{"data":[{"id":"123","login":"owner"}]}`)
	}))
	defer server.Close()
	service := &Service{DB: db, API: &API{Tokens: fakeTokens{}, Client: server.Client(), TwitchURL: server.URL}}
	for _, payload := range []string{`{"provider":"youtube","channelId":"UC` + strings.Repeat("a", 22) + `"}`, `{"provider":"twitch","channelId":"123"}`} {
		response := call(service, "subscribe", "", payload)
		if response.Code != 200 {
			t.Fatal(response.Code, response.Body.String())
		}
	}
	docs, err := db.Collection("assignments").Documents(context.Background()).GetAll()
	if err != nil || len(docs) != 2 {
		t.Fatal(len(docs), err)
	}
	if calls != 1 {
		t.Fatal(calls)
	}
}
func TestSignedTwitchConcurrencyWelcomeAndIdentity(t *testing.T) {
	db := database(t)
	ctx := context.Background()
	profileRef := db.Collection("profiles").Doc("owner")
	if _, err := profileRef.Set(ctx, map[string]interface{}{"twitch": map[string]interface{}{"id": "123", "login": "owner"}}); err != nil {
		t.Fatal(err)
	}
	var state []twitchSubscription
	posts := 0
	var mu sync.Mutex
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		defer mu.Unlock()
		if r.Header.Get("Client-ID") != "client" {
			t.Error("missing client ID")
		}
		if r.URL.Path == "/users" {
			fmt.Fprint(w, `{"data":[{"id":"123","login":"owner"}]}`)
			return
		}
		if r.Method == http.MethodGet {
			if r.URL.Query().Get("user_id") != "123" {
				t.Error(r.URL)
			}
			if state == nil {
				fmt.Fprint(w, `{"data":[]}`)
			} else {
				json.NewEncoder(w).Encode(map[string]interface{}{"data": state})
			}
			return
		}
		if r.Method != http.MethodPost {
			t.Error(r.Method)
			w.WriteHeader(400)
			return
		}
		var body struct {
			Type, Version string
			Condition     map[string]string
			Transport     struct{ Method, Callback, Secret string }
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			t.Error(err)
		}
		if body.Transport.Callback != TwitchCallback || body.Transport.Secret != "dedicated-signing-secret" {
			t.Error(body.Transport)
		}
		sub := twitchSubscription{ID: fmt.Sprint(posts), Type: body.Type, Version: body.Version, Status: "webhook_callback_verification_pending", Condition: body.Condition}
		sub.Transport.Callback = TwitchCallback
		sub.Transport.Method = "webhook"
		state = append(state, sub)
		posts++
		w.WriteHeader(202)
	}))
	defer server.Close()
	service := &Service{DB: db, TwitchSecret: "dedicated-signing-secret", API: &API{Tokens: fakeTokens{}, Client: server.Client(), TwitchURL: server.URL}}
	service.Queue = NewTwitchQueue(service)
	var wg sync.WaitGroup
	for i := 0; i < 3; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			response := call(service, "subscribe", "owner", `{"provider":"twitch","channelId":"123"}`)
			if response.Code != 200 {
				t.Error(response.Code, response.Body.String())
			}
		}()
	}
	wg.Wait()
	// subscribe leaves EventSub to the worker, and the three opens share one item.
	mu.Lock()
	if posts != 0 || state != nil {
		t.Fatal("EventSub called inline", posts)
	}
	mu.Unlock()
	if depth(service.Queue) != 1 {
		t.Fatal(depth(service.Queue))
	}
	for depth(service.Queue) > 0 {
		service.Queue.step(ctx)
	}
	if posts != 27 {
		t.Fatal("duplicate EventSub posts", posts)
	}
	messages, err := db.Collection("channels").Doc("twitch:123").Collection("messages").Documents(ctx).GetAll()
	if err != nil || len(messages) != 2 {
		t.Fatal(len(messages), err)
	}
	first, _ := db.Collection("channels").Doc("twitch:123").Collection("messages").Doc("welcome-v1-1").Get(ctx)
	second, _ := db.Collection("channels").Doc("twitch:123").Collection("messages").Doc("welcome-v1-2").Get(ctx)
	if !first.Data()["timestamp"].(time.Time).Before(second.Data()["timestamp"].(time.Time)) {
		t.Fatal("welcome ordering lost")
	}
	if first.Data()["tags"].(map[string]interface{})["user-id"] != "158394109" {
		t.Fatal(first.Data())
	}
	doc, _ := profileRef.Get(ctx)
	if doc.Data()["lastActiveAt"] == nil || doc.Data()["welcomePendingChannel"] != nil {
		t.Fatal(doc.Data())
	}
	if response := call(service, "subscribe", "viewer", `{"provider":"twitch","channelId":"123"}`); response.Code != 200 {
		t.Fatal(response.Body.String())
	}
	if posts != 27 || depth(service.Queue) != 0 {
		t.Fatal(posts)
	}
	// Simulate interruption after the first welcome write. A retry repairs the
	// missing message without replacing the first message or creating a third.
	if _, err := second.Ref.Delete(ctx); err != nil {
		t.Fatal(err)
	}
	if _, err := profileRef.Set(ctx, map[string]interface{}{"welcomePendingChannel": "123"}, firestore.MergeAll); err != nil {
		t.Fatal(err)
	}
	response := call(service, "subscribe", "owner", `{"provider":"twitch","channelId":"123"}`)
	if response.Code != 200 {
		t.Fatal(response.Code, response.Body.String())
	}
	repaired, err := first.Ref.Get(ctx)
	if err != nil || !repaired.UpdateTime.Equal(first.UpdateTime) {
		t.Fatal("first welcome replaced", err)
	}
	messages, err = db.Collection("channels").Doc("twitch:123").Collection("messages").Documents(ctx).GetAll()
	if err != nil || len(messages) != 2 {
		t.Fatal(len(messages), err)
	}
}
func TestTwitchStaleIdentityAndLegacyCallbackGate(t *testing.T) {
	for _, mode := range []string{"stale", "missing-token", "legacy"} {
		t.Run(mode, func(t *testing.T) {
			db := database(t)
			ctx := context.Background()
			db.Collection("profiles").Doc("owner").Set(ctx, map[string]interface{}{"twitch": map[string]interface{}{"id": "123"}})
			posts := 0
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if r.URL.Path == "/users" {
					if mode == "stale" && r.Header.Get("Authorization") == "Bearer user-token" {
						fmt.Fprint(w, `{"data":[{"id":"999","login":"different"}]}`)
					} else {
						fmt.Fprint(w, `{"data":[{"id":"123","login":"owner"}]}`)
					}
					return
				}
				if r.Method == http.MethodPost {
					posts++
					w.WriteHeader(202)
					return
				}
				fmt.Fprint(w, `{"data":[{"id":"legacy","type":"channel.follow","version":"2","status":"enabled","condition":{"broadcaster_user_id":"123","moderator_user_id":"123"},"transport":{"method":"webhook","callback":"https://legacy.example/eventsub"}}]}`)
			}))
			defer server.Close()
			service := &Service{DB: db, TwitchSecret: "dedicated-signing-secret", API: &API{Tokens: fakeTokens{Missing: mode == "missing-token"}, Client: server.Client(), TwitchURL: server.URL}}
			service.Queue = NewTwitchQueue(service)
			response := call(service, "subscribe", "owner", `{"provider":"twitch","channelId":"123"}`)
			// The identity gate still answers the caller. The callback gate runs
			// on the worker, which drops the broadcaster without creating anything.
			if mode == "legacy" {
				if response.Code != 200 || depth(service.Queue) != 1 {
					t.Fatal(response.Code, response.Body.String())
				}
				service.Queue.step(ctx)
			} else if response.Code < 400 || depth(service.Queue) != 0 {
				t.Fatal(response.Code, response.Body.String())
			}
			if posts != 0 || depth(service.Queue) != 0 {
				t.Fatal("created before identity/callback gate", posts)
			}
		})
	}
}
func TestDonationOwnershipAndNormalization(t *testing.T) {
	db := database(t)
	service := &Service{DB: db, MaticWebhookID: "webhook"}
	response := call(service, "setRealTimeCashAddress", "", `{"address":"0x`+strings.Repeat("a", 40)+`"}`)
	if response.Code != 401 {
		t.Fatal(response.Code)
	}
	response = call(service, "setRealTimeCashAddress", "owner", `{"address":"bad"}`)
	if response.Code != 400 {
		t.Fatal(response.Code)
	}
	response = call(service, "setRealTimeCashAddress", "owner", `{"uid":"victim","address":"0x`+strings.Repeat("A", 40)+`"}`)
	if response.Code != 200 {
		t.Fatal(response.Code, response.Body.String())
	}
	docs, err := db.Collection("realtimecash").Documents(context.Background()).GetAll()
	if err != nil || len(docs) != 1 || docs[0].Ref.ID != "owner" || docs[0].Data()["address"] != "0x"+strings.Repeat("a", 40) || docs[0].Data()["maticWebhookId"] != "webhook" {
		t.Fatal(docs, err)
	}
}
