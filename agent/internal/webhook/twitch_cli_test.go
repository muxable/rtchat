package webhook

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"reflect"
	"strconv"
	"sync"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
)

// These tests drive the handler with signed traffic from the Twitch CLI
// (https://dev.twitch.tv/docs/cli/). Set TWITCH_CLI to the binary, or put
// `twitch` on the PATH.

const (
	twitchCLISecret      = "twitch-cli-secret"
	twitchCLIBroadcaster = "1234"
	twitchCLIChannel     = "channels/twitch:" + twitchCLIBroadcaster
)

// twitchCLITypes are the subscriptions eventsub.ts creates, at the versions
// it creates them with.
var twitchCLITypes = []struct{ eventType, version string }{
	{"channel.follow", "2"},
	{"channel.subscribe", "1"},
	{"channel.subscription.gift", "1"},
	{"channel.subscription.message", "1"},
	{"channel.subscription.end", "1"},
	{"channel.cheer", "1"},
	{"channel.raid", "1"},
	{"channel.ban", "1"},
	{"channel.unban", "1"},
	{"channel.channel_points_custom_reward_redemption.add", "1"},
	{"channel.channel_points_custom_reward_redemption.update", "1"},
	{"channel.poll.begin", "1"},
	{"channel.poll.progress", "1"},
	{"channel.poll.end", "1"},
	{"channel.prediction.begin", "1"},
	{"channel.prediction.progress", "1"},
	{"channel.prediction.lock", "1"},
	{"channel.prediction.end", "1"},
	{"channel.hype_train.begin", "1"},
	{"channel.hype_train.progress", "1"},
	{"channel.hype_train.end", "1"},
	{"channel.update", "1"},
	{"stream.online", "1"},
	{"stream.offline", "1"},
	{"channel.shoutout.create", "1"},
	{"channel.shoutout.receive", "1"},
}

// twitchCLI returns the CLI's path. A missing CLI fails the tests in CI
// rather than silently skipping them.
func twitchCLI(t *testing.T) string {
	t.Helper()
	path := os.Getenv("TWITCH_CLI")
	if path == "" {
		path = "twitch"
	}
	resolved, err := exec.LookPath(path)
	if err != nil {
		if os.Getenv("CI") != "" {
			t.Fatalf("twitch cli %q not found: %v", path, err)
		}
		t.Skipf("twitch cli %q not found, set TWITCH_CLI or put twitch on the PATH", path)
	}
	return resolved
}

func runTwitchCLI(t *testing.T, args ...string) (string, error) {
	t.Helper()
	cmd := exec.Command(twitchCLI(t), args...)
	// otherwise the CLI asks GitHub for its latest release on every run, and
	// panics when GitHub rate-limits it.
	cmd.Env = append(os.Environ(), "TWITCH_DISABLE_UPDATE_CHECKS=true")
	out, err := cmd.CombinedOutput()
	return string(out), err
}

type twitchDelivery struct {
	header      http.Header
	body        []byte
	status      int
	contentType string
	response    string
}

// twitchCLIServer serves the handler behind the real webhook mux and records
// what the CLI sent and what the handler answered.
type twitchCLIServer struct {
	*httptest.Server
	store *lockedTwitchStore

	mu           sync.Mutex
	deliveries   []twitchDelivery
	deauthorized []string
}

func newTwitchCLIServer(t *testing.T) *twitchCLIServer {
	s := &twitchCLIServer{store: &lockedTwitchStore{}}
	h := &TwitchHandler{Secret: twitchCLISecret, Store: s.store, OnDeauthorized: func(id string) {
		s.mu.Lock()
		defer s.mu.Unlock()
		s.deauthorized = append(s.deauthorized, id)
	}}
	server := NewServer(Secrets{})
	server.RegisterProvider("/twitch/", h)
	s.Server = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(r.Body)
		if err != nil {
			t.Error(err)
			return
		}
		r.Body = io.NopCloser(bytes.NewReader(body))
		recorder := httptest.NewRecorder()
		server.Mux.ServeHTTP(recorder, r)
		s.mu.Lock()
		s.deliveries = append(s.deliveries, twitchDelivery{
			header: r.Header.Clone(), body: body, status: recorder.Code,
			contentType: recorder.Header().Get("Content-Type"), response: recorder.Body.String(),
		})
		s.mu.Unlock()
		for key, values := range recorder.Header() {
			w.Header()[key] = values
		}
		w.WriteHeader(recorder.Code)
		w.Write(recorder.Body.Bytes())
	}))
	t.Cleanup(s.Close)
	return s
}

