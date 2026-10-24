package webhook

import (
	"net/http"
	"sync"
	"sync/atomic"
	"time"

	"github.com/muxable/rtchat/agent/internal/callable"
	"go.uber.org/zap"
)

// Server holds the webhook routes and credentials for provider handlers.
type Server struct {
	Mux     *http.ServeMux
	Secrets Secrets
	// Draining, when set, fails /healthz so the load balancer stops routing
	// here before the process shuts down.
	Draining *atomic.Bool

	mu        sync.RWMutex
	providers map[string]http.Handler
}

// providerPrefixes are mounted once; RegisterProvider swaps the handler behind
// each, since ServeMux panics on duplicate registrations.
var providerPrefixes = []string{"/kick/", "/twitch/", "/alchemy/"}

func NewServer(secrets Secrets) *Server {
	s := &Server{
		Mux:       http.NewServeMux(),
		Secrets:   secrets,
		providers: map[string]http.Handler{},
	}
	// not logged: the load balancer probes this every few seconds.
	s.Mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		if s.Draining != nil && s.Draining.Load() {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		w.Write([]byte("ok"))
	})
	for _, prefix := range providerPrefixes {
		prefix := prefix
		s.providers[prefix] = http.HandlerFunc(notImplemented)
		s.Mux.Handle(prefix, LoggingMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			s.mu.RLock()
			handler := s.providers[prefix]
			s.mu.RUnlock()
			handler.ServeHTTP(w, r)
		})))
	}
	return s
}

// RegisterProvider replaces the handler for one of the provider prefixes.
func (s *Server) RegisterProvider(prefix string, handler http.Handler) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.providers[prefix]; !ok {
		panic("webhook: unknown provider prefix " + prefix)
	}
	s.providers[prefix] = handler
}

func notImplemented(w http.ResponseWriter, r *http.Request) {
	http.Error(w, http.StatusText(http.StatusNotImplemented), http.StatusNotImplemented)
}

// LoggingMiddleware logs request metadata without logging bodies or secrets.
func LoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		writer := &statusWriter{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(writer, r)
		zap.L().Info("http request",
			zap.String("method", r.Method),
			zap.String("path", r.URL.Path),
			zap.String("via", callable.Via(r)),
			zap.Int("status", writer.status),
			zap.Float64("latency_ms", float64(time.Since(start))/float64(time.Millisecond)),
		)
	})
}

type statusWriter struct {
	http.ResponseWriter
	status      int
	wroteHeader bool
}

func (w *statusWriter) WriteHeader(status int) {
	if w.wroteHeader {
		return
	}
	// Informational responses do not commit the final response status.
	if status >= 100 && status < 200 {
		w.ResponseWriter.WriteHeader(status)
		return
	}
	w.status = status
	w.wroteHeader = true
	w.ResponseWriter.WriteHeader(status)
}

func (w *statusWriter) Write(data []byte) (int, error) {
	if !w.wroteHeader {
		w.WriteHeader(http.StatusOK)
	}
	return w.ResponseWriter.Write(data)
}
