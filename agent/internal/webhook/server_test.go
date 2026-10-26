package webhook

import (
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"

	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"
)

func TestServerRoutes(t *testing.T) {
	server := NewServer(Secrets{})
	server.Mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusServiceUnavailable)
	})
	for _, test := range []struct {
		path   string
		status int
		body   string
	}{
		{"/", http.StatusServiceUnavailable, ""},
		{"/healthz", http.StatusOK, "ok"},
		{"/kick/", http.StatusNotImplemented, "Not Implemented\n"},
		{"/kick/events", http.StatusNotImplemented, "Not Implemented\n"},
		{"/twitch/", http.StatusNotImplemented, "Not Implemented\n"},
		{"/twitch/events", http.StatusNotImplemented, "Not Implemented\n"},
		{"/alchemy/", http.StatusNotImplemented, "Not Implemented\n"},
		{"/alchemy/events", http.StatusNotImplemented, "Not Implemented\n"},
	} {
		t.Run(test.path, func(t *testing.T) {
			response := httptest.NewRecorder()
			server.Mux.ServeHTTP(response, httptest.NewRequest(http.MethodGet, test.path, nil))
			if response.Code != test.status || response.Body.String() != test.body {
				t.Fatalf("got %d %q, want %d %q", response.Code, response.Body.String(), test.status, test.body)
			}
		})
	}
}

func TestLoggingMiddleware(t *testing.T) {
	for _, test := range []struct {
		name    string
		handler http.HandlerFunc
		status  int
	}{
		{"explicit", func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(http.StatusNotImplemented) }, http.StatusNotImplemented},
		{"implicit", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ok")) }, http.StatusOK},
		{"empty", func(w http.ResponseWriter, r *http.Request) {}, http.StatusOK},
		{"first status", func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusAccepted)
			w.WriteHeader(http.StatusInternalServerError)
		}, http.StatusAccepted},
	} {
		t.Run(test.name, func(t *testing.T) {
			core, logs := observer.New(zap.InfoLevel)
			undo := zap.ReplaceGlobals(zap.New(core))
			defer undo()
			response := httptest.NewRecorder()
			LoggingMiddleware(test.handler).ServeHTTP(response, httptest.NewRequest(http.MethodPost, "/events?token=private", nil))
			if response.Code != test.status {
				t.Fatalf("got response status %d, want %d", response.Code, test.status)
			}
			entries := logs.All()
			if len(entries) != 1 {
				t.Fatalf("got %d log entries, want 1", len(entries))
			}
			if test.status >= 500 && entries[0].Level != zap.ErrorLevel {
				t.Fatal("server failure was not logged as an error")
			}
			fields := entries[0].ContextMap()
			if fields["method"] != http.MethodPost || fields["path"] != "/events" || fields["status"] != int64(test.status) {
				t.Fatalf("unexpected log fields: %v", fields)
			}
			if latency, ok := fields["latency_ms"].(float64); !ok || latency < 0 {
				t.Fatalf("invalid latency: %v", fields["latency_ms"])
			}
		})
	}
}

func TestRegisterProviderReplacesPlaceholder(t *testing.T) {
	s := NewServer(Secrets{})
	s.RegisterProvider("/kick/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusAccepted)
	}))
	rec := httptest.NewRecorder()
	s.Mux.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/kick/webhook", nil))
	if rec.Code != http.StatusAccepted {
		t.Fatalf("got %d, want %d", rec.Code, http.StatusAccepted)
	}
}

func TestHealthzFailsWhileDraining(t *testing.T) {
	s := NewServer(Secrets{})
	draining := &atomic.Bool{}
	s.Draining = draining
	probe := func() int {
		w := httptest.NewRecorder()
		s.Mux.ServeHTTP(w, httptest.NewRequest("GET", "/healthz", nil))
		return w.Code
	}
	if code := probe(); code != http.StatusOK {
		t.Fatal("healthy before draining", code)
	}
	draining.Store(true)
	if code := probe(); code != http.StatusServiceUnavailable {
		t.Fatal("health check should fail while draining", code)
	}
}
