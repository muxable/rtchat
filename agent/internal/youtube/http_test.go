package youtube

import (
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"syscall"
	"testing"
)

// Exercise a real httptest server where possible. Restricted environments may
// prohibit even loopback sockets; the fallback runs the same HTTP handlers and
// request/response assertions through httptest recorders without a network.
type testServer struct {
	URL    string
	client *http.Client
	close  func()
}

func (s *testServer) Client() *http.Client { return s.client }
func (s *testServer) Close()               { s.close() }
func newTestServer(t *testing.T, handler http.Handler) *testServer {
	t.Helper()
	listener, err := net.Listen("tcp4", "127.0.0.1:0")
	if err == nil {
		server := &httptest.Server{Listener: listener, Config: &http.Server{Handler: handler}}
		server.Start()
		return &testServer{URL: server.URL, client: server.Client(), close: server.Close}
	}
	if !errors.Is(err, syscall.EPERM) && !errors.Is(err, syscall.EACCES) {
		t.Fatal(err)
	}
	t.Log("loopback sockets unavailable; using in-memory httptest transport")
	return &testServer{URL: "http://youtube.test", client: &http.Client{Transport: handlerTransport{handler}}, close: func() {}}
}

type handlerTransport struct{ handler http.Handler }

func (h handlerTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	if err := req.Context().Err(); err != nil {
		return nil, err
	}
	recorder := httptest.NewRecorder()
	h.handler.ServeHTTP(recorder, req)
	if err := req.Context().Err(); err != nil {
		return nil, err
	}
	return recorder.Result(), nil
}