func (s *twitchCLIServer) callback() string { return s.URL + "/twitch/eventsub" }

// delivery returns the only request the server has received.
func (s *twitchCLIServer) delivery(t *testing.T) twitchDelivery {
	t.Helper()
	s.mu.Lock()
	defer s.mu.Unlock()
	if len(s.deliveries) != 1 {
		t.Fatalf("got %d deliveries, want 1", len(s.deliveries))
	}
	return s.deliveries[0]
}

// lockedTwitchStore records writes made on the server's goroutines.
type lockedTwitchStore struct {
	mu    sync.Mutex
	store fakeTwitchStore
}

func (s *lockedTwitchStore) Set(ctx context.Context, path string, data map[string]interface{}, merge bool) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.store.Set(ctx, path, data, merge)
}

func (s *lockedTwitchStore) Create(ctx context.Context, path string, data map[string]interface{}) (bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.store.Create(ctx, path, data)
}

func (s *lockedTwitchStore) Update(ctx context.Context, path string, data map[string]interface{}) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.store.Update(ctx, path, data)
}

func (s *lockedTwitchStore) mergeBatch(ctx context.Context, documents []twitchDocument) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.store.mergeBatch(ctx, documents)
}

func (s *lockedTwitchStore) writes() []twitchDocument {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]twitchDocument(nil), s.store.writes...)
}

// triggerTwitchCLI sends one notification of eventType for the test
// broadcaster with a fresh message id and returns that id.
func triggerTwitchCLI(t *testing.T, s *twitchCLIServer, secret, eventType, version string, flags ...string) string {
	t.Helper()
	// shoutouts are created by the --from-user, everything else is received
	// by the --to-user.
	broadcaster := "-t"
	if eventType == "channel.shoutout.create" {
		broadcaster = "-f"
	}
	messageID := "cli-" + strconv.FormatInt(time.Now().UnixNano(), 36)
	args := append([]string{
		"event", "trigger", eventType, "--transport=webhook", "-F", s.callback(), "-s", secret, "--no-config",
		broadcaster, twitchCLIBroadcaster, "-I", messageID, "-v", version,
	}, flags...)
	if out, err := runTwitchCLI(t, args...); err != nil {
		t.Fatalf("twitch %v: %v\n%s", args, err, out)
	}
	return messageID
}

// sentEvent is the event exactly as the CLI sent it.
func sentEvent(t *testing.T, d twitchDelivery) map[string]interface{} {
	t.Helper()
	var payload struct {
		Subscription struct {
			Type string `json:"type"`
		} `json:"subscription"`
		Event map[string]interface{} `json:"event"`
	}
	if err := json.Unmarshal(d.body, &payload); err != nil {
		t.Fatal(err)
	}
	return payload.Event
}

// sameJSON compares values by their JSON encoding, so the handler's int64
// conversion of integral numbers doesn't count as a difference.
func sameJSON(t *testing.T, got, want interface{}) bool {
	t.Helper()
	a, err := json.Marshal(got)
	if err != nil {
		t.Fatal(err)
	}
	b, err := json.Marshal(want)
	if err != nil {
		t.Fatal(err)
	}
	return bytes.Equal(a, b)
}

