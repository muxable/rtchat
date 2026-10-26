package callable

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/muxable/rtchat/agent/internal/observability"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"
)

func TestTransport(t *testing.T) {
	for _, tc := range []struct {
		name, method, body, token string
		protected                 bool
		code                      int
		contains                  string
	}{
		{"null", "POST", `{"data":null}`, "", false, 200, `"result":null`},
		{"public invalid token", "POST", `{"data":{}}`, "bad", false, 401, "UNAUTHENTICATED"},
		{"protected missing token", "POST", `{"data":{}}`, "", true, 401, "UNAUTHENTICATED"},
		{"protected valid token", "POST", `{"data":{}}`, "valid", true, 200, `"result":"uid"`},
		{"unexpected member", "POST", `{"data":{},"uid":"admin"}`, "", false, 400, "INVALID_ARGUMENT"},
		{"duplicate member", "POST", `{"data":{},"data":null}`, "", false, 200, `"result":null`},
		{"trailing object", "POST", `{"data":{}}{}`, "", false, 400, "INVALID_ARGUMENT"},
		{"missing data", "POST", `{}`, "", false, 400, "INVALID_ARGUMENT"},
		{"null envelope", "POST", `null`, "", false, 400, "INVALID_ARGUMENT"},
		{"array envelope", "POST", `[]`, "", false, 400, "INVALID_ARGUMENT"},
		{"malformed", "POST", `{"data":`, "", false, 400, "INVALID_ARGUMENT"},
		{"method", "GET", `{"data":{}}`, "", false, 400, "INVALID_ARGUMENT"},
		{"preflight", "OPTIONS", "", "", true, 204, ""},
		{"too large", "POST", `{"data":"` + strings.Repeat("x", 1024*1024) + `"}`, "", false, 400, "INVALID_ARGUMENT"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			s := NewServer(func(ctx context.Context, token string) (string, error) {
				if token == "valid" {
					return "uid", nil
				}
				return "", errors.New("secret detail")
			})
			s.Register("test", tc.protected, func(ctx context.Context, data json.RawMessage) (any, error) {
				if UID(ctx) != "" {
					return UID(ctx), nil
				}
				return nil, nil
			})
			req := httptest.NewRequest(tc.method, "/test", strings.NewReader(tc.body))
			req.Header.Set("Content-Type", "application/json; charset=utf-8")
			if tc.token != "" {
				req.Header.Set("Authorization", "Bearer "+tc.token)
			}
			response := httptest.NewRecorder()
			s.ServeHTTP(response, req)
			if response.Code != tc.code || !strings.Contains(response.Body.String(), tc.contains) {
				t.Fatalf("%d %s", response.Code, response.Body.String())
			}
			if response.Header().Get("Access-Control-Allow-Origin") != "*" {
				t.Fatal("missing CORS")
			}
			if strings.Contains(response.Body.String(), "secret detail") {
				t.Fatal("leaked authentication error")
			}
		})
	}
}
func TestErrorAndMount(t *testing.T) {
	s := NewServer(nil)
	s.Register("explicit", false, func(context.Context, json.RawMessage) (any, error) {
		return nil, &Error{Code: "permission-denied", Message: "denied", Details: map[string]string{"reason": "test"}}
	})
	s.Register("internal", false, func(context.Context, json.RawMessage) (any, error) { return nil, errors.New("credentials=secret") })
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ready")) })
	s.Mount(mux)
	for _, name := range []string{"explicit", "internal"} {
		req := httptest.NewRequest("POST", "/"+name, strings.NewReader(`{"data":{}}`))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, req)
		if name == "explicit" && (w.Code != 403 || !strings.Contains(w.Body.String(), `"details"`)) {
			t.Fatal(w.Body.String())
		}
		if name == "internal" && (w.Code != 500 || strings.Contains(w.Body.String(), "secret")) {
			t.Fatal(w.Body.String())
		}
	}
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, httptest.NewRequest("GET", "/", nil))
	if w.Body.String() != "ready" {
		t.Fatal("readiness taken over")
	}
}
func TestPanicReturnsCanonicalInternal(t *testing.T) {
	s := NewServer(nil)
	s.Register("panic", false, func(context.Context, json.RawMessage) (any, error) { panic("secret") })
	req := httptest.NewRequest("POST", "/panic", strings.NewReader(`{"data":null}`))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	s.ServeHTTP(w, req)
	if w.Code != 500 || strings.Contains(w.Body.String(), "secret") {
		t.Fatalf("%d %s", w.Code, w.Body.String())
	}
}

