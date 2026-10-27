package webhook

import (
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func testKickTime(t *testing.T, text string) time.Time {
	t.Helper()
	at, err := time.Parse(time.RFC3339Nano, text)
	if err != nil {
		t.Fatal(err)
	}
	return at.UTC()
}

func kickFixture(t *testing.T, name string) interface{} {
	t.Helper()
	body, err := os.ReadFile(filepath.Join("testdata", "kick", name+".json"))
	if err != nil {
		t.Fatal(err)
	}
	var event interface{}
	if err := json.Unmarshal(body, &event); err != nil {
		t.Fatal(err)
	}
	return event
}

func TestKickEventFixtures(t *testing.T) {
	now := testKickTime(t, "2026-10-12T00:00:00Z")
	for _, tc := range []struct{ eventType, fixture, channelID, id, messageType, at string }{
		{"channel.subscription.new", "channel.subscription.new", "kick:123456789", "kick:01DELIVERY", "kick.channel.subscription.new", "2025-01-14T16:08:06Z"},
		{"channel.subscription.renewal", "channel.subscription.renewal", "kick:123456789", "kick:01DELIVERY", "kick.channel.subscription.renewal", "2025-01-14T16:08:06Z"},
		{"channel.subscription.gifts", "channel.subscription.gifts", "kick:123456789", "kick:01DELIVERY", "kick.channel.subscription.gifts", "2025-01-14T16:08:06Z"},
		{"channel.subscription.gifts", "channel.subscription.gifts.anonymous", "kick:123456789", "kick:01DELIVERY", "kick.channel.subscription.gifts", "2025-01-14T16:08:06Z"},
		{"kicks.gifted", "kicks.gifted", "kick:123456789", "kick:01DELIVERY", "kick.kicks.gifted", "2025-10-20T04:00:08.634Z"},
		{"channel.followed", "channel.followed", "kick:123456789", "kick:01DELIVERY", "kick.channel.followed", "2026-10-12T00:00:00Z"},
		{"moderation.banned", "moderation.banned", "kick:123456789", "kick:01DELIVERY", "kick.moderation.banned", "2025-01-14T16:08:05Z"},
		{"moderation.banned", "moderation.banned.permanent", "kick:123456789", "kick:01DELIVERY", "kick.moderation.banned", "2025-01-14T16:08:05Z"},
		{"channel.reward.redemption.updated", "channel.reward.redemption.updated", "kick:333", "kick:01DELIVERY", "kick.channel.reward.redemption.updated", "2025-12-02T22:54:19.323Z"},
		{"livestream.status.updated", "livestream.status.updated.online", "kick:123456789", "kick:01DELIVERY", "stream.online", "2025-01-01T11:00:00+11:00"},
		{"livestream.status.updated", "livestream.status.updated.offline", "kick:123456789", "kick:01DELIVERY", "stream.offline", "2025-01-01T15:00:00+11:00"},
		{"chat.message.sent", "chat.message.sent", "kick:123456789", "kick:unique_message_id_123", "kick.chat.message.sent", "2025-01-14T16:08:06Z"},
		{"livestream.metadata.updated", "livestream.metadata.updated", "kick:123456789", "", "", ""},
	} {
		t.Run(tc.fixture, func(t *testing.T) {
			event := kickFixture(t, tc.fixture)
			docs, err := KickToDocuments(KickDelivery{MessageID: "01DELIVERY", Timestamp: now.Format(time.RFC3339), Type: tc.eventType, Version: "1", Event: event}, now)
			if err != nil {
				t.Fatal(err)
			}
			if docs == nil || docs.ChannelID != tc.channelID {
				t.Fatalf("documents: %+v", docs)
			}
			broadcaster := kickObject(kickObject(event)["broadcaster"])
			channel := map[string]interface{}{"login": broadcaster["channel_slug"], "displayName": broadcaster["username"]}
			switch tc.fixture {
			case "livestream.status.updated.online":
				channel["onlineAt"] = testKickTime(t, tc.at)
				channel["title"] = "Stream Title"
			case "livestream.status.updated.offline":
				channel["onlineAt"] = nil
				channel["title"] = "Stream Title"
			case "livestream.metadata.updated":
				channel["title"] = "Stream Title"
				channel["language"] = "en"
				channel["categoryId"] = float64(123)
				channel["categoryName"] = "Category name"
			}
			if !reflect.DeepEqual(docs.Channel, channel) {
				t.Fatalf("channel = %#v, want %#v", docs.Channel, channel)
			}
			messages := []KickMessageDoc{}
			if tc.id != "" {
				messages = append(messages, KickMessageDoc{ID: tc.id, Data: map[string]interface{}{
					"channelId": tc.channelID, "type": tc.messageType, "timestamp": testKickTime(t, tc.at), "expiresAt": now.Add(wantMessageTTL(tc.messageType)), "event": event,
				}})
			}
			if !reflect.DeepEqual(docs.Messages, messages) {
				t.Fatalf("messages = %#v, want %#v", docs.Messages, messages)
			}
			if tc.fixture == "channel.subscription.gifts.anonymous" {
				gifter := kickObject(kickObject(docs.Messages[0].Data["event"])["gifter"])
				if gifter["is_anonymous"] != true || gifter["username"] != nil {
					t.Fatalf("gifter: %#v", gifter)
				}
			}
			if tc.fixture == "moderation.banned.permanent" && kickObject(kickObject(docs.Messages[0].Data["event"])["metadata"])["expires_at"] != nil {
				t.Fatal("permanent ban expiry changed")
			}
		})
	}
}

func TestKickToDocuments(t *testing.T) {
	now := testKickTime(t, "2026-10-12T01:00:00Z")
	for _, tc := range []struct {
		name, eventType, body, id, messageType, at string
		channel                                    map[string]interface{}
		ignored                                    bool
	}{
		{name: "chat", eventType: "chat.message.sent", body: `{"message_id":"uuid-1","content":"hello","created_at":"2026-10-12T00:59:59Z"}`, id: "kick:uuid-1", messageType: "kick.chat.message.sent", at: "2026-10-12T00:59:59Z"},
		{name: "online", eventType: "livestream.status.updated", body: `{"is_live":true,"title":"irl","started_at":"2026-10-12T00:00:00Z"}`, id: "kick:delivery-1", messageType: "stream.online", at: "2026-10-12T00:00:00Z", channel: map[string]interface{}{"onlineAt": testKickTime(t, "2026-10-12T00:00:00Z"), "title": "irl"}},
		{name: "offline", eventType: "livestream.status.updated", body: `{"is_live":false,"ended_at":"2026-10-12T02:00:00Z"}`, id: "kick:delivery-1", messageType: "stream.offline", at: "2026-10-12T02:00:00Z", channel: map[string]interface{}{"onlineAt": nil}},
		{name: "metadata", eventType: "livestream.metadata.updated", body: `{"metadata":{"title":"new title","language":"en","category":{"id":15,"name":"IRL"}}}`, channel: map[string]interface{}{"title": "new title", "language": "en", "categoryId": float64(15), "categoryName": "IRL"}},
		{name: "missing metadata", eventType: "livestream.metadata.updated", body: `{}`, channel: map[string]interface{}{"title": nil, "language": nil, "categoryId": nil, "categoryName": nil}},
		{name: "follow", eventType: "channel.followed", body: `{"follower":{"user_id":9},"created_at":"2000-01-01T00:00:00Z"}`, id: "kick:delivery-1", messageType: "kick.channel.followed", at: "2026-10-12T01:00:00Z"},
		{name: "unknown", eventType: "future.event", body: `{"created_at":"2026-10-12T00:59:59Z"}`, id: "kick:delivery-1", messageType: "kick.future.event", at: "2026-10-12T00:59:59Z"},
		{name: "timestamp fallback", eventType: "channel.subscription.new", body: `{"created_at":null}`, id: "kick:delivery-1", messageType: "kick.channel.subscription.new", at: "2026-10-12T01:00:00Z"},
		{name: "no broadcaster", body: `{}`, ignored: true},
		{name: "null broadcaster id", body: `{"broadcaster":{"user_id":null}}`, ignored: true},
		{name: "no slug", eventType: "channel.followed", body: `{"broadcaster":{"user_id":"123"}}`, id: "kick:delivery-1", messageType: "kick.channel.followed", at: "2026-10-12T01:00:00Z", channel: map[string]interface{}{}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var event map[string]interface{}
			if err := json.Unmarshal([]byte(tc.body), &event); err != nil {
				t.Fatal(err)
			}
			if !tc.ignored && tc.name != "no slug" {
				event["broadcaster"] = map[string]interface{}{"user_id": float64(123), "username": "Muxfd", "channel_slug": "muxfd"}
			}
			docs, err := KickToDocuments(KickDelivery{MessageID: "delivery-1", Timestamp: now.Format(time.RFC3339), Type: tc.eventType, Version: "1", Event: event}, now)
			if err != nil {
				t.Fatal(err)
			}
			if tc.ignored {
				if docs != nil {
					t.Fatal("expected ignored delivery")
				}
				return
			}
			channel := map[string]interface{}{}
			if tc.name != "no slug" {
				channel["login"] = "muxfd"
				channel["displayName"] = "Muxfd"
			}
			for k, v := range tc.channel {
				channel[k] = v
			}
			if docs.ChannelID != "kick:123" || !reflect.DeepEqual(channel, docs.Channel) {
				t.Fatalf("documents: %#v", docs)
			}
			want := []KickMessageDoc{}
			if tc.id != "" {
				want = append(want, KickMessageDoc{ID: tc.id, Data: map[string]interface{}{"channelId": "kick:123", "type": tc.messageType, "timestamp": testKickTime(t, tc.at), "expiresAt": now.Add(wantMessageTTL(tc.messageType)), "event": event}})
			}
			if !reflect.DeepEqual(docs.Messages, want) {
				t.Fatalf("messages: %#v, want %#v", docs.Messages, want)
			}
		})
	}
}