func TestTwitchCLINotifications(t *testing.T) {
	twitchCLI(t)
	for _, test := range twitchCLITypes {
		test := test
		t.Run(test.eventType, func(t *testing.T) {
			s := newTwitchCLIServer(t)
			before := time.Now()
			messageID := triggerTwitchCLI(t, s, twitchCLISecret, test.eventType, test.version)

			d := s.delivery(t)
			if d.status != http.StatusOK {
				t.Fatalf("status %d, want 200", d.status)
			}
			if got := d.header.Get("Twitch-Eventsub-Subscription-Type"); got != test.eventType {
				t.Fatalf("cli sent %q", got)
			}
			event := sentEvent(t, d)
			writes := s.store.writes()
			if len(writes) == 0 {
				t.Fatal("no writes")
			}
			message := writes[0]
			messagePath := twitchCLIChannel + "/messages/twitch:" + messageID
			if test.eventType == "channel.follow" {
				messagePath = twitchCLIChannel + "/messages/twitch:follow:" + event["user_id"].(string)
			}
			if message.Path != messagePath || message.Merge || message.Update || message.Create != (test.eventType == "channel.follow") {
				t.Fatalf("message written as %#v", message)
			}
			if message.Data["channelId"] != "twitch:"+twitchCLIBroadcaster || message.Data["type"] != test.eventType {
				t.Fatalf("message data %#v", message.Data)
			}
			if !sameJSON(t, message.Data["event"], event) {
				t.Fatalf("stored event %#v, cli sent %#v", message.Data["event"], event)
			}
			sent, err := time.Parse(time.RFC3339Nano, d.header.Get("Twitch-Eventsub-Message-Timestamp"))
			if err != nil {
				t.Fatal(err)
			}
			if got, _ := message.Data["timestamp"].(time.Time); !got.Equal(sent.Truncate(time.Millisecond)) {
				t.Fatalf("timestamp %v, cli sent %v", got, sent)
			}
			if expiresAt, _ := message.Data["expiresAt"].(time.Time); expiresAt.Before(before.Add(14 * 24 * time.Hour).Truncate(time.Millisecond)) {
				t.Fatalf("expiresAt %v", message.Data["expiresAt"])
			}

			var channel []twitchDocument
			if len(writes) > 1 {
				channel = writes[1:]
			}
			var want []twitchDocument
			switch test.eventType {
			case "stream.online":
				want = []twitchDocument{{Path: twitchCLIChannel, Data: map[string]interface{}{"onlineAt": firestore.ServerTimestamp}, Merge: true}}
			case "stream.offline":
				want = []twitchDocument{{Path: twitchCLIChannel, Data: map[string]interface{}{"onlineAt": nil}, Merge: true}}
			case "channel.follow":
				want = []twitchDocument{{Path: twitchCLIChannel, Data: map[string]interface{}{"followerCount": firestore.Increment(1)}, Update: true}}
			case "channel.update":
				want = []twitchDocument{{Path: twitchCLIChannel, Data: map[string]interface{}{
					"login": event["broadcaster_user_login"], "displayName": event["broadcaster_user_name"],
					"title": event["title"], "language": event["language"],
					"categoryId": event["category_id"], "categoryName": event["category_name"],
				}, Merge: true}}
			}
			if !reflect.DeepEqual(channel, want) {
				t.Fatalf("channel writes %#v, want %#v", channel, want)
			}
		})
	}
}

// Twitch sometimes sends two follows, with different message ids, for one
// follower. Only the first is recorded and counted.
func TestTwitchCLIRepeatedFollow(t *testing.T) {
	twitchCLI(t)
	s := newTwitchCLIServer(t)
	first := triggerTwitchCLI(t, s, twitchCLISecret, "channel.follow", "2", "-f", "5678")
	second := triggerTwitchCLI(t, s, twitchCLISecret, "channel.follow", "2", "-f", "5678")
	if first == second {
		t.Fatal("cli reused the message id")
	}
	s.mu.Lock()
	for _, d := range s.deliveries {
		if d.status != http.StatusOK {
			t.Fatalf("status %d, want 200", d.status)
		}
	}
	s.mu.Unlock()
	want := []twitchDocument{
		{Path: twitchCLIChannel + "/messages/twitch:follow:5678", Create: true},
		{Path: twitchCLIChannel, Update: true},
		{Path: twitchCLIChannel + "/messages/twitch:follow:5678", Create: true},
	}
	writes := s.store.writes()
	if len(writes) != len(want) {
		t.Fatalf("writes %#v", writes)
	}
	for i, write := range writes {
		if write.Path != want[i].Path || write.Create != want[i].Create || write.Update != want[i].Update {
			t.Fatalf("write %d %#v, want %#v", i, write, want[i])
		}
	}
}

func TestTwitchCLIIncomingRaid(t *testing.T) {
	twitchCLI(t)
	s := newTwitchCLIServer(t)
	messageID := triggerTwitchCLI(t, s, twitchCLISecret, "channel.raid", "1")

	event := sentEvent(t, s.delivery(t))
	if event["to_broadcaster_user_id"] != twitchCLIBroadcaster {
		t.Fatalf("cli raided %v", event["to_broadcaster_user_id"])
	}
	if writes := s.store.writes(); len(writes) != 1 || writes[0].Path != twitchCLIChannel+"/messages/twitch:"+messageID {
		t.Fatalf("writes %#v", writes)
	}
}

