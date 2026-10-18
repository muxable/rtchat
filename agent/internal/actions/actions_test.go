package actions

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/clients/youtube"
	"github.com/muxable/rtchat/agent/internal/provider"
)

const own = "UCaaaaaaaaaaaaaaaaaaaaaa"
const other = "UCbbbbbbbbbbbbbbbbbbbbbb"
const viewer = "UCcccccccccccccccccccccc"

type mockTokens struct{ err error }

func (m mockTokens) AccessToken(_ context.Context, uid, p string) (string, error) {
	if uid != "verified-user" {
		return "", errors.New("wrong identity")
	}
	return "user-token", m.err
}
func (m mockTokens) AppAccessToken(context.Context, string) (string, error) { return "app-token", nil }
func (m mockTokens) Credentials(context.Context, string) (provider.Credentials, error) {
	return provider.Credentials{ClientID: "client-id"}, nil
}

type mockStore struct {
	profile       map[string]any
	start, cancel int
	raidErr       error
}

func (m *mockStore) Profile(context.Context, string) (map[string]any, error) { return m.profile, nil }
func (m *mockStore) RaidStart(_ context.Context, id string, target map[string]any, at time.Time) error {
	m.start++
	return m.raidErr
}
func (m *mockStore) RaidCancel(context.Context, string, time.Time) error {
	m.cancel++
	return m.raidErr
}

type roundTrip func(*http.Request) (*http.Response, error)

func (f roundTrip) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }
func respond(code int, body string) *http.Response {
	return &http.Response{StatusCode: code, Body: io.NopCloser(strings.NewReader(body)), Header: make(http.Header)}
}