func kickTestKey(t *testing.T) (*rsa.PrivateKey, string) {
	t.Helper()
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	der, err := x509.MarshalPKIXPublicKey(&key.PublicKey)
	if err != nil {
		t.Fatal(err)
	}
	return key, string(pem.EncodeToMemory(&pem.Block{Type: "PUBLIC KEY", Bytes: der}))
}

func kickTestSign(t *testing.T, key *rsa.PrivateKey, id, ts, body string) string {
	t.Helper()
	hash := sha256.Sum256([]byte(id + "." + ts + "." + body))
	signature, err := rsa.SignPKCS1v15(rand.Reader, key, crypto.SHA256, hash[:])
	if err != nil {
		t.Fatal(err)
	}
	return base64.StdEncoding.EncodeToString(signature)
}

func TestVerifyKickSignature(t *testing.T) {
	private, key := kickTestKey(t)
	id, ts, body := "01HZXJ4Q0Y8M6ZJ6V9Q3K4X7AB", "2026-10-12T01:02:03Z", `{"message_id":"m1"}`
	signature := kickTestSign(t, private, id, ts, body)
	for _, tc := range []struct {
		name, key, id, ts, body, signature string
		want                               bool
	}{
		{"valid", key, id, ts, body, signature, true},
		{"body", key, id, ts, body + " ", signature, false},
		{"id", key, "other", ts, body, signature, false},
		{"timestamp", key, id, "2026", body, signature, false},
		{"garbage signature", key, id, ts, body, "not base64!", false},
		{"garbage key", "not a key", id, ts, body, signature, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if got := VerifyKickSignature(tc.key, tc.id, tc.ts, []byte(tc.body), tc.signature); got != tc.want {
				t.Fatalf("verified = %v", got)
			}
		})
	}
}

