package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/muxable/rtchat/agent/internal/webhook"
)

func TestProductionCallableRegistration(t *testing.T) {
	t.Setenv("METADATA_CLIENT_IDS", "")
	t.Setenv("AGENT_PROVIDER_SUBSCRIPTIONS_ENABLED", "")
	server := newHTTPServer(nil, webhook.Secrets{}, nil, "", "", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("readiness")) }))
	for _, name := range []string{"send", "ban", "unban", "timeout", "deleteMessage", "clear", "raid", "cancelRaid", "subscribe", "setRealTimeCashAddress", "search", "getEmotes", "getBadges", "getViewerList", "getStatistics"} {
		t.Run(name, func(t *testing.T) {
			req := httptest.NewRequest("OPTIONS", "/"+name, nil)
			w := httptest.NewRecorder()
			server.Mux.ServeHTTP(w, req)
			if w.Code != 204 || w.Header().Get("Access-Control-Allow-Methods") != "POST, OPTIONS" {
				t.Fatalf("callable missing from production mux: %d %s", w.Code, w.Body.String())
			}
		})
	}
	// Protected routes must reject absent/forged identity before any provider/database I/O.
	for _, name := range []string{"send", "ban", "unban", "timeout", "deleteMessage", "clear", "raid", "cancelRaid", "setRealTimeCashAddress", "getViewerList"} {
		for _, authorization := range []string{"", "Bearer forged-identity"} {
			req := httptest.NewRequest("POST", "/"+name, strings.NewReader(`{"data":{}}`))
			req.Header.Set("Content-Type", "application/json")
			if authorization != "" {
				req.Header.Set("Authorization", authorization)
			}
			w := httptest.NewRecorder()
			server.Mux.ServeHTTP(w, req)
			if w.Code != 401 {
				t.Fatalf("%s missing authentication: %d", name, w.Code)
			}
		}
	}
	for _, name := range []string{"subscribe", "search", "getEmotes", "getBadges", "getStatistics"} {
		req := httptest.NewRequest("POST", "/"+name, strings.NewReader(`{"data":{}}`))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		server.Mux.ServeHTTP(w, req)
		if w.Code != 400 || !strings.Contains(w.Body.String(), "INVALID_ARGUMENT") {
			t.Fatalf("%s public handler validation: %d %s", name, w.Code, w.Body.String())
		}
	}

}
func TestProductionUtilityAndWebhookRegistration(t *testing.T) {
	t.Setenv("METADATA_CLIENT_IDS", "")
	server := newHTTPServer(nil, webhook.Secrets{}, nil, "", "", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("readiness")) }))
	for _, tc := range []struct {
		method, path string
		status       int
	}{{"GET", "/embed", 400}, {"GET", "/embedRedirect", 400}, {"GET", "/metadata", 405}, {"GET", "/api/metadata", 405}, {"GET", "/kick/webhook", 405}, {"GET", "/twitch/eventsub", 405}, {"POST", "/alchemy/webhook", 503}, {"GET", "/healthz", 200}, {"GET", "/", 200}} {
		req := httptest.NewRequest(tc.method, tc.path, nil)
		w := httptest.NewRecorder()
		server.Mux.ServeHTTP(w, req)
		if w.Code != tc.status {
			t.Fatalf("%s: %d %s", tc.path, w.Code, w.Body.String())
		}
		if tc.path != "/" && w.Body.String() == "readiness" {
			t.Fatalf("%s fell through to readiness", tc.path)
		}
	}
}
func TestProductionInvalidMetadataConfigurationKeepsRoutesClosed(t *testing.T) {
	t.Setenv("METADATA_CLIENT_IDS", "invalid-json")
	server := newHTTPServer(nil, webhook.Secrets{}, nil, "", "", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("readiness")) }))
	for _, path := range []string{"/embed", "/embedRedirect", "/metadata", "/api/metadata"} {
		w := httptest.NewRecorder()
		server.Mux.ServeHTTP(w, httptest.NewRequest("GET", path, nil))
		if w.Code != 503 {
			t.Fatalf("%s: %d", path, w.Code)
		}
	}
}
