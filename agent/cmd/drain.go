package main

import (
	"context"
	"errors"
	"net"
	"net/http"
	"sync/atomic"
	"time"

	"go.uber.org/zap"
)

// The load balancer marks a backend unhealthy after two failed /healthz
// probes two seconds apart, and the container runtime kills the process ten
// seconds after SIGTERM, so draining has to fit in that window.
const (
	drainDelay   = 5 * time.Second
	drainTimeout = 4 * time.Second
)

// drainableServer lets a spot preemption or rollout finish in-flight API
// requests instead of dropping them: draining fails /healthz so the load
// balancer stops routing new requests here, then shuts down gracefully.
type drainableServer struct {
	server   *http.Server
	draining atomic.Bool
}

func newDrainableServer(addr string) *drainableServer {
	return &drainableServer{server: &http.Server{Addr: addr}}
}

func (d *drainableServer) wrap(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if d.draining.Load() {
			// don't let the load balancer reuse this connection for new requests.
			w.Header().Set("Connection", "close")
			if r.URL.Path == "/healthz" {
				w.WriteHeader(http.StatusServiceUnavailable)
				return
			}
		}
		next.ServeHTTP(w, r)
	})
}

// Serve blocks until the server stops. A drained server returns nil.
func (d *drainableServer) Serve(handler http.Handler) error {
	listener, err := net.Listen("tcp", d.server.Addr)
	if err != nil {
		return err
	}
	return d.serve(listener, handler)
}

func (d *drainableServer) serve(listener net.Listener, handler http.Handler) error {
	d.server.Handler = d.wrap(handler)
	if err := d.server.Serve(listener); !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	return nil
}

// Drain fails health checks, waits delay for the load balancer to notice, then
// waits up to timeout for in-flight requests to finish.
func (d *drainableServer) Drain(delay, timeout time.Duration) {
	d.draining.Store(true)
	zap.L().Info("draining http server")
	time.Sleep(delay)
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	if err := d.server.Shutdown(ctx); err != nil {
		zap.L().Warn("http server did not drain in time", zap.Error(err))
		return
	}
	zap.L().Info("http server drained")
}
