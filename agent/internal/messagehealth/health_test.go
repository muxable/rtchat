package messagehealth

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestCurrentBeforeAnyMessages(t *testing.T) {
	lastMessageUnixNano.Store(0)
	messageCount.Store(0)

	got := Current(time.Minute)
	if got.Status != "waiting" {
		t.Fatalf("status = %q, want waiting", got.Status)
	}
	if got.LastMessageAt != nil {
		t.Fatal("expected no last message timestamp")
	}
}

func TestMarkMessageReceived(t *testing.T) {
	lastMessageUnixNano.Store(0)
	messageCount.Store(0)

	MarkMessageReceived()

	got := Current(time.Minute)
	if got.Status != "healthy" {
		t.Fatalf("status = %q, want healthy", got.Status)
	}
	if got.MessageCount != 1 {
		t.Fatalf("count = %d, want 1", got.MessageCount)
	}
	if got.LastMessageAt == nil {
		t.Fatal("expected last message timestamp")
	}
}

func TestHandlerReportsStaleMessages(t *testing.T) {
	lastMessageUnixNano.Store(time.Now().
		Add(-time.Hour).UnixNano())
	messageCount.Store(1)

	req := httptest.NewRequest(http.MethodGet, "/health/messages", nil)
	rec := httptest.NewRecorder()

	Handler(time.Minute).ServeHTTP(rec, req)

	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want 503", rec.Code)
	}

	var got Snapshot
	if err := json.Unmarshal(rec.Body.Bytes(), &got); err != nil {
		t.Fatal(err)
	}
	if got.Status != "stale" {
		t.Fatalf("health = %q, want stale", got.Status)
	}
}

func TestHandlerRejectsNonGet(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/health/messages", nil)
	rec := httptest.NewRecorder()

	Handler(time.Minute).ServeHTTP(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want 405", rec.Code)
	}
}
