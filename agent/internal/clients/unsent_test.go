package clients

import (
	"context"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
)

// dropFirst closes the first connection it accepts before the TLS handshake
// finishes, as a reset during connection setup does.
type dropFirst struct {
	net.Listener
	accepted atomic.Int32
}

func (l *dropFirst) Accept() (net.Conn, error) {
	for {
		conn, err := l.Listener.Accept()
		if err != nil || l.accepted.Add(1) > 1 {
			return conn, err
		}
		conn.Close()
	}
}

// A request that never reached the provider has no effect, so even a chat
// POST is safe to send again; one the provider may have received is not.
func TestDoResendsRequestsThatWereNeverWritten(t *testing.T) {
	var received atomic.Int32
	server := httptest.NewUnstartedServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		received.Add(1)
		io.WriteString(w, `{}`)
	}))
	server.Listener = &dropFirst{Listener: server.Listener}
	server.StartTLS()
	defer server.Close()
	client := Client{HTTP: server.Client(), BaseURL: server.URL}
	response, err := client.Do(context.Background(), http.MethodPost, "/chat/messages", map[string]string{"message": "hi"})
	if err != nil || response.StatusCode != 200 || received.Load() != 1 {
		t.Fatalf("err=%v received=%d", err, received.Load())
	}
}

func TestDoDoesNotResendWrittenRequests(t *testing.T) {
	var received atomic.Int32
	server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		received.Add(1)
		conn, _, _ := w.(http.Hijacker).Hijack()
		conn.Close() // received, but no response: the outcome is unknown
	}))
	defer server.Close()
	client := Client{HTTP: server.Client(), BaseURL: server.URL}
	if _, err := client.Do(context.Background(), http.MethodPost, "/chat/messages", map[string]string{"message": "hi"}); err == nil || received.Load() != 1 {
		t.Fatalf("err=%v received=%d; an ambiguous POST was resent", err, received.Load())
	}
}