type kickMemoryStore struct {
	messages            map[string]map[string]interface{}
	channels            map[string]map[string]interface{}
	calls               []string
	createErr, mergeErr error
}

func (s *kickMemoryStore) CreateMessage(_ context.Context, channel, id string, data map[string]interface{}) error {
	path := "channels/" + channel + "/messages/" + id
	s.calls = append(s.calls, path)
	if s.createErr != nil {
		return s.createErr
	}
	if s.messages == nil {
		s.messages = map[string]map[string]interface{}{}
	}
	if _, exists := s.messages[path]; exists {
		return status.Error(codes.AlreadyExists, "redelivery")
	}
	s.messages[path] = data
	return nil
}

func (s *kickMemoryStore) MergeChannel(_ context.Context, channel string, data map[string]interface{}) error {
	s.calls = append(s.calls, "channels/"+channel)
	if s.mergeErr != nil {
		return s.mergeErr
	}
	if s.channels == nil {
		s.channels = map[string]map[string]interface{}{}
	}
	if s.channels[channel] == nil {
		s.channels[channel] = map[string]interface{}{}
	}
	for k, v := range data {
		s.channels[channel][k] = v
	}
	return nil
}

type kickContextStore struct {
	kickMemoryStore
	check func(context.Context)
}

func (s *kickContextStore) CreateMessage(ctx context.Context, channel, id string, data map[string]interface{}) error {
	s.check(ctx)
	if err := ctx.Err(); err != nil {
		return err
	}
	return s.kickMemoryStore.CreateMessage(ctx, channel, id, data)
}

