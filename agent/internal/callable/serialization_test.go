package callable

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestFirebaseIntegerDecoding(t *testing.T) {
	for _, tc := range []struct{ name, data, want string }{
		{"signed duration", `{"length":{"@type":"type.googleapis.com/google.protobuf.Int64Value","value":"300"}}`, `{"length":300}`},
		{"nested signed minimum", `[{"n":{"@type":"type.googleapis.com/google.protobuf.Int64Value","value":"-9223372036854775808"}}]`, `[{"n":-9223372036854775808}]`},
		{"unsigned maximum", `{"@type":"type.googleapis.com/google.protobuf.UInt64Value","value":"18446744073709551615"}`, `18446744073709551615`},
		{"plain values stay exact", `{"n":9007199254740993,"bool":true,"null":null,"text":"300","float":1.5}`, `{"bool":true,"float":1.5,"n":9007199254740993,"null":null,"text":"300"}`},
		{"unknown wrapper stays a map", `{"@type":"future.Type","value":"300"}`, `{"@type":"future.Type","value":"300"}`},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var received json.RawMessage
			s := NewServer(nil)
			s.Register("test", false, func(_ context.Context, data json.RawMessage) (any, error) {
				received = data
				return nil, nil
			})
			r := httptest.NewRequest("POST", "/test", strings.NewReader(`{"data":`+tc.data+`}`))
			r.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()
			s.ServeHTTP(w, r)
			if w.Code != http.StatusOK || string(received) != tc.want {
				t.Fatalf("status=%d decoded=%s response=%s", w.Code, received, w.Body.String())
			}
		})
	}
}

func TestMalformedIntegerWrappersDoNotReachHandler(t *testing.T) {
	for _, value := range []string{`null`, `300`, `"abc"`, `"1.5"`, `"9223372036854775808"`, `""`} {
		t.Run(value, func(t *testing.T) {
			s := NewServer(nil)
			s.Register("test", false, func(context.Context, json.RawMessage) (any, error) {
				t.Fatal("invalid wrapper reached handler")
				return nil, nil
			})
			r := httptest.NewRequest("POST", "/test", strings.NewReader(`{"data":{"@type":"type.googleapis.com/google.protobuf.Int64Value","value":`+value+`}}`))
			r.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()
			s.ServeHTTP(w, r)
			if w.Code != http.StatusBadRequest || !strings.Contains(w.Body.String(), "INVALID_ARGUMENT") {
				t.Fatalf("%d %s", w.Code, w.Body.String())
			}
		})
	}
}