// These standalone snapshots preserve the inline legacy functions/test action fixtures.
func fixture(t *testing.T, key string) string {
	t.Helper()
	data, err := os.ReadFile("testdata/provider-responses.json")
	if err != nil {
		t.Fatal(err)
	}
	var all map[string]json.RawMessage
	if err := json.Unmarshal(data, &all); err != nil {
		t.Fatal(err)
	}
	return string(all[key])
}
func newMock(transport roundTrip) (*Service, *mockStore) {
	store := &mockStore{profile: map[string]any{"twitch": map[string]any{"id": "sender"}, "youtube": map[string]any{"id": own}}}
	s := &Service{Tokens: mockTokens{}, Store: store, HTTP: &http.Client{Transport: transport}, SendIRC: func(context.Context, string, string, string, string) error { return nil }}
	return s, store
}
func call(t *testing.T, s *Service, name string, data any, authenticated bool) (int, map[string]any) {
	t.Helper()
	api := callable.NewServer(func(context.Context, string) (string, error) { return "verified-user", nil })
	s.Register(api)
	payload, err := json.Marshal(map[string]any{"data": data})
	if err != nil {
		t.Fatal(err)
	}
	req := httptest.NewRequest("POST", "/"+name, strings.NewReader(string(payload)))
	req.Header.Set("Content-Type", "application/json")
	if authenticated {
		req.Header.Set("Authorization", "Bearer firebase-token")
	}
	w := httptest.NewRecorder()
	api.ServeHTTP(w, req)
	var body map[string]any
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	return w.Code, body
}
func requestBody(t *testing.T, r *http.Request) map[string]any {
	t.Helper()
	var result map[string]any
	if r.Body != nil {
		if err := json.NewDecoder(r.Body).Decode(&result); err != nil {
			t.Fatal(err)
		}
	}
	return result
}
func assertNull(t *testing.T, code int, result map[string]any) {
	t.Helper()
	value, exists := result["result"]
	if code != 200 || !exists || value != nil {
		t.Fatalf("%d %#v", code, result)
	}
}
func TestAllActionsRequireVerifiedAuthentication(t *testing.T) {
	s, _ := newMock(func(r *http.Request) (*http.Response, error) { t.Fatal("unauthenticated side effect"); return nil, nil })
	for _, name := range []string{"send", "ban", "unban", "timeout", "deleteMessage", "clear", "raid", "cancelRaid"} {
		code, body := call(t, s, name, map[string]any{}, false)
		if code != 401 || field(object(body["error"]), "status") != "UNAUTHENTICATED" {
			t.Fatalf("%s %d %v", name, code, body)
		}
	}
}
func TestTwitchSendAndFallback(t *testing.T) {
	for _, tc := range []struct {
		name, fixture string
		status        int
		want          any
		fallback      bool
	}{{"sent", "twitchSent", 200, nil, false}, {"dropped", "twitchDropped", 200, "Your message is identical.", false}, {"missing scope", "twitchMissingScope", 401, nil, true}, {"forbidden", "twitchMissingScope", 403, nil, true}} {
		t.Run(tc.name, func(t *testing.T) {
			s, _ := newMock(func(r *http.Request) (*http.Response, error) {
				if r.Header.Get("Client-Id") != "client-id" {
					t.Fatal("missing Twitch client")
				}
				if r.URL.Path == "/helix/users" {
					login := "target"
					if r.URL.Query().Get("id") == "sender" {
						login = "sender-login"
					}
					return respond(200, `{"data":[{"login":"`+login+`"}]}`), nil
				}
				body := requestBody(t, r)
				if body["sender_id"] != "sender" || body["reply_parent_message_id"] != "parent" {
					t.Fatal(body)
				}
				return respond(tc.status, fixture(t, tc.fixture)), nil
			})
			called := false
			s.SendIRC = func(_ context.Context, token, login, channel, message string) error {
				called = true
				if token != "user-token" || login != "sender-login" || channel != "target" || message != "hello" {
					t.Fatal(token, login, channel, message)
				}
				return nil
			}
			code, body := call(t, s, "send", map[string]any{"provider": "twitch", "channelId": "broadcaster", "message": "hello", "replyToMessageId": "twitch:parent"}, true)
			if code != 200 || body["result"] != tc.want || called != tc.fallback {
				t.Fatalf("%d %v fallback=%v", code, body, called)
			}
		})
	}
}
func TestTwitchModerationAndRaids(t *testing.T) {
	for _, action := range []string{"ban", "unban", "timeout", "deleteMessage", "clear", "raid", "cancelRaid"} {
		t.Run(action, func(t *testing.T) {
			s, store := newMock(func(r *http.Request) (*http.Response, error) {
				if r.URL.Path == "/helix/users" {
					return respond(200, `{"data":[{"id":"resolved","login":"target","display_name":"Target"}]}`), nil
				}
				params := r.URL.Query()
				if action == "raid" {
					if params.Get("from_broadcaster_id") != "from" || params.Get("to_broadcaster_id") != "to" {
						t.Fatal(params)
					}
					return respond(200, `{"data":[{"created_at":"2026-10-16T00:00:00Z"}]}`), nil
				}
				if params.Get("broadcaster_id") != "broadcaster" {
					t.Fatal(params)
				}
				if action != "cancelRaid" && params.Get("moderator_id") != "sender" {
					t.Fatal(params)
				}
				if action == "ban" || action == "timeout" {
					body := requestBody(t, r)
					if field(object(body["data"]), "user_id") != "resolved" {
						t.Fatal(body)
					}
					if action == "timeout" && object(body["data"])["duration"] != float64(61) {
						t.Fatal(body)
					}
					return respond(200, `{"data":[{"user_id":"resolved"}]}`), nil
				}
				if action == "unban" && params.Get("user_id") != "resolved" {
					t.Fatal(params)
				}
				if action == "clear" && params.Has("message_id") {
					t.Fatal("clear must remove the whole chat", params)
				}
				if action == "deleteMessage" && params.Get("message_id") != "message" {
					t.Fatal(params)
				}
				if r.Method != "DELETE" {
					t.Fatal(r.Method)
				}
				return respond(204, ""), nil
			})
			store.raidErr = errors.New("database unavailable") // Recording failures cannot undo accepted Twitch operations.
			code, result := call(t, s, action, map[string]any{"provider": "twitch", "channelId": "broadcaster", "username": "target", "messageId": "twitch:message", "length": 61, "reason": "reason", "fromChannelId": "from", "toChannelId": "to"}, true)
			if code != 200 {
				t.Fatal(code, result)
			}
			if action == "raid" && store.start != 1 {
				t.Fatal("missing raid start")
			}
			if action == "cancelRaid" && store.cancel != 1 {
				t.Fatal("missing raid cancel")
			}
			if action != "ban" && action != "timeout" && action != "raid" {
				assertNull(t, code, result)
			}
		})
	}
}
func TestKickActions(t *testing.T) {
	for _, action := range []string{"send", "ban", "unban", "timeout", "deleteMessage"} {
		t.Run(action, func(t *testing.T) {
			s, _ := newMock(func(r *http.Request) (*http.Response, error) {
				if r.URL.Path == "/public/v1/channels" {
					if r.URL.Query().Get("slug") != "target" {
						t.Fatal(r.URL)
					}
					return respond(200, `{"data":[{"broadcaster_user_id":456}]}`), nil
				}
				if r.URL.Path == "/public/v1/chat/message" {
					if r.Method != "DELETE" {
						t.Fatal(r.Method)
					}
					return respond(204, ""), nil
				}
				body := requestBody(t, r)
				if body["broadcaster_user_id"] != float64(123) {
					t.Fatal(body)
				}
				if action == "send" {
					if body["reply_to_message_id"] != "parent" || body["content"] != "hello" {
						t.Fatal(body)
					}
					return respond(200, fixture(t, "kickSent")), nil
				}
				if body["user_id"] != float64(456) {
					t.Fatal(body)
				}
				if action == "timeout" && (body["duration"] != float64(2) || len(field(body, "reason")) != 100) {
					t.Fatal(body)
				}
				if action == "unban" && r.Method != "DELETE" {
					t.Fatal(r.Method)
				}
				return respond(204, ""), nil
			})
			code, body := call(t, s, action, map[string]any{"provider": "kick", "channelId": "123", "message": "hello", "replyToMessageId": "kick:parent", "messageId": "kick:message", "username": "target", "length": 61, "reason": strings.Repeat("x", 120)}, true)
			assertNull(t, code, body)
		})
	}
}
func TestYouTubeSendBanTimeoutDelete(t *testing.T) {
	for _, action := range []string{"send", "ban", "timeout", "deleteMessage"} {
		t.Run(action, func(t *testing.T) {
			s, _ := newMock(func(r *http.Request) (*http.Response, error) {
				if r.URL.Path == "/youtube/v3/liveBroadcasts" {
					if r.URL.Query().Get("mine") != "" {
						t.Fatal("unsupported mine")
					}
					return respond(200, fixture(t, "youtubeBroadcasts")), nil
				}
				if action == "deleteMessage" {
					if r.URL.Query().Get("id") != "message" || r.Method != "DELETE" {
						t.Fatal(r.URL, r.Method)
					}
					return respond(204, ""), nil
				}
				body := requestBody(t, r)
				snippet := object(body["snippet"])
				if snippet["liveChatId"] != "own-chat" {
					t.Fatal(body)
				}
				if action == "send" {
					if field(object(snippet["textMessageDetails"]), "messageText") != "hello" {
						t.Fatal(body)
					}
				} else {
					if field(object(snippet["bannedUserDetails"]), "channelId") != viewer {
						t.Fatal(body)
					}
					want := "permanent"
					if action == "timeout" {
						want = "temporary"
						if snippet["banDurationSeconds"] != float64(62) {
							t.Fatal(body)
						}
					}
					if snippet["type"] != want {
						t.Fatal(body)
					}
				}
				return respond(200, `{"id":"result-id"}`), nil
			})
			code, body := call(t, s, action, map[string]any{"provider": "youtube", "channelId": own, "message": "hello", "messageId": "youtube:message", "userId": viewer, "length": 61.1, "reason": "reason"}, true)
			assertNull(t, code, body)
		})
	}
}
func TestYouTubeErrorsAndCacheInvalidation(t *testing.T) {
	lookups := 0
	messages := 0
	s, _ := newMock(func(r *http.Request) (*http.Response, error) {
		if r.URL.Path == "/youtube/v3/liveBroadcasts" {
			lookups++
			return respond(200, fixture(t, "youtubeBroadcasts")), nil
		}
		messages++
		if messages == 1 {
			return respond(403, `{"error":{"errors":[{"reason":"liveChatEnded"}]}}`), nil
		}
		return respond(403, fixture(t, "youtubeQuota")), nil
	})
	data := map[string]any{"provider": "youtube", "channelId": own, "message": "hi"}
	code, body := call(t, s, "send", data, true)
	if code != 400 || field(object(body["error"]), "status") != "FAILED_PRECONDITION" {
		t.Fatal(code, body)
	}
	code, body = call(t, s, "send", data, true)
	if code != 429 || field(object(body["error"]), "message") != quotaMessage || lookups != 2 {
		t.Fatal(code, body, lookups)
	}
}
func TestYouTubeExplicitVideoOwnershipAndUnicodeLimit(t *testing.T) {
	var posts int
	s, _ := newMock(func(r *http.Request) (*http.Response, error) {
		if r.URL.Path == "/youtube/v3/videos" {
			return respond(200, fixture(t, "youtubeVideo")), nil
		}
		posts++
		return respond(200, `{"id":"sent"}`), nil
	})
	data := map[string]any{"provider": "youtube", "channelId": other, "videoId": "dQw4w9WgXcQ", "message": strings.Repeat("😀", 200)}
	code, body := call(t, s, "send", data, true)
	assertNull(t, code, body)
	data["message"] = strings.Repeat("😀", 201)
	code, _ = call(t, s, "send", data, true)
	if code != 400 || posts != 1 {
		t.Fatal(code, posts)
	}
	data["message"] = "hi"
	data["channelId"] = own
	code, body = call(t, s, "send", data, true)
	if code != 400 || field(object(body["error"]), "message") != "This YouTube channel isn't live." {
		t.Fatal(code, body)
	}
}
func TestYouTubeCacheConcurrentAccess(t *testing.T) {
	s, _ := newMock(func(r *http.Request) (*http.Response, error) {
		if r.URL.Path == "/youtube/v3/liveBroadcasts" {
			return respond(200, fixture(t, "youtubeBroadcasts")), nil
		}
		return respond(200, `{"id":"ok"}`), nil
	})
	var wg sync.WaitGroup
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			code, body := call(t, s, "send", map[string]any{"provider": "youtube", "channelId": own, "message": "hi"}, true)
			assertNull(t, code, body)
		}()
	}
	wg.Wait()
}
func TestMissingTokensAndUnsupportedActions(t *testing.T) {
	for _, p := range []string{"kick", "youtube"} {
		s, _ := newMock(func(r *http.Request) (*http.Response, error) { t.Fatal("request without grant"); return nil, nil })
		s.Tokens = mockTokens{err: provider.ErrNoToken}
		code, body := call(t, s, "send", map[string]any{"provider": p, "channelId": own, "message": "hello"}, true)
		if code != 400 || field(object(body["error"]), "status") != "FAILED_PRECONDITION" {
			t.Fatal(code, body)
		}
	}
	s, _ := newMock(nil)
	for _, p := range []string{"kick", "youtube"} {
		code, body := call(t, s, "clear", map[string]any{"provider": p, "channelId": "channel"}, true)
		if code != 400 {
			t.Fatal(code, body)
		}
	}
}

