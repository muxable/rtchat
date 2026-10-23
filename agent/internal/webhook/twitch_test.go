package webhook

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"testing"
	"time"
)

var twitchTestNow = time.Date(2026, 10, 13, 12, 0, 0, 123456789, time.UTC)

func TestMapTwitchIgnoredAndInvalid(t *testing.T) {
	for _, test := range []struct {
		name, eventType, version, status, id, messageID string
		invalid                                         bool
	}{
		{"follow v1", "channel.follow", "1", "enabled", "1337", "id", false},
		{"disabled", "channel.follow", "2", "authorization_revoked", "1337", "id", false},
		{"missing broadcaster", "stream.offline", "1", "enabled", "", "id", true},
		{"path in broadcaster", "stream.offline", "1", "enabled", "a/b", "id", true},
		{"path in message", "stream.offline", "1", "enabled", "1337", "a/b", true},
		{"future event", "channel.future", "1", "enabled", "1337", "id", false},
	} {
		t.Run(test.name, func(t *testing.T) {
			var payload twitchPayload
			payload.Subscription.Type = test.eventType
			payload.Subscription.Version = test.version
			payload.Subscription.Status = test.status
			payload.Event = map[string]interface{}{"broadcaster_user_id": test.id}
			got, err := mapTwitchNotification(payload, test.messageID, twitchTestNow, twitchTestNow)
			if (err != nil) != test.invalid {
				t.Fatalf("error = %v", err)
			}
			if !test.invalid && test.name != "future event" && len(got.Documents) != 0 {
				t.Fatal("ignored event wrote documents")
			}
			if test.name == "future event" && len(got.Documents) != 1 {
				t.Fatal("unknown type should retain generic message")
			}
		})
	}
}

type fakeTwitchStore struct {
	writes      []twitchDocument
	created     map[string]bool
	setError    error
	updateError error
}

func (s *fakeTwitchStore) Create(_ context.Context, path string, data map[string]interface{}) (bool, error) {
	s.writes = append(s.writes, twitchDocument{Path: path, Data: data, Create: true})
	if s.setError != nil || s.created[path] {
		return false, s.setError
	}
	if s.created == nil {
		s.created = map[string]bool{}
	}
	s.created[path] = true
	return true, nil
}

func (s *fakeTwitchStore) Set(_ context.Context, path string, data map[string]interface{}, merge bool) error {
	s.writes = append(s.writes, twitchDocument{Path: path, Data: data, Merge: merge})
	return s.setError
}
func (s *fakeTwitchStore) Update(_ context.Context, path string, data map[string]interface{}) error {
	s.writes = append(s.writes, twitchDocument{Path: path, Data: data, Update: true})
	return s.updateError
}

func signedTwitchRequest(body, messageType, timestamp string) *http.Request {
	req := httptest.NewRequest(http.MethodPost, "/twitch/eventsub", strings.NewReader(body))
	req.Header.Set("Twitch-Eventsub-Message-Id", "message-id")
	req.Header.Set("Twitch-Eventsub-Message-Timestamp", timestamp)
	req.Header.Set("Twitch-Eventsub-Message-Type", messageType)
	mac := hmac.New(sha256.New, []byte("secret"))
	mac.Write([]byte("message-id" + timestamp + body))
	req.Header.Set("Twitch-Eventsub-Message-Signature", "sha256="+hex.EncodeToString(mac.Sum(nil)))
	return req
}

