package jobs

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"testing"
	"time"
)

type testTokens struct{}

func (testTokens) AppAccessToken(context.Context, string) (string, error) { return "app-token", nil }
func TestTwitchMetadataAndFollowerCap(t *testing.T) {
	users, streams, followers := 0, 0, 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer app-token" || r.Header.Get("Client-ID") != "client" {
			t.Error("missing provider credentials")
		}
		q := r.URL.Query()
		switch r.URL.Path {
		case "/users":
			users++
			if len(q["login"]) > 100 {
				t.Error("user batch exceeds 100")
			}
			data := []map[string]string{}
			for _, id := range q["login"] {
				data = append(data, map[string]string{"id": id})
			}
			json.NewEncoder(w).Encode(map[string]interface{}{"data": data})
		case "/streams":
			streams++
			if len(q["user_id"]) > 100 {
				t.Error("stream batch exceeds 100")
			}
			data := []map[string]interface{}{}
			for _, id := range q["user_id"] {
				if id == "0" {
					data = append(data, map[string]interface{}{"user_id": id, "user_login": "live", "user_name": "Live", "language": "en", "viewer_count": 321, "started_at": "2026-10-16T12:00:00Z"})
				}
			}
			json.NewEncoder(w).Encode(map[string]interface{}{"data": data})
		case "/channels":
			data := []map[string]string{}
			for _, id := range q["broadcaster_id"] {
				data = append(data, map[string]string{"broadcaster_id": id, "broadcaster_login": "offline", "broadcaster_name": "Offline", "broadcaster_language": "fr"})
			}
			json.NewEncoder(w).Encode(map[string]interface{}{"data": data})
		case "/channels/followers":
			followers++
			fmt.Fprint(w, `{"total":42}`)
		default:
			t.Error(r.URL.Path)
			http.NotFound(w, r)
		}
	}))
	defer server.Close()
	a := API{Tokens: testTokens{}, Client: server.Client(), TwitchClientID: "client", TwitchURL: server.URL}
	logins := []string{}
	for i := 0; i < 205; i++ {
		logins = append(logins, strconv.Itoa(i))
	}
	metadata := map[string]map[string]interface{}{}
	err := a.FetchTwitch(context.Background(), logins, func(updates []ChannelUpdate) error {
		for _, u := range updates {
			if len(u.Data) > 1 {
				metadata[u.ID] = u.Data
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if users != 3 || streams != 3 || followers != 200 {
		t.Fatalf("users=%d streams=%d followers=%d", users, streams, followers)
	}
	if metadata["twitch:0"]["viewerCount"] != int64(321) || metadata["twitch:0"]["displayName"] != "Live" {
		t.Fatal(metadata["twitch:0"])
	}
	if metadata["twitch:1"]["viewerCount"] != int64(0) || metadata["twitch:1"]["onlineAt"] != nil || metadata["twitch:1"]["language"] != "fr" {
		t.Fatal(metadata["twitch:1"])
	}
}
func TestKickMetadataParity(t *testing.T) {
	var channel KickChannel
	if err := json.Unmarshal([]byte(`{"broadcaster_user_id":123,"slug":"streamer","stream_title":"Hello","category":{"id":9,"name":"IRL"},"stream":{"is_live":true,"language":"en","viewer_count":12,"start_time":"2026-10-16T12:00:00Z"}}`), &channel); err != nil {
		t.Fatal(err)
	}
	data, err := channel.Metadata()
	if err != nil {
		t.Fatal(err)
	}
	if data["viewerCount"] != int64(12) || data["categoryId"] != float64(9) || data["onlineAt"].(time.Time).Hour() != 12 {
		t.Fatal(data)
	}
	channel.Stream.Live = false
	data, err = channel.Metadata()
	if err != nil || data["viewerCount"] != int64(0) || data["onlineAt"] != nil {
		t.Fatal(data, err)
	}
	var empty KickChannel
	data, _ = empty.Metadata()
	for _, field := range []string{"title", "language", "categoryId", "categoryName", "onlineAt"} {
		if data[field] != nil {
			t.Error(field, data[field])
		}
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func TestHTTPRateLimitCancellationAndIdempotentDelete(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	attempts := 0
	client := &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
		attempts++
		status := http.StatusNotFound
		if r.Method != http.MethodDelete {
			status = http.StatusTooManyRequests
			cancel()
		}
		return &http.Response{StatusCode: status, Header: http.Header{"Retry-After": {"60"}}, Body: io.NopCloser(strings.NewReader(""))}, nil
	})}
	a := API{Tokens: testTokens{}, Client: client}
	if err := a.kick(ctx, http.MethodGet, "/channels", nil, nil); !errors.Is(err, context.Canceled) {
		t.Fatal(err)
	}
	if attempts != 1 {
		t.Fatal(attempts)
	}
	if err := a.kick(context.Background(), http.MethodDelete, "/events/subscriptions", nil, nil); err != nil {
		t.Fatal(err)
	}
}

func TestFollowerPermissionDoesNotFailMetadata(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/users":
			fmt.Fprint(w, `{"data":[{"id":"1"}]}`)
		case "/streams":
			fmt.Fprint(w, `{"data":[]}`)
		case "/channels":
			fmt.Fprint(w, `{"data":[{"broadcaster_id":"1"}]}`)
		default:
			w.WriteHeader(403)
		}
	}))
	defer server.Close()
	a := API{Tokens: testTokens{}, Client: server.Client(), TwitchURL: server.URL}
	writes := 0
	if err := a.FetchTwitch(context.Background(), []string{"test"}, func(updates []ChannelUpdate) error { writes += len(updates); return nil }); err != nil {
		t.Fatal(err)
	}
	if writes != 1 {
		t.Fatal(writes)
	}
}

func TestUnchanged(t *testing.T) {
	at := time.Date(2026, 10, 16, 12, 0, 0, 0, time.UTC)
	current := map[string]interface{}{"viewerCount": int64(3), "login": "a", "onlineAt": at, "title": nil, "categoryId": float64(9)}
	for _, tc := range []struct {
		update map[string]interface{}
		want   bool
	}{
		{map[string]interface{}{"viewerCount": int64(3), "login": "a", "onlineAt": at.In(time.FixedZone("x", 3600)), "title": nil}, true},
		{map[string]interface{}{"categoryId": float64(9)}, true},
		{map[string]interface{}{"viewerCount": int64(4)}, false},
		{map[string]interface{}{"viewerCount": float64(3)}, false},
		{map[string]interface{}{"categoryId": int64(9)}, false},
		{map[string]interface{}{"onlineAt": nil}, false},
		{map[string]interface{}{"onlineAt": at.Add(time.Millisecond)}, false},
		{map[string]interface{}{"title": "new"}, false},
		{map[string]interface{}{"followerCount": int64(0)}, false},
		{map[string]interface{}{"language": nil}, false},
	} {
		if got := unchanged(current, tc.update); got != tc.want {
			t.Errorf("unchanged(%v) = %v", tc.update, got)
		}
	}
}