func TestProviderErrorParity(t *testing.T) {
	t.Run("Twitch JSON is a successful callable result", func(t *testing.T) {
		s, _ := newMock(func(r *http.Request) (*http.Response, error) {
			return respond(403, `{"error":"Forbidden","status":403,"message":"Missing moderator scope"}`), nil
		})
		code, body := call(t, s, "clear", map[string]any{"provider": "twitch", "channelId": "channel"}, true)
		if code != 200 || field(object(body["result"]), "message") != "Missing moderator scope" {
			t.Fatal(code, body)
		}
	})
	t.Run("Kick failures are hidden INTERNAL", func(t *testing.T) {
		s, _ := newMock(func(r *http.Request) (*http.Response, error) {
			return respond(403, `{"message":"private provider failure"}`), nil
		})
		code, body := call(t, s, "send", map[string]any{"provider": "kick", "channelId": "123", "message": "hi"}, true)
		if code != 500 || field(object(body["error"]), "message") != "INTERNAL" {
			t.Fatal(code, body)
		}
	})
	for _, tc := range []struct {
		status       int
		reason, code string
	}{{403, "quotaExceeded", "resource-exhausted"}, {403, "rateLimitExceeded", "resource-exhausted"}, {404, "liveChatNotFound", "failed-precondition"}, {401, "authError", "unauthenticated"}, {403, "forbidden", "permission-denied"}, {404, "notFound", "not-found"}, {503, "backendError", "unavailable"}, {400, "badRequest", "internal"}} {
		t.Run(tc.reason, func(t *testing.T) {
			client := youtube.New(&http.Client{Transport: roundTrip(func(*http.Request) (*http.Response, error) {
				payload, _ := json.Marshal(map[string]any{"error": map[string]any{"errors": []any{map[string]any{"reason": tc.reason}}}})
				return respond(tc.status, string(payload)), nil
			})}, "token")
			err := youtubeError(client.DeleteMessage(context.Background(), "message")).(*callable.Error)
			if err.Code != tc.code || object(err.Details)["status"] != tc.status {
				t.Fatalf("%+v", err)
			}
		})
	}
}
