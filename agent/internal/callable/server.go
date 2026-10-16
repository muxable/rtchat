// Package callable implements the Firebase callable HTTP protocol.
package callable

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net/http"
	"strings"
	"time"
)

type Handler func(context.Context, json.RawMessage) (any, error)
type VerifyFunc func(context.Context, string) (string, error)
type Error struct {
	Code    string
	Message string
	Details any
}

func (e *Error) Error() string { return e.Message }

type uidKey struct{}

func UID(ctx context.Context) string { uid, _ := ctx.Value(uidKey{}).(string); return uid }

type Server struct {
	mux    *http.ServeMux
	verify VerifyFunc
}

func NewServer(verify VerifyFunc) *Server                          { return &Server{mux: http.NewServeMux(), verify: verify} }
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) { s.mux.ServeHTTP(w, r) }

// Register installs a callable at /name. Public handlers still reject invalid supplied credentials.
func (s *Server) Register(name string, requireAuth bool, handler Handler) {
	if name == "" || strings.Contains(name, "/") {
		panic("invalid callable name")
	}
	s.mux.HandleFunc("/"+name, func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, Firebase-Instance-ID-Token, X-Firebase-AppCheck")
		w.Header().Set("Vary", "Origin")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		if r.Method != http.MethodPost {
			writeError(w, &Error{Code: "invalid-argument", Message: "POST required"})
			return
		}
		media, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
		if err != nil || media != "application/json" {
			writeError(w, &Error{Code: "invalid-argument", Message: "JSON required"})
			return
		}
		r.Body = http.MaxBytesReader(w, r.Body, 1024*1024)
		dec := json.NewDecoder(r.Body)
		var envelope map[string]json.RawMessage
		if err := dec.Decode(&envelope); err != nil || len(envelope) != 1 || envelope["data"] == nil {
			writeError(w, &Error{Code: "invalid-argument", Message: "expected data envelope"})
			return
		}
		var extra any
		if dec.Decode(&extra) != io.EOF {
			writeError(w, &Error{Code: "invalid-argument", Message: "invalid JSON"})
			return
		}
		ctx, cancel := context.WithTimeout(r.Context(), 60*time.Second)
		defer cancel()
		if authorization := r.Header.Get("Authorization"); authorization != "" {
			parts := strings.Split(authorization, " ")
			if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || parts[1] == "" || s.verify == nil {
				writeError(w, &Error{Code: "unauthenticated", Message: "invalid authentication"})
				return
			}
			uid, err := s.verify(ctx, parts[1])
			if err != nil || uid == "" {
				writeError(w, &Error{Code: "unauthenticated", Message: "invalid authentication"})
				return
			}
			ctx = context.WithValue(ctx, uidKey{}, uid)
		}
		if requireAuth && UID(ctx) == "" {
			writeError(w, &Error{Code: "unauthenticated", Message: "authentication required"})
			return
		}
		result, err := handler(ctx, envelope["data"])
		if err != nil {
			writeError(w, err)
			return
		}
		payload, err := json.Marshal(map[string]any{"result": result})
		if err != nil {
			writeError(w, err)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Write(payload)
	})
}

var statusCodes = map[string]int{"cancelled": 499, "unknown": 500, "invalid-argument": 400, "deadline-exceeded": 504, "not-found": 404, "already-exists": 409, "permission-denied": 403, "resource-exhausted": 429, "failed-precondition": 400, "aborted": 409, "out-of-range": 400, "unimplemented": 501, "internal": 500, "unavailable": 503, "data-loss": 500, "unauthenticated": 401}

func writeError(w http.ResponseWriter, err error) {
	e := &Error{Code: "internal", Message: "INTERNAL"}
	var explicit *Error
	if errors.As(err, &explicit) {
		if _, ok := statusCodes[explicit.Code]; ok {
			e = explicit
		}
	}
	body := map[string]any{"status": strings.ToUpper(strings.ReplaceAll(e.Code, "-", "_")), "message": e.Message}
	if e.Details != nil {
		body["details"] = e.Details
	}
	payload, marshalErr := json.Marshal(map[string]any{"error": body})
	if marshalErr != nil {
		writeError(w, marshalErr)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCodes[e.Code])
	w.Write(payload)
}