func (s *kickContextStore) MergeChannel(ctx context.Context, channel string, data map[string]interface{}) error {
	s.check(ctx)
	if err := ctx.Err(); err != nil {
		return err
	}
	return s.kickMemoryStore.MergeChannel(ctx, channel, data)
}

func TestKickVerifiedDeliverySurvivesRequestCancellation(t *testing.T) {
	private, key := kickTestKey(t)
	for _, cancelBefore := range []bool{false, true} {
		t.Run(fmt.Sprintf("cancel before persistence=%t", cancelBefore), func(t *testing.T) {
			type contextKey struct{}
			parent, cancel := context.WithCancel(context.WithValue(context.Background(), contextKey{}, "request value"))
			defer cancel()
			if cancelBefore {
				cancel()
			}
			var persistence context.Context
			store := &kickContextStore{check: func(ctx context.Context) {
				cancel() // Also exercise cancellation between the message and channel writes.
				persistence = ctx
				if ctx.Err() != nil || ctx.Value(contextKey{}) != "request value" {
					t.Fatalf("persistence inherited cancellation or lost request values: %v", ctx.Err())
				}
				deadline, ok := ctx.Deadline()
				if !ok || time.Until(deadline) <= 0 || time.Until(deadline) > 10*time.Second {
					t.Fatalf("unbounded persistence context: %v, %v", deadline, ok)
				}
			}}
			handler := NewKickHandler(store)
			handler.publicKey = key
			now := time.Now().UTC().Format(time.RFC3339)
			body := `{"broadcaster":{"user_id":123,"channel_slug":"muxfd"},"message_id":"m1"}`
			req := httptest.NewRequest(http.MethodPost, "/kick/webhook", strings.NewReader(body)).WithContext(parent)
			req.Header.Set("Kick-Event-Message-Id", "delivery-1")
			req.Header.Set("Kick-Event-Message-Timestamp", now)
			req.Header.Set("Kick-Event-Type", "chat.message.sent")
			req.Header.Set("Kick-Event-Signature", kickTestSign(t, private, "delivery-1", now, body))
			response := httptest.NewRecorder()
			handler.ServeHTTP(response, req)
			if response.Code != http.StatusOK || len(store.messages) != 1 || len(store.channels) != 1 {
				t.Fatalf("delivery was not persisted: status=%d writes=%v", response.Code, store.calls)
			}
			if persistence == nil || persistence.Err() != context.Canceled {
				t.Fatal("persistence context not released after handler returned")
			}
		})
	}
}