func TestTwitchHTTP(t *testing.T) {
	notification := `{"subscription":{"type":"channel.cheer","version":"1","status":"enabled"},"event":{"broadcaster_user_id":"1337","bits":100}}`
	for _, test := range []struct {
		name, body, messageType, timestamp string
		mutate                             func(*http.Request, *TwitchHandler)
		status                             int
		response                           string
		writes                             int
	}{
		{name: "notification", body: notification, messageType: "notification", status: 200, writes: 1},
		{name: "challenge", body: `{"subscription":{"status":"webhook_callback_verification_pending"},"challenge":"raw <challenge>\n"}`, messageType: "webhook_callback_verification", status: 200, response: "raw <challenge>\n"},
		{name: "revocation", body: `{"subscription":{"type":"channel.follow","status":"authorization_revoked"}}`, messageType: "revocation", status: 200},
		{name: "missing secret", body: notification, messageType: "notification", mutate: func(_ *http.Request, h *TwitchHandler) { h.Secret = "" }, status: 503},
		{name: "wrong signature", body: notification, messageType: "notification", mutate: func(r *http.Request, _ *TwitchHandler) {
			r.Header.Set("Twitch-Eventsub-Message-Signature", "sha256="+strings.Repeat("0", 64))
		}, status: 403},
		{name: "tampered body", body: notification, messageType: "notification", mutate: func(r *http.Request, _ *TwitchHandler) { r.Body = http.NoBody }, status: 403},
		{name: "tampered id", body: notification, messageType: "notification", mutate: func(r *http.Request, _ *TwitchHandler) { r.Header.Set("Twitch-Eventsub-Message-Id", "other") }, status: 403},
		{name: "tampered timestamp", body: notification, messageType: "notification", mutate: func(r *http.Request, _ *TwitchHandler) {
			r.Header.Set("Twitch-Eventsub-Message-Timestamp", twitchTestNow.Add(-time.Second).Format(time.RFC3339Nano))
		}, status: 403},
		{name: "missing signature", body: notification, messageType: "notification", mutate: func(r *http.Request, _ *TwitchHandler) { r.Header.Del("Twitch-Eventsub-Message-Signature") }, status: 403},
		{name: "invalid signature hex", body: notification, messageType: "notification", mutate: func(r *http.Request, _ *TwitchHandler) {
			r.Header.Set("Twitch-Eventsub-Message-Signature", "sha256=zz")
		}, status: 403},
		{name: "old", body: notification, messageType: "notification", timestamp: twitchTestNow.Add(-10*time.Minute - time.Nanosecond).Format(time.RFC3339Nano), status: 403},
		{name: "ten minute boundary", body: notification, messageType: "notification", timestamp: twitchTestNow.Add(-10 * time.Minute).Format(time.RFC3339Nano), status: 200, writes: 1},
		{name: "bad timestamp", body: notification, messageType: "notification", timestamp: "invalid", status: 403},
		{name: "bad json", body: `{`, messageType: "notification", status: 400},
		{name: "missing event", body: `{"subscription":{"type":"channel.cheer","status":"enabled"}}`, messageType: "notification", status: 400},
		{name: "missing challenge", body: `{}`, messageType: "webhook_callback_verification", status: 400},
		{name: "unknown message type", body: `{}`, messageType: "other", status: 400},
		{name: "other route", body: notification, messageType: "notification", mutate: func(r *http.Request, _ *TwitchHandler) { r.URL.Path = "/twitch/other" }, status: 404},
		{name: "get", body: notification, messageType: "notification", mutate: func(r *http.Request, _ *TwitchHandler) { r.Method = http.MethodGet }, status: 405},
		{name: "oversized", body: strings.Repeat("x", 1024*1024+1), messageType: "notification", status: 413},
	} {
		t.Run(test.name, func(t *testing.T) {
			timestamp := test.timestamp
			if timestamp == "" {
				timestamp = twitchTestNow.Format(time.RFC3339Nano)
			}
			store := &fakeTwitchStore{}
			h := &TwitchHandler{Secret: "secret", Store: store, now: func() time.Time { return twitchTestNow }}
			req := signedTwitchRequest(test.body, test.messageType, timestamp)
			if test.mutate != nil {
				test.mutate(req, h)
			}
			recorder := httptest.NewRecorder()
			server := NewServer(Secrets{})
			server.RegisterProvider("/twitch/", h)
			server.Mux.ServeHTTP(recorder, req)
			if recorder.Code != test.status {
				t.Fatalf("status %d, want %d", recorder.Code, test.status)
			}
			if len(store.writes) != test.writes {
				t.Fatalf("writes %d, want %d", len(store.writes), test.writes)
			}
			if test.response != "" {
				if recorder.Body.String() != test.response {
					t.Fatalf("body %q", recorder.Body.String())
				}
				if recorder.Header().Get("Content-Type") != "text/plain; charset=utf-8" {
					t.Fatal("challenge content type")
				}
			}
		})
	}
}

