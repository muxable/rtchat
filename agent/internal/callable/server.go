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

	"github.com/muxable/rtchat/agent/internal/cancel"
	"github.com/muxable/rtchat/agent/internal/observability"
	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
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
	routes map[string]http.Handler
	verify VerifyFunc
}

func NewServer(verify VerifyFunc) *Server {
	return &Server{routes: make(map[string]http.Handler), verify: verify}
}

func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if handler, ok := s.routes[r.URL.Path]; ok {
		handler.ServeHTTP(w, r)
		return
	}
	http.NotFound(w, r)
}

// Mount registers handlers directly on the existing mux, leaving readiness intact.
// Call after all registrations and before serving requests.
func (s *Server) Mount(mux *http.ServeMux) {
	for path, handler := range s.routes {
		mux.Handle(path, handler)
	}
}

// Register installs a callable at /name. Public handlers still reject invalid supplied credentials.
func (s *Server) Register(name string, requireAuth bool, handler Handler) {
	if name == "" || strings.Contains(name, "/") {
		panic("invalid callable name")
	}
	path := "/" + name
	if _, exists := s.routes[path]; exists {
		panic("duplicate callable name")
	}
	s.routes[path] = s.wrap(name, requireAuth, handler)
}

// wrap logs one "http request" line per call, in the same shape as the
// webhook routes, so log-based metrics can count traffic and errors per route.
func (s *Server) wrap(name string, requireAuth bool, handler Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		call, err := s.serve(w, r, requireAuth, handler)
		e, status := canonical(err)
		code := "ok"
		if err != nil {
			code = e.Code
		} else if r.Method == http.MethodOptions {
			status = http.StatusNoContent
		}
		fields := []zap.Field{
			zap.String("kind", "callable"),
			zap.String("callable", name),
			zap.String("method", r.Method),
			zap.String("path", r.URL.Path),
			zap.Int("status", status),
			zap.String("code", code),
			zap.String("provider", call.provider),
			zap.String("via", Via(r)),
			zap.Bool("authenticated", call.authenticated),
			zap.Float64("latency_ms", float64(time.Since(start))/float64(time.Millisecond)),
		}
		if status >= 500 {
			zap.L().Error("http request", append(fields, zap.Error(err))...)
			return
		}
		zap.L().Info("http request", fields...)
	})
}

// ProxyHeader names the Cloud Function that forwarded a request to the agent.
const ProxyHeader = "X-Rtchat-Proxy"

// Via is the forwarding Cloud Function, or empty for direct requests.
func Via(r *http.Request) string {
	via := r.Header.Get(ProxyHeader)
	if len(via) > 32 {
		return "invalid"
	}
	return via
}

// callInfo is what the request log records about a call.
type callInfo struct {
	provider      string
	authenticated bool
}

// serve writes the response and returns the error it sent, if any.
func (s *Server) serve(w http.ResponseWriter, r *http.Request, requireAuth bool, handler Handler) (call callInfo, err error) {
	fail := func(e error) (callInfo, error) {
		writeError(w, e)
		return call, e
	}
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, Firebase-Instance-ID-Token, X-Firebase-AppCheck")
	w.Header().Set("Vary", "Origin")
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return call, nil
	}
	if r.Method != http.MethodPost {
		return fail(&Error{Code: "invalid-argument", Message: "POST required"})
	}
	media, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || media != "application/json" {
		return fail(&Error{Code: "invalid-argument", Message: "JSON required"})
	}
	r.Body = http.MaxBytesReader(w, r.Body, 1024*1024)
	dec := json.NewDecoder(r.Body)
	data, err := readData(dec)
	if err != nil {
		return fail(&Error{Code: "invalid-argument", Message: "expected data envelope"})
	}
	var fields struct {
		Provider string `json:"provider"`
	}
	if json.Unmarshal(data, &fields) == nil && len(fields.Provider) <= 16 {
		call.provider = fields.Provider
	}
	ctx, cancel := context.WithTimeout(r.Context(), 60*time.Second)
	defer cancel()
	if authorization := r.Header.Get("Authorization"); authorization != "" {
		parts := strings.Split(authorization, " ")
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || parts[1] == "" || s.verify == nil {
			return fail(&Error{Code: "unauthenticated", Message: "invalid authentication"})
		}
		uid, err := s.verify(ctx, parts[1])
		if err != nil || uid == "" {
			return fail(&Error{Code: "unauthenticated", Message: "invalid authentication"})
		}
		ctx = context.WithValue(ctx, uidKey{}, uid)
		call.authenticated = true
	}
	if requireAuth && UID(ctx) == "" {
		return fail(&Error{Code: "unauthenticated", Message: "authentication required"})
	}
	result, err := invoke(ctx, data, handler)
	if err != nil {
		return fail(err)
	}
	payload, err := json.Marshal(map[string]any{"result": result})
	if err != nil {
		return fail(err)
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(payload)
	return call, nil
}

var statusCodes = map[string]int{"cancelled": 499, "unknown": 500, "invalid-argument": 400, "deadline-exceeded": 504, "not-found": 404, "already-exists": 409, "permission-denied": 403, "resource-exhausted": 429, "failed-precondition": 400, "aborted": 409, "out-of-range": 400, "unimplemented": 501, "internal": 500, "unavailable": 503, "data-loss": 500, "unauthenticated": 401}

// canonical maps err to the error and HTTP status sent to the client.
func canonical(err error) (*Error, int) {
	if err == nil {
		return nil, http.StatusOK
	}
	e := &Error{Code: "internal", Message: "INTERNAL"}
	var explicit *Error
	if errors.As(err, &explicit) {
		if _, ok := statusCodes[explicit.Code]; ok {
			e = explicit
		}
	} else if cancel.IsCanceled(err) {
		e = &Error{Code: "cancelled", Message: "CANCELLED"}
	} else if errors.Is(err, context.DeadlineExceeded) || status.Code(err) == codes.DeadlineExceeded {
		e = &Error{Code: "deadline-exceeded", Message: "DEADLINE_EXCEEDED"}
	}
	return e, statusCodes[e.Code]
}

func writeError(w http.ResponseWriter, err error) {
	e, status := canonical(err)
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
	w.WriteHeader(status)
	w.Write(payload)
}

// Decode a single data envelope using the standard JSON decoder. As with other
// Go JSON inputs, repeated keys use the last value.
func readData(dec *json.Decoder) (json.RawMessage, error) {
	var envelope map[string]json.RawMessage
	if err := dec.Decode(&envelope); err != nil {
		return nil, err
	}
	data, ok := envelope["data"]
	if !ok || len(envelope) != 1 {
		return nil, errors.New("expected data envelope")
	}
	if dec.Decode(new(any)) != io.EOF {
		return nil, errors.New("trailing JSON")
	}
	return decodeData(data)
}

func invoke(ctx context.Context, data json.RawMessage, handler Handler) (result any, err error) {
	defer func() {
		if value := recover(); value != nil {
			result = nil
			err = observability.CapturePanic(value)
		}
	}()
	return handler(ctx, data)
}
