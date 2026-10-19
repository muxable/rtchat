package subscriptions

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"testing"
	"time"
)

func TestKickIDsUseOneCanonicalLifecycle(t *testing.T) {
	db := database(t)
	fixture := &kickFixture{state: map[string][]kickSubscription{}}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			q := r.URL.Query()
			id, _ := strconv.ParseUint(q.Get("broadcaster_user_id"), 10, 53)
			q.Set("broadcaster_user_id", strconv.FormatUint(id, 10))
			r.URL.RawQuery = q.Encode()
		}
		fixture.handler(w, r)
	}))
	defer server.Close()
	service := &Service{DB: db, Enabled: true, API: &API{Tokens: fakeTokens{}, Client: server.Client(), KickURL: server.URL}}
	for _, id := range []string{"00123", "123"} {
		response := call(service, "subscribe", "", `{"provider":"kick","channelId":"`+id+`"}`)
		var body struct{ Result string }
		if err := json.Unmarshal(response.Body.Bytes(), &body); err != nil || response.Code != 200 || body.Result != "123" {
			t.Fatalf("noncanonical subscription: %d %s", response.Code, response.Body.String())
		}
	}
	docs, err := db.Collection("webhooks").Documents(context.Background()).GetAll()
	if err != nil || len(docs) != 1 || docs[0].Ref.ID != "kick:123" || fixture.posts != 1 {
		t.Fatalf("aliased lifecycle: docs=%d posts=%d err=%v", len(docs), fixture.posts, err)
	}
}

func TestUncertainKickCreationRetainsLifecycleLeases(t *testing.T) {
	for _, canceled := range []bool{false, true} {
		t.Run(strconv.FormatBool(canceled), func(t *testing.T) {
			db := database(t)
			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()
			posts := 0
			client := &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
				if r.Method == http.MethodGet {
					return &http.Response{StatusCode: 200, Header: make(http.Header), Body: io.NopCloser(strings.NewReader(`{"data":[]}`))}, nil
				}
				posts++
				// Model a remote POST still processing after its response is lost. A
				// client timeout need not cancel the lifecycle's parent context.
				if canceled {
					cancel()
					return nil, context.Canceled
				}
				return nil, context.DeadlineExceeded
			})}
			service := &Service{DB: db, Enabled: true, API: &API{Tokens: fakeTokens{}, Client: client}}
			input := json.RawMessage(`{"provider":"kick","channelId":"123"}`)
			if _, err := service.Subscribe(ctx, input); err == nil {
				t.Fatal("lost POST response accepted")
			}
			for _, key := range []string{"kick:123", "kick-capacity"} {
				lease, err := db.Collection("subscriptionLeases").Doc(key).Get(context.Background())
				if err != nil {
					t.Fatalf("uncertain mutation released %s: %v", key, err)
				}
				if until, _ := lease.Data()["until"].(time.Time); !until.After(time.Now()) {
					t.Fatal("safety window lost")
				}
			}
			retry, stop := context.WithTimeout(context.Background(), 50*time.Millisecond)
			defer stop()
			if _, err := service.Subscribe(retry, input); err == nil {
				t.Fatal("retry bypassed uncertain creation")
			}
			if posts != 1 {
				t.Fatalf("overlapping creation POSTs: %d", posts)
			}
			if !canceled && ctx.Err() != nil {
				t.Fatal("client timeout incorrectly canceled the parent")
			}
		})
	}
}
