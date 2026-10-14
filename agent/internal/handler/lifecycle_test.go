package handler

import (
	"errors"
	"testing"
	"time"

	"github.com/gempir/go-twitch-irc/v3"
)

type fakeChat struct {
	onConnect   func()
	connect     func() error
	disconnect  func() error
	onReconnect func(twitch.ReconnectMessage)
	token       string
	connects    int
}

func (c *fakeChat) OnConnect(f func()) { c.onConnect = f }

func (c *fakeChat) Join(...string) {}

func (c *fakeChat) Connect() error { c.connects++; return c.connect() }

func (c *fakeChat) Disconnect() error {
	if c.disconnect != nil {
		return c.disconnect()
	}
	return nil
}

func (c *fakeChat) Say(string, string) {}

func (c *fakeChat) Reply(string, string, string) {}

func TestJoinHonorsTimeout(t *testing.T) {
	done := make(chan struct{})
	c := &fakeChat{connect: func() error { <-done; return twitch.ErrClientDisconnected }, disconnect: func() error { close(done); return nil }}
	start := time.Now()
	err := joinWithTimeout(c, "room", 10*time.Millisecond)
	if err == nil || time.Since(start) > time.Second {
		t.Fatalf("timeout=%v elapsed=%s", err, time.Since(start))
	}
}

func TestJoinReturnsConnectError(t *testing.T) {
	want := errors.New("authentication rejected")
	c := &fakeChat{connect: func() error { return want }}
	start := time.Now()
	err := joinWithTimeout(c, "room", time.Second)
	if !errors.Is(err, want) || time.Since(start) > 500*time.Millisecond {
		t.Fatalf("error=%v elapsed=%s", err, time.Since(start))
	}
}

func TestAuthenticatedCloseCleansAllResources(t *testing.T) {
	first := errors.New("reader closed")
	sendClosed, canceled := false, false
	c := &AuthenticatedTwitchClient{client: &fakeChat{disconnect: func() error { return first }}, sendClient: &fakeChat{disconnect: func() error { sendClosed = true; return nil }}, raidCancel: func() { canceled = true }}
	if err := c.Close(); !errors.Is(err, first) {
		t.Fatal(err)
	}
	if !sendClosed || !canceled {
		t.Fatalf("send closed=%v raid canceled=%v", sendClosed, canceled)
	}
}

func (c *fakeChat) OnReconnectMessage(f func(twitch.ReconnectMessage)) { c.onReconnect = f }

func (c *fakeChat) SetIRCToken(token string) { c.token = token }