func TestMountedRoutesStayIsolated(t *testing.T) {
	s := NewServer(nil)
	s.Register("first", false, func(context.Context, json.RawMessage) (any, error) { return "first", nil })
	s.Register("second", false, func(context.Context, json.RawMessage) (any, error) { return "second", nil })
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ready")) })
	s.Mount(mux)
	for path, expected := range map[string]string{"/first": `{"result":"first"}`, "/second": `{"result":"second"}`, "/unknown": "ready", "/first/child": "ready"} {
		w := httptest.NewRecorder()
		r := httptest.NewRequest("POST", path, strings.NewReader(`{"data":null}`))
		r.Header.Set("Content-Type", "application/json")
		mux.ServeHTTP(w, r)
		if w.Code != 200 || w.Body.String() != expected {
			t.Errorf("%s: %d %s", path, w.Code, w.Body.String())
		}
	}
}

func TestRequestLog(t *testing.T) {
	core, logs := observer.New(zap.InfoLevel)
	defer zap.ReplaceGlobals(zap.New(core))()
	s := NewServer(func(context.Context, string) (string, error) { return "uid", nil })
	s.Register("ok", true, func(context.Context, json.RawMessage) (any, error) { return nil, nil })
	s.Register("fail", false, func(context.Context, json.RawMessage) (any, error) { return nil, errors.New("boom") })
	for _, tc := range []struct{ path, token, body string }{
		{"/ok", "valid", `{"data":{"provider":"kick"}}`},
		{"/fail", "", `{"data":"x"}`},
	} {
		req := httptest.NewRequest("POST", tc.path, strings.NewReader(tc.body))
		req.Header.Set("Content-Type", "application/json")
		if tc.token != "" {
			req.Header.Set("Authorization", "Bearer "+tc.token)
			req.Header.Set(ProxyHeader, "getBadges")
		}
		s.ServeHTTP(httptest.NewRecorder(), req)
	}
	entries := logs.FilterMessage("http request").AllUntimed()
	if len(entries) != 2 {
		t.Fatalf("got %d request logs", len(entries))
	}
	ok, fail := entries[0].ContextMap(), entries[1].ContextMap()
	if ok["callable"] != "ok" || ok["status"] != int64(200) || ok["code"] != "ok" || ok["provider"] != "kick" || ok["authenticated"] != true || ok["via"] != "getBadges" {
		t.Fatalf("unexpected success log %v", ok)
	}
	if entries[1].Level != zap.ErrorLevel || fail["callable"] != "fail" || fail["status"] != int64(500) || fail["code"] != "internal" || fail["error"] != "boom" || fail["via"] != "" {
		t.Fatalf("unexpected failure log %v", fail)
	}
}

func TestPanicIsReportedWithoutLeakingToClient(t *testing.T) {
	core, logs := observer.New(zap.InfoLevel)
	undo := zap.ReplaceGlobals(zap.New(observability.Wrap(core), zap.AddCaller(), zap.AddStacktrace(zap.WarnLevel)))
	defer undo()
	server := NewServer(nil)
	server.Register("panic", false, func(context.Context, json.RawMessage) (any, error) { panic("private panic detail") })
	request := httptest.NewRequest("POST", "/panic", strings.NewReader(`{"data":null}`))
	request.Header.Set("Content-Type", "application/json")
	response := httptest.NewRecorder()
	server.ServeHTTP(response, request)
	if response.Code != 500 || strings.Contains(response.Body.String(), "private panic detail") {
		t.Fatal(response.Code, response.Body.String())
	}
	entries := logs.FilterLevelExact(zap.ErrorLevel).All()
	if len(entries) != 1 {
		t.Fatal(entries)
	}
	fields := entries[0].ContextMap()
	stack, _ := fields["stack_trace"].(string)
	if fields["@type"] == nil || fields["path"] != "/panic" || !strings.Contains(stack, "private panic detail") || !strings.Contains(stack, "TestPanicIsReportedWithoutLeakingToClient.func") {
		t.Fatal(fields)
	}
}