func TestKickHandler(t *testing.T) {
	private, key := kickTestKey(t)
	_, oldKey := kickTestKey(t)
	now := testKickTime(t, "2026-10-12T01:00:00Z")
	body := `{"broadcaster":{"user_id":123,"channel_slug":"muxfd","username":"Muxfd"},"message_id":"m1","created_at":"2026-10-12T00:59:59Z"}`
	for _, tc := range []struct {
		name, method, body, missing, eventType string
		status                                 int
		createErr, mergeErr                    error
		rotated, badKey                        bool
	}{
		{name: "success", status: 200},
		{name: "get", method: "GET", status: 405},
		{name: "missing id", missing: "Kick-Event-Message-Id", status: 400},
		{name: "missing timestamp", missing: "Kick-Event-Message-Timestamp", status: 400},
		{name: "missing signature", missing: "Kick-Event-Signature", status: 400},
		{name: "mismatch", missing: "tamper", status: 403},
		{name: "rotation", rotated: true, status: 200},
		{name: "key fetch failure", badKey: true, status: 500},
		{name: "no broadcaster", body: `{}`, status: 200},
		{name: "null event", body: `null`, status: 200},
		{name: "invalid JSON", body: `{`, status: 400},
		{name: "create failure", createErr: errors.New("unavailable"), status: 500},
		{name: "already exists", createErr: status.Error(codes.AlreadyExists, "exists"), status: 200},
		{name: "merge failure", mergeErr: errors.New("unavailable"), status: 500},
		{name: "metadata", eventType: "livestream.metadata.updated", status: 200},
		{name: "empty channel", body: `{"broadcaster":{"user_id":123},"message_id":"m1"}`, status: 200},
	} {
		t.Run(tc.name, func(t *testing.T) {
			fetched := 0
			endpoint := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				fetched++
				if r.Method != "GET" || r.URL.Path != "/public/v1/public-key" {
					t.Errorf("key request: %s %s", r.Method, r.URL.Path)
				}
				if tc.badKey {
					w.WriteHeader(503)
					return
				}
				json.NewEncoder(w).Encode(map[string]interface{}{"data": map[string]interface{}{"public_key": key}})
			})
			store := &kickMemoryStore{createErr: tc.createErr, mergeErr: tc.mergeErr, channels: map[string]map[string]interface{}{"kick:123": {"existing": "preserved"}}}
			handler := NewKickHandler(store)
			handler.client = &http.Client{Transport: kickTestTransport{handler: endpoint}}
			clock := now
			handler.now = func() time.Time { return clock }
			if tc.rotated {
				handler.publicKey = oldKey
			}
			payload := body
			if tc.body != "" {
				payload = tc.body
			}
			eventType := tc.eventType
			if eventType == "" {
				eventType = "chat.message.sent"
			}
			send := func() *httptest.ResponseRecorder {
				method := tc.method
				if method == "" {
					method = "POST"
				}
				req := httptest.NewRequest(method, "/kick/", strings.NewReader(payload))
				req.Header.Set("Kick-Event-Message-Id", "delivery-1")
				req.Header.Set("Kick-Event-Message-Timestamp", now.Format(time.RFC3339))
				req.Header.Set("Kick-Event-Type", eventType)
				req.Header.Set("Kick-Event-Version", "1")
				req.Header.Set("Kick-Event-Signature", kickTestSign(t, private, "delivery-1", now.Format(time.RFC3339), payload))
				if tc.missing == "tamper" {
					req.Header.Set("Kick-Event-Message-Id", "other")
				} else if tc.missing != "" {
					req.Header.Del(tc.missing)
				}
				recorder := httptest.NewRecorder()
				server := NewServer(Secrets{})
				server.RegisterProvider("/kick/", handler)
				server.Mux.ServeHTTP(recorder, req)
				return recorder
			}
			if got := send().Code; got != tc.status {
				t.Fatalf("status = %d, want %d", got, tc.status)
			}
			expectedFetches := 1
			switch tc.name {
			case "get", "missing id", "missing timestamp", "missing signature":
				expectedFetches = 0
			case "mismatch":
				// the key was just fetched, so the mismatch doesn't refetch it.
				expectedFetches = 1
			}
			if fetched != expectedFetches {
				t.Fatalf("key fetches = %d, want %d", fetched, expectedFetches)
			}
			switch tc.name {
			case "success", "rotation":
				if !reflect.DeepEqual(store.calls, []string{"channels/kick:123/messages/kick:m1", "channels/kick:123"}) {
					t.Fatalf("writes: %v", store.calls)
				}
				original := store.messages["channels/kick:123/messages/kick:m1"]
				clock = clock.Add(time.Hour)
				if got := send().Code; got != 200 {
					t.Fatalf("redelivery status = %d", got)
				}
				if len(store.messages) != 1 || !reflect.DeepEqual(original, store.messages["channels/kick:123/messages/kick:m1"]) {
					t.Fatal("redelivery changed the stored message")
				}
				if fetched != 1 {
					t.Fatal("public key was not cached")
				}
				if store.channels["kick:123"]["existing"] != "preserved" || store.channels["kick:123"]["login"] != "muxfd" {
					t.Fatal("channel merge failed")
				}
				// Decode independently and compare every stored field to the pure mapping.
				var event interface{}
				json.Unmarshal([]byte(payload), &event)
				docs, err := KickToDocuments(KickDelivery{MessageID: "delivery-1", Timestamp: "2026-10-12T01:00:00Z", Type: eventType, Version: "1", Event: event}, testKickTime(t, "2026-10-12T01:00:00Z"))
				if err != nil || !reflect.DeepEqual(original, docs.Messages[0].Data) {
					t.Fatalf("stored data: %#v", original)
				}
			case "metadata":
				if !reflect.DeepEqual(store.calls, []string{"channels/kick:123"}) {
					t.Fatalf("writes: %v", store.calls)
				}
			case "empty channel":
				if !reflect.DeepEqual(store.calls, []string{"channels/kick:123/messages/kick:m1"}) {
					t.Fatalf("writes: %v", store.calls)
				}
			case "create failure":
				if len(store.calls) != 1 {
					t.Fatal("merged after failed create")
				}
			case "already exists", "merge failure":
				if len(store.calls) != 2 {
					t.Fatalf("writes: %v", store.calls)
				}
			default:
				if len(store.calls) != 0 {
					t.Fatalf("unexpected writes: %v", store.calls)
				}
			}
		})
	}
}

