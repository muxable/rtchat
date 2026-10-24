package handler

import (
	"errors"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/gempir/go-twitch-irc/v4"
	"github.com/muxable/rtchat/agent/internal/agent"
	"golang.org/x/oauth2"
)

func testRequest() *agent.Request { return (*agent.Request)(&firestore.DocumentRef{ID: "twitch:room"}) }

func testAgent() *TwitchAgent {
	return &TwitchAgent{loadProfile: func(string) (map[string]interface{}, error) {
		return map[string]interface{}{"login": "user", "id": "42"}, nil
	}, tokenSource: func(string) (oauth2.TokenSource, error) {
		return oauth2.StaticTokenSource(&oauth2.Token{AccessToken: "fresh"}), nil
	}}
}

func activeChat() (*fakeChat, chan struct{}) {
	done := make(chan struct{})
	c := &fakeChat{}
	c.connect = func() error {
		if c.connects > 1 {
			return nil
		}
		c.onConnect()
		<-done
		return twitch.ErrClientDisconnected
	}
	c.disconnect = func() error {
		select {
		case <-done:
		default:
			close(done)
		}
		return nil
	}
	return c, done
}

func TestAnonymousBindsEvents(t *testing.T) {
	h := testAgent()
	bound := false
	c, done := activeChat()
	defer c.Disconnect()
	h.newChat = func(string, string) chatConnection { return c }
	h.bindChat = func(chatConnection) { bound = true }
	client, err := h.JoinAnonymously(testRequest())
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	if !bound {
		t.Fatal("anonymous client has no chat handlers")
	}
	_ = done
}

func TestAuthenticatedBindsBeforeConnect(t *testing.T) {
	h := testAgent()
	h.loadProfile = func(string) (map[string]interface{}, error) {
		return map[string]interface{}{"login": "realtimechat"}, nil
	}
	bound := false
	observed := make(chan bool, 1)
	c, _ := activeChat()
	defer c.Disconnect()
	original := c.connect
	c.connect = func() error { observed <- bound; return original() }
	h.newChat = func(string, string) chatConnection { return c }
	h.bindChat = func(chatConnection) { bound = true }
	client, err := h.JoinAsUser(testRequest(), "uid")
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	if !<-observed {
		t.Fatal("connected before binding events; initial messages lost and callbacks race")
	}
}

func TestAuthenticatedJoinOpensOneConnection(t *testing.T) {
	h := testAgent()
	c, _ := activeChat()
	defer c.Disconnect()
	opened := 0
	h.newChat = func(string, string) chatConnection { opened++; return c }
	h.bindChat = func(chatConnection) {}
	client, err := h.JoinAsUser(testRequest(), "uid")
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	if opened != 1 {
		t.Fatalf("opened %d connections; sends go through helix", opened)
	}
	c.onReconnect(twitch.ReconnectMessage{})
	if c.token != "oauth:fresh" || c.connects != 1 {
		t.Errorf("token=%q connects=%d", c.token, c.connects)
	}
}

func TestJoinDisconnectsLateConnection(t *testing.T) {
	allow := make(chan struct{})
	finished := make(chan struct{})
	calls := 0
	c := &fakeChat{}
	c.connect = func() error { <-allow; c.onConnect(); close(finished); return nil }
	c.disconnect = func() error { calls++; return twitch.ErrConnectionIsNotOpen }
	if err := joinWithTimeout(c, "room", time.Millisecond); err == nil {
		t.Fatal("expected timeout")
	}
	close(allow)
	<-finished
	if calls != 2 {
		t.Fatalf("disconnect calls=%d; late connection leaked", calls)
	}
}

func TestJoinRejectsMalformedProfile(t *testing.T) {
	for _, profile := range []map[string]interface{}{{}, {"login": 123}, {"login": ""}, {"login": "user", "id": 123}} {
		t.Run("profile", func(t *testing.T) {
			h := testAgent()
			h.loadProfile = func(string) (map[string]interface{}, error) { return profile, nil }
			h.newChat = func(string, string) chatConnection {
				t.Error("created client for invalid profile")
				return &fakeChat{connect: func() error { return errors.New("invalid") }}
			}
			h.bindChat = func(chatConnection) {}
			defer func() {
				if r := recover(); r != nil {
					t.Fatalf("panic: %v", r)
				}
			}()
			if _, err := h.JoinAsUser(testRequest(), "uid"); err == nil {
				t.Fatal("invalid profile accepted")
			}
		})
	}
}

func TestTwitchProfileMalformed(t *testing.T) {
	for _, data := range []map[string]interface{}{{}, {"twitch": 123}} {
		t.Run("profile", func(t *testing.T) {
			defer func() {
				if r := recover(); r != nil {
					t.Fatalf("panic: %v", r)
				}
			}()
			if _, err := twitchProfile(data); err == nil {
				t.Fatal("invalid nested profile accepted")
			}
		})
	}
}