func TestTwitchWritesAndRetries(t *testing.T) {
	for _, test := range []struct {
		name, eventType, wantPath string
		setError, updateError     error
		wantStatus, wantWrites    int
	}{
		{name: "follow counted once", eventType: "channel.follow", wantPath: "channels/twitch:1337/messages/twitch:follow:42", wantStatus: 200, wantWrites: 3},
		{name: "follow update failure ignored", eventType: "channel.follow", wantPath: "channels/twitch:1337/messages/twitch:follow:42", updateError: errors.New("missing channel"), wantStatus: 200, wantWrites: 3},
		{name: "follow failure retried", eventType: "channel.follow", wantPath: "channels/twitch:1337/messages/twitch:follow:42", setError: errors.New("unavailable"), wantStatus: 500, wantWrites: 2},
		{name: "message failure retried", eventType: "stream.offline", setError: errors.New("unavailable"), wantStatus: 500, wantWrites: 2},
		{name: "online", eventType: "stream.online", wantStatus: 200, wantWrites: 4},
	} {
		t.Run(test.name, func(t *testing.T) {
			store := &fakeTwitchStore{setError: test.setError, updateError: test.updateError}
			h := &TwitchHandler{Secret: "secret", Store: store, now: func() time.Time { return twitchTestNow }}
			body := `{"subscription":{"type":"` + test.eventType + `","version":"2","status":"enabled"},"event":{"broadcaster_user_id":"1337","user_id":"42"}}`
			for i := 0; i < 2; i++ {
				recorder := httptest.NewRecorder()
				h.ServeHTTP(recorder, signedTwitchRequest(body, "notification", twitchTestNow.Format(time.RFC3339Nano)))
				if recorder.Code != test.wantStatus {
					t.Fatalf("status %d", recorder.Code)
				}
			}
			if len(store.writes) != test.wantWrites {
				t.Fatalf("writes %d", len(store.writes))
			}
			wantPath := test.wantPath
			if wantPath == "" {
				wantPath = "channels/twitch:1337/messages/twitch:message-id"
			}
			if store.writes[0].Path != wantPath || store.writes[0].Merge || store.writes[0].Update {
				t.Fatalf("message should be set at deterministic path: %#v", store.writes[0])
			}
		})
	}
}

func (s *fakeTwitchStore) mergeBatch(ctx context.Context, documents []twitchDocument) error {
	for _, doc := range documents {
		if err := s.Set(ctx, doc.Path, doc.Data, true); err != nil {
			return err
		}
	}
	return nil
}

func TestTwitchSignatureVector(t *testing.T) {
	// Fixed digest calculated independently of the request-signing test helper.
	signature := "sha256=1425d9efd440f0881433430a8f59eb4f0a72cacb7449559bb167fa92aa72c6b7"
	body := []byte(`{"challenge":"hello"}`)
	if !verifyTwitchSignature("secret", "message-id", "2026-10-13T12:00:00Z", signature, body) {
		t.Fatal("known signature rejected")
	}
	for _, test := range []struct{ secret, id, timestamp, signature string }{
		{"wrong", "message-id", "2026-10-13T12:00:00Z", signature},
		{"secret", "", "2026-10-13T12:00:00Z", signature},
		{"secret", "message-id", "", signature},
		{"secret", "message-id", "2026-10-13T12:00:00Z", strings.TrimPrefix(signature, "sha256=")},
		{"secret", "message-id", "2026-10-13T12:00:00Z", "sha256=00"},
	} {
		if verifyTwitchSignature(test.secret, test.id, test.timestamp, test.signature, body) {
			t.Fatal("invalid signature accepted")
		}
	}
}

func TestDecodeTwitchFirestoreTypes(t *testing.T) {
	payload, err := decodeTwitchPayload([]byte(`{"event":{"bits":100,"fraction":1.5,"unsafe":9007199254740992,"negative":-2,"zero":0,"null":null,"bool":true,"text":"100","nested":{"count":3},"array":[4,null,{"count":5}]}}`))
	if err != nil {
		t.Fatal(err)
	}
	want := map[string]interface{}{
		"bits": int64(100), "fraction": float64(1.5), "unsafe": float64(9007199254740992), "negative": int64(-2), "zero": int64(0),
		"null": nil, "bool": true, "text": "100", "nested": map[string]interface{}{"count": int64(3)},
		"array": []interface{}{int64(4), nil, map[string]interface{}{"count": int64(5)}},
	}
	if !reflect.DeepEqual(payload.Event, want) {
		t.Fatalf("event %#v, want %#v", payload.Event, want)
	}
	if _, err := decodeTwitchPayload([]byte(`{"event":{}} {}`)); err == nil {
		t.Fatal("accepted trailing JSON")
	}
}
