package webhook

import (
	"context"
	"errors"
	"io"
	"net/http"
	"reflect"
	"strings"
	"testing"
	"time"
)

type twitchRoundTripFunc func(*http.Request) (*http.Response, error)

func (f twitchRoundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func TestTwitchStatsRefresh(t *testing.T) {
	live := `{"data":[{"user_id":"twitch:1337","user_login":"cool_user","user_name":"Cool_User","viewer_count":100,"language":"en","started_at":"2020-07-15T18:16:11.171999Z"}]}`
	offline := `{"data":[{"broadcaster_id":"1337","broadcaster_login":"cool_user","broadcaster_name":"Cool_User","broadcaster_language":"en"}]}`
	for _, test := range []struct {
		name, token, streams, channels, followers string
		tokenStatus                               int
		wantChannels                              bool
		wantError                                 bool
		wantWrites                                []twitchDocument
	}{
		{name: "live", streams: live, followers: `{"total":42}`, wantWrites: []twitchDocument{
			{Path: "channels/twitch:twitch:1337", Merge: true, Data: map[string]interface{}{"viewerCount": int64(100), "language": "en", "login": "cool_user", "displayName": "Cool_User", "onlineAt": time.Date(2020, 7, 15, 18, 16, 11, 171000000, time.UTC)}},
			{Path: "channels/twitch:twitch:1337", Merge: true, Data: map[string]interface{}{"followerCount": int64(42)}},
		}},
		{name: "offline fallback", streams: `{"data":[]}`, channels: offline, followers: `{"total":0}`, wantChannels: true, wantWrites: []twitchDocument{
			{Path: "channels/twitch:1337", Merge: true, Data: map[string]interface{}{"viewerCount": int64(0), "language": "en", "login": "cool_user", "displayName": "Cool_User", "onlineAt": nil}},
		}},
		{name: "no stream data skips fallback", streams: `{"error":"Unauthorized"}`, followers: `{"error":"Unauthorized"}`},
		{name: "no fallback data", streams: `{"data":[]}`, channels: `{"error":"Bad Request"}`, followers: `{"total":0}`, wantChannels: true},
		{name: "token failure", token: `{"error":"Unauthorized"}`, tokenStatus: 401, wantError: true},
		{name: "bad stream json", streams: `{`, wantError: true},
		{name: "bad stream date", streams: `{"data":[{"user_id":"twitch:1337","started_at":"invalid"}]}`, wantError: true},
		{name: "follower failure prevents partial writes", streams: live, followers: `{`, wantError: true},
	} {
		t.Run(test.name, func(t *testing.T) {
			store := &fakeTwitchStore{}
			calls := []string{}
			stats := twitchStats{store: store, clientID: "client-id", clientSecret: "client-secret", client: &http.Client{Transport: twitchRoundTripFunc(func(r *http.Request) (*http.Response, error) {
				calls = append(calls, r.URL.Path)
				body := ""
				code := http.StatusOK
				if r.URL.Host == "id.twitch.tv" {
					if r.URL.Path != "/oauth2/token" || r.Method != http.MethodPost {
						t.Fatalf("token request %s %s", r.Method, r.URL)
					}
					if err := r.ParseForm(); err != nil {
						t.Fatal(err)
					}
					if r.Form.Get("client_id") != "client-id" || r.Form.Get("client_secret") != "client-secret" || r.Form.Get("grant_type") != "client_credentials" {
						t.Fatalf("wrong token form")
					}
					body = test.token
					if body == "" {
						body = `{"access_token":"app-token"}`
					}
					if test.tokenStatus != 0 {
						code = test.tokenStatus
					}
				} else {
					if r.URL.Host != "api.twitch.tv" || r.Method != http.MethodGet || r.Header.Get("Authorization") != "Bearer app-token" || r.Header.Get("Client-ID") != "client-id" {
						t.Fatalf("wrong helix request %s", r.URL)
					}
					switch r.URL.Path {
					case "/helix/streams":
						if r.URL.Query().Get("user_id") != "twitch:1337" || r.URL.Query().Get("first") != "100" {
							t.Fatalf("streams query %s", r.URL.RawQuery)
						}
						body = test.streams
					case "/helix/channels":
						if r.URL.Query().Get("broadcaster_id") != "twitch:1337" {
							t.Fatalf("channels query %s", r.URL.RawQuery)
						}
						body = test.channels
					case "/helix/channels/followers":
						if r.URL.Query().Get("broadcaster_id") != "twitch:1337" || r.URL.Query().Get("first") != "1" {
							t.Fatalf("followers query %s", r.URL.RawQuery)
						}
						body = test.followers
					default:
						t.Fatalf("unexpected request %s", r.URL)
					}
				}
				return &http.Response{StatusCode: code, Body: io.NopCloser(strings.NewReader(body)), Header: make(http.Header)}, nil
			})}}
			err := stats.refresh(context.Background(), "twitch:1337")
			if (err != nil) != test.wantError {
				t.Fatalf("error %v", err)
			}
			if !reflect.DeepEqual(store.writes, test.wantWrites) {
				t.Fatalf("writes %#v, want %#v", store.writes, test.wantWrites)
			}
			calledChannels := false
			for _, path := range calls {
				calledChannels = calledChannels || path == "/helix/channels"
			}
			if calledChannels != test.wantChannels {
				t.Fatalf("calls %v", calls)
			}
		})
	}
}

func TestTwitchStatsTransportAndStoreErrors(t *testing.T) {
	sentinel := errors.New("unavailable")
	stats := twitchStats{client: &http.Client{Transport: twitchRoundTripFunc(func(r *http.Request) (*http.Response, error) { return nil, sentinel })}}
	if err := stats.refresh(context.Background(), "twitch:1337"); !errors.Is(err, sentinel) {
		t.Fatalf("error %v", err)
	}
	stats.store = &fakeTwitchStore{setError: sentinel}
	stats.client.Transport = twitchRoundTripFunc(func(r *http.Request) (*http.Response, error) {
		body := `{"error":"Bad Request"}`
		switch r.URL.Path {
		case "/oauth2/token":
			body = `{"access_token":"app-token"}`
		case "/helix/channels/followers":
			body = `{"total":42}`
		}
		return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(body)), Header: make(http.Header)}, nil
	})
	if err := stats.refresh(context.Background(), "twitch:1337"); !errors.Is(err, sentinel) {
		t.Fatalf("error %v", err)
	}
}
