package handler

import (
	"context"
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
		c.onRoomState(twitch.RoomStateMessage{Channel: "room"})
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

func TestAuthenticatedJoinWaitsBeforeOpeningConnection(t *testing.T) {
	h := testAgent()
	waited := false
	h.WaitForAuth = func(ctx context.Context, login string) error {
		if login != "user" {
			t.Fatal(login)
		}
		waited = true
		return nil
	}
	c, _ := activeChat()
	defer c.Disconnect()
	h.newChat = func(string, string) chatConnection {
		if !waited {
			t.Fatal("opened IRC connection before shared authentication slot")
		}
		return c
	}
	h.bindChat = func(chatConnection) {}
	client, err := h.JoinAsUser(testRequest(), "uid")
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
}

func TestAuthenticatedJoinDoesNotConnectWhenGateFails(t *testing.T) {
	h := testAgent()
	h.WaitForAuth = func(context.Context, string) error { return context.Canceled }
	h.newChat = func(string, string) chatConnection { t.Fatal("opened connection despite canceled wait"); return nil }
	if _, err := h.JoinAsUser(testRequest(), "uid"); !errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
}

func TestAnonymousJoinDoesNotUseProfilesOrTokens(t *testing.T) {
	h := &TwitchAgent{
		loadProfile: func(string) (map[string]interface{}, error) {
			t.Fatal("anonymous join read a profile")
			return nil, nil
		},
		tokenSource: func(string) (oauth2.TokenSource, error) { t.Fatal("anonymous join requested a token"); return nil, nil },
		WaitForAuth: func(context.Context, string) error { t.Fatal("anonymous join entered authenticated queue"); return nil },
		bindChat:    func(chatConnection) {},
	}
	c, _ := activeChat()
	h.newChat = func(login, token string) chatConnection {
		if login != "" || token != "" {
			t.Fatal("anonymous join supplied credentials")
		}
		return c
	}
	client, err := h.NewClient(testRequest())
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
}

func TestJoinWaitsForRequestedRoomState(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	releaseConnection := make(chan struct{})
	defer close(releaseConnection)
	c := &fakeChat{}
	c.connect = func() error {
		c.onConnect()
		c.onRoomState(twitch.RoomStateMessage{Channel: "another-room"})
		cancel()
		// Keep the connection open so cancellation, rather than its exit,
		// ends the join. Otherwise both select cases can become ready at once.
		<-releaseConnection
		return twitch.ErrClientDisconnected
	}
	if err := joinWithContext(ctx, c, "room", time.Second); !errors.Is(err, context.Canceled) {
		t.Fatalf("login or another room was mistaken for a successful join: %v", err)
	}
}

func TestAnonymousJoinRetriesWithFreshConnection(t *testing.T) {
	h := testAgent()
	attempts := 0
	h.bindChat = func(chatConnection) {}
	h.newChat = func(string, string) chatConnection {
		attempts++
		if attempts == 1 {
			return &fakeChat{connect: func() error { return errors.New("temporary connection failure") }}
		}
		c, _ := activeChat()
		return c
	}
	client, err := h.JoinAnonymously(testRequest())
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	if attempts != 2 {
		t.Fatalf("attempts=%d", attempts)
	}
}

func TestAnonymousRetryStopsOnShutdown(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	h := testAgent()
	h.Context = ctx
	h.bindChat = func(chatConnection) {}
	attempts := 0
	h.newChat = func(string, string) chatConnection {
		attempts++
		return &fakeChat{connect: func() error { cancel(); return errors.New("temporary failure") }}
	}
	if _, err := h.JoinAnonymously(testRequest()); !errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
	if attempts != 1 {
		t.Fatal(attempts)
	}
}

func TestCloseAlreadyDisconnectedChat(t *testing.T) {
	for _, err := range []error{twitch.ErrConnectionIsNotOpen, twitch.ErrClientDisconnected} {
		c := &fakeChat{disconnect: func() error { return err }}
		if err := (&AnonymousTwitchClient{client: c}).Close(); err != nil {
			t.Fatal(err)
		}
		if err := (&AuthenticatedTwitchClient{client: c}).Close(); err != nil {
			t.Fatal(err)
		}
	}
}
