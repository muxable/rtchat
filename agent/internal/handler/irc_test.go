package handler

import (
	"bufio"
	"io"
	"net"
	"strings"
	"testing"
	"time"

	"github.com/gempir/go-twitch-irc/v4"
)

func TestIRCLoginIsNotChannelReadiness(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()
	joined := make(chan struct{})
	acknowledge := make(chan struct{})
	defer close(acknowledge)
	serverDone := make(chan error, 1)
	go func() {
		conn, err := listener.Accept()
		if err != nil {
			serverDone <- err
			return
		}
		defer conn.Close()
		_ = conn.SetDeadline(time.Now().Add(5 * time.Second))
		scanner := bufio.NewScanner(conn)
		for scanner.Scan() {
			line := scanner.Text()
			if strings.HasPrefix(line, "NICK ") {
				_, err = io.WriteString(conn, ":tmi.twitch.tv 001 guest :Welcome\r\n")
				if err != nil {
					serverDone <- err
					return
				}
			}
			if line == "JOIN #room" {
				close(joined)
				<-acknowledge
				_, err = io.WriteString(conn, "@room-id=42 :tmi.twitch.tv ROOMSTATE #room\r\n")
				serverDone <- err
				// Keep the socket open until the client is explicitly closed.
				for scanner.Scan() {
				}
				return
			}
		}
		serverDone <- scanner.Err()
	}()
	client := twitch.NewAnonymousClient()
	client.TLS = false
	client.IrcAddress = listener.Addr().String()
	defer client.Disconnect()
	ready := make(chan error, 1)
	go func() { ready <- joinWithTimeout(client, "room", 2*time.Second) }()
	select {
	case <-joined:
	case err := <-serverDone:
		t.Fatalf("IRC server failed: %v", err)
	case <-time.After(3 * time.Second):
		t.Fatal("client did not send JOIN")
	}
	select {
	case err := <-ready:
		t.Fatalf("login alone marked channel ready: %v", err)
	case <-time.After(20 * time.Millisecond):
	}
	acknowledge <- struct{}{}
	if err := <-ready; err != nil {
		t.Fatal(err)
	}
	if err := <-serverDone; err != nil {
		t.Fatal(err)
	}
}