func TestTwitchCLIChannelUpdate(t *testing.T) {
	twitchCLI(t)
	s := newTwitchCLIServer(t)
	triggerTwitchCLI(t, s, twitchCLISecret, "channel.update", "1", "-d", "a new title", "-G", "509658")

	writes := s.store.writes()
	if len(writes) != 2 {
		t.Fatalf("writes %#v", writes)
	}
	if got := writes[1].Data; got["title"] != "a new title" || got["categoryId"] != "509658" {
		t.Fatalf("channel data %#v", got)
	}
}

func TestTwitchCLIVerifySubscription(t *testing.T) {
	twitchCLI(t)
	s := newTwitchCLIServer(t)
	// the CLI exits non-zero unless the handshake succeeds.
	if out, err := runTwitchCLI(t, "event", "verify-subscription", "stream.online", "--transport=webhook", "-F", s.callback(), "-s", twitchCLISecret, "--no-config"); err != nil {
		t.Fatalf("verify-subscription: %v\n%s", err, out)
	}

	d := s.delivery(t)
	var payload struct {
		Challenge string `json:"challenge"`
	}
	if err := json.Unmarshal(d.body, &payload); err != nil {
		t.Fatal(err)
	}
	if d.status != http.StatusOK || d.response != payload.Challenge || d.contentType != "text/plain; charset=utf-8" {
		t.Fatalf("answered %d %q (%s), challenge %q", d.status, d.response, d.contentType, payload.Challenge)
	}
	if writes := s.store.writes(); len(writes) != 0 {
		t.Fatalf("writes %#v", writes)
	}
}

func TestTwitchCLIWrongSecret(t *testing.T) {
	twitchCLI(t)
	t.Run("notification", func(t *testing.T) {
		s := newTwitchCLIServer(t)
		triggerTwitchCLI(t, s, "not-the-twitch-cli-secret", "stream.online", "1")

		if d := s.delivery(t); d.status != http.StatusForbidden {
			t.Fatalf("status %d, want 403", d.status)
		}
		if writes := s.store.writes(); len(writes) != 0 {
			t.Fatalf("writes %#v", writes)
		}
	})
	t.Run("challenge", func(t *testing.T) {
		s := newTwitchCLIServer(t)
		if out, err := runTwitchCLI(t, "event", "verify-subscription", "stream.online", "--transport=webhook", "-F", s.callback(), "-s", "not-the-twitch-cli-secret", "--no-config"); err == nil {
			t.Fatalf("verify-subscription passed with the wrong secret\n%s", out)
		}
		if d := s.delivery(t); d.status != http.StatusForbidden {
			t.Fatalf("status %d, want 403", d.status)
		}
	})
}

// The app's user.authorization.revoke subscription is acknowledged without a
// chat message and reports the broadcaster.
func TestTwitchCLIAuthorizationRevoke(t *testing.T) {
	twitchCLI(t)
	s := newTwitchCLIServer(t)
	// The CLI sends the --from-user as the user who revoked.
	args := []string{"event", "trigger", "user.authorization.revoke", "--transport=webhook", "-F", s.callback(), "-s", twitchCLISecret, "--no-config", "-f", twitchCLIBroadcaster, "--client-id", "client"}
	if out, err := runTwitchCLI(t, args...); err != nil {
		t.Fatalf("twitch %v: %v\n%s", args, err, out)
	}
	d := s.delivery(t)
	if d.status != http.StatusOK {
		t.Fatalf("status %d, want 200", d.status)
	}
	if event := sentEvent(t, d); event["user_id"] != twitchCLIBroadcaster || event["client_id"] != "client" {
		t.Fatalf("cli sent %#v", event)
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if !reflect.DeepEqual(s.deauthorized, []string{twitchCLIBroadcaster}) {
		t.Fatalf("deauthorized %v", s.deauthorized)
	}
	if writes := s.store.writes(); len(writes) != 0 {
		t.Fatalf("writes %#v", writes)
	}
}
