package callable

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
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
func TestAppCheckFailsClosed(t *testing.T) {
	s := NewServer(nil)
	called := false
	s.RegisterWithOptions("check", Options{RequireAppCheck: true}, func(context.Context, json.RawMessage) (any, error) { called = true; return nil, nil })
	req := httptest.NewRequest("POST", "/check", strings.NewReader(`{"data":{}}`))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Firebase-AppCheck", "client-assertion")
	w := httptest.NewRecorder()
	s.ServeHTTP(w, req)
	if w.Code != 401 || called {
		t.Fatal("unverified App Check accepted")
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