func TestKickPublicKeyFetchRetry(t *testing.T) {
	_, key := kickTestKey(t)
	for _, badResponse := range []string{"http failure", "invalid JSON"} {
		t.Run(badResponse, func(t *testing.T) {
			calls := 0
			endpoint := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				calls++
				if calls == 1 {
					if badResponse == "http failure" {
						w.WriteHeader(503)
					} else {
						w.Write([]byte("{"))
					}
					return
				}
				json.NewEncoder(w).Encode(map[string]interface{}{"data": map[string]interface{}{"public_key": key}})
			})
			h := NewKickHandler(&kickMemoryStore{})
			h.client = &http.Client{Transport: kickTestTransport{handler: endpoint}}
			if _, err := h.getPublicKey(context.Background(), false); err == nil {
				t.Fatal("expected fetch error")
			}
			for i := 0; i < 2; i++ {
				if got, err := h.getPublicKey(context.Background(), false); err != nil || got != key {
					t.Fatalf("key = %q, err = %v", got, err)
				}
			}
			if calls != 2 {
				t.Fatalf("fetches = %d", calls)
			}
		})
	}
}

// Exercise the real HTTP fetch path without a listening socket or network.
type kickTestTransport struct{ handler http.Handler }

func (transport kickTestTransport) RoundTrip(request *http.Request) (*http.Response, error) {
	recorder := httptest.NewRecorder()
	transport.handler.ServeHTTP(recorder, request)
	return recorder.Result(), nil
}

func TestKickFirestoreData(t *testing.T) {
	at := testKickTime(t, "2026-10-12T00:00:00Z")
	input := map[string]interface{}{
		"timestamp":  at,
		"categoryId": float64(123),
		"event": map[string]interface{}{
			"user_id": float64(123456789),
			"nested":  []interface{}{float64(5), float64(1.5), nil, "2025-01-01T00:00:00Z", float64(9007199254740992)},
		},
	}
	want := map[string]interface{}{
		"timestamp":  at,
		"categoryId": int64(123),
		"event": map[string]interface{}{
			"user_id": int64(123456789),
			"nested":  []interface{}{int64(5), float64(1.5), nil, "2025-01-01T00:00:00Z", float64(9007199254740992)},
		},
	}
	if got := kickFirestoreData(input); !reflect.DeepEqual(got, want) {
		t.Fatalf("data = %#v, want %#v", got, want)
	}
	if _, ok := input["categoryId"].(float64); !ok {
		t.Fatal("conversion mutated the original event")
	}
}

func TestKickKeyRefreshIsThrottled(t *testing.T) {
	fetched := 0
	endpoint := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fetched++
		json.NewEncoder(w).Encode(map[string]interface{}{"data": map[string]interface{}{"public_key": "key"}})
	})
	handler := NewKickHandler(&kickMemoryStore{})
	handler.client = &http.Client{Transport: kickTestTransport{handler: endpoint}}
	clock := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	handler.now = func() time.Time { return clock }

	for i := 0; i < 5; i++ {
		if _, err := handler.getPublicKey(context.Background(), true); err != nil {
			t.Fatal(err)
		}
	}
	if fetched != 1 {
		t.Fatalf("fetches within a minute = %d, want 1", fetched)
	}
	clock = clock.Add(2 * kickKeyRefreshInterval)
	if _, err := handler.getPublicKey(context.Background(), true); err != nil {
		t.Fatal(err)
	}
	if fetched != 2 {
		t.Fatalf("fetches after the interval = %d, want 2", fetched)
	}
}

func TestKickKind(t *testing.T) {
	for in, want := range map[string]string{"kick.chat.message.sent": "message", "kick.channel.followed": "channel.followed", "stream.online": "stream.online"} {
		if got := kickKind(in); got != want {
			t.Errorf("kickKind(%q) = %q, want %q", in, got, want)
		}
	}
}
