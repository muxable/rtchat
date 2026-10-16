package catalog

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"sync"
	"testing"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/provider"
)

type fakeTokens struct {
	user map[string]string
	app  map[string]string
}

func (f *fakeTokens) AccessToken(_ context.Context, uid, p string) (string, error) {
	if token := f.user[uid+":"+p]; token != "" {
		return token, nil
	}
	return "", provider.ErrNoToken
}
func (f *fakeTokens) AppAccessToken(_ context.Context, p string) (string, error) {
	if token := f.app[p]; token != "" {
		return token, nil
	}
	return "", provider.ErrNoToken
}

type fakeStore struct {
	mu          sync.Mutex
	profiles    map[string]map[string]any
	owner       string
	cached      map[string][]map[string]any
	cacheError  bool
	cacheWrites int
}

func (f *fakeStore) Profile(_ context.Context, uid, p string) (map[string]any, error) {
	return f.profiles[uid+":"+p], nil
}
func (f *fakeStore) BroadcasterUID(context.Context, string) (string, error) { return f.owner, nil }
func (f *fakeStore) CachedYouTube(_ context.Context, key string) ([]map[string]any, bool, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.cacheError {
		return nil, false, errors.New("cache unavailable")
	}
	v, ok := f.cached[key]
	return v, ok, nil
}
func (f *fakeStore) CacheYouTube(_ context.Context, key string, v []map[string]any) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.cacheWrites++
	if f.cacheError {
		return errors.New("cache unavailable")
	}
	f.cached[key] = v
	return nil
}

type transport func(*http.Request) (*http.Response, error)

func (f transport) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }
func response(code int, body string) *http.Response {
	return &http.Response{StatusCode: code, Body: io.NopCloser(strings.NewReader(body)), Header: http.Header{}}
}
func fixture() (*Server, *fakeStore, *fakeTokens) {
	store := &fakeStore{profiles: map[string]map[string]any{}, cached: map[string][]map[string]any{}}
	tokens := &fakeTokens{user: map[string]string{}, app: map[string]string{"twitch": "twitch-app", "kick": "kick-app"}}
	s := &Server{Store: store, Tokens: tokens, TwitchClientID: "client", YouTubeAPIKey: func(context.Context) (string, error) { return "api-key", nil }}
	return s, store, tokens
}
func invoke(t *testing.T, s *Server, name, body, uid string) (int, map[string]any) {
	t.Helper()
	api := callable.NewServer(func(_ context.Context, token string) (string, error) {
		if token == "firebase-id-token" {
			return uid, nil
		}
		return "", errors.New("invalid")
	})
	s.Register(api)
	r := httptest.NewRequest("POST", "/"+name, strings.NewReader(`{"data":`+body+`}`))
	r.Header.Set("Content-Type", "application/json")
	if uid != "" {
		r.Header.Set("Authorization", "Bearer firebase-id-token")
	}
	w := httptest.NewRecorder()
	api.ServeHTTP(w, r)
	var result map[string]any
	if json.Unmarshal(w.Body.Bytes(), &result) != nil {
		t.Fatalf("invalid response: %s", w.Body)
	}
	return w.Code, result
}
func TestYouTubeLookupGrammarAndCache(t *testing.T) {
	for _, query := range []string{"@Some.Creator", "Some.Creator", "https://www.youtube.com/@Some.Creator", "youtube.com/@Some.Creator/", "https://m.youtube.com/%40Some.Creator?view=1#about"} {
		l, ok := parseYouTube(query)
		if !ok || l.Handle != "some.creator" {
			t.Fatalf("%s: %+v", query, l)
		}
	}
	id := "UCabcdefghijklmnopqr12_-"
	for _, q := range []string{id, "https://youtube.com/channel/" + id} {
		l, ok := parseYouTube(q)
		if !ok || l.ID != id {
			t.Fatalf("invalid ID %s", q)
		}
	}
	for _, q := range []string{"", "@", "two words", "some/name", "@bad!", "https://example.com/@creator", "https://youtube.com.evil.com/@creator", "https://youtube.com/watch?v=123", "https://youtube.com/channel/UCshort", "https://youtube.com/@creator/extra", "https://youtube.com/@%ZZ", "https://youtube.com/@creator%2Fextra"} {
		if _, ok := parseYouTube(q); ok {
			t.Fatalf("accepted %s", q)
		}
	}
	s, store, _ := fixture()
	requests := 0
	s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		requests++
		if r.URL.Path != "/youtube/v3/channels" || r.URL.Query().Get("forHandle") != "@some.creator" || r.URL.Query().Get("key") != "api-key" {
			t.Fatal("quota-expensive or incorrect lookup")
		}
		return response(200, `{"items":[{"id":"`+id+`","snippet":{"title":"Creator","customUrl":"@Some.Creator","thumbnails":{"default":{"url":"https://image"}}}}]}`), nil
	})}
	for i := 0; i < 2; i++ {
		status, result := invoke(t, s, "search", `{"provider":"youtube","query":"https://youtube.com/@Some.Creator"}`, "")
		item := first(result["result"])
		if status != 200 || item["login"] != "some.creator" || item["channelId"] != id || item["isOnline"] != false {
			t.Fatal(result)
		}
	}
	if requests != 1 || store.cacheWrites != 1 {
		t.Fatal("cache missed")
	}
	store.cached = map[string][]map[string]any{}
	s.HTTP = &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) { requests++; return response(200, `{"items":[]}`), nil })}
	for i := 0; i < 2; i++ {
		_, result := invoke(t, s, "search", `{"provider":"youtube","query":"notfound"}`, "")
		if len(array(result["result"])) != 0 {
			t.Fatal(result)
		}
	}
	if requests != 2 {
		t.Fatal("misses not cached")
	}
	store.cacheError = true
	s.HTTP = &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) { return response(503, `private`), nil })}
	status, result := invoke(t, s, "search", `{"provider":"youtube","query":"creator"}`, "")
	if status != 200 || len(array(result["result"])) != 0 {
		t.Fatal("best-effort YouTube failure")
	}
}

// CLI covers normal authorization and role grouping; these stubs exercise
// pagination and denied-broadcaster/role-query fallback, which its dataset cannot force.
func TestViewerPaginationAndDeniedBroadcasterFallback(t *testing.T) {
	s, store, tokens := fixture()
	store.owner = "broadcaster"
	store.profiles["broadcaster:twitch"] = map[string]any{"id": "100"}
	store.profiles["viewer:twitch"] = map[string]any{"id": "200"}
	tokens.user["broadcaster:twitch"] = "broadcaster-token"
	tokens.user["viewer:twitch"] = "viewer-token"
	s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		switch r.URL.Path {
		case "/helix/chat/chatters":
			token := r.Header.Get("Authorization")
			if token == "Bearer broadcaster-token" {
				return response(403, `denied`), nil
			}
			expected := "100"
			if token == "Bearer viewer-token" {
				expected = "200"
			}
			if r.URL.Query().Get("moderator_id") != expected {
				t.Fatal("moderator ID does not match token subject")
			}
			if r.URL.Query().Get("after") == "next" {
				return response(200, `{"data":[{"user_id":"5","user_name":"Zulu","user_login":"zulu"}],"pagination":{}}`), nil
			}
			return response(200, `{"data":[{"user_id":"100","user_name":"Owner","user_login":"owner"},{"user_id":"4","user_name":"Alpha","user_login":"alpha"}],"pagination":{"cursor":"next"}}`), nil
		case "/helix/moderation/moderators", "/helix/channels/vips":
			return response(403, `denied`), nil
		}
		t.Fatalf("unexpected %s", r.URL)
		return nil, nil
	})}
	status, result := invoke(t, s, "getViewerList", `"twitch:100"`, "viewer")
	groups := object(result["result"])
	if status != 200 || len(array(groups["moderatorsData"])) != 0 || len(array(groups["viewersData"])) != 2 || !reflect.DeepEqual(groups["viewers"], []any{"Alpha", "Zulu"}) {
		t.Fatalf("fallback failed %+v", result)
	}
	delete(tokens.user, "viewer:twitch")
	status, _ = invoke(t, s, "getViewerList", `"twitch:100"`, "viewer")
	if status != 403 {
		t.Fatal("missing caller authorization accepted")
	}
}
func TestCatalogInvalidInputsAndProviderErrors(t *testing.T) {
	s, _, _ := fixture()
	for _, tc := range []struct{ name, body string }{{"search", `null`}, {"search", `{"provider":"unknown","query":"q"}`}, {"getEmotes", `{}`}, {"getEmotes", `{"provider":"twitch","channelId":"x&fake=1"}`}, {"getBadges", `{}`}, {"getStatistics", `{"provider":"youtube","channelId":"123"}`}, {"getViewerList", `"twitch:123:extra"`}} {
		status, _ := invoke(t, s, tc.name, tc.body, "viewer")
		if status != 400 {
			t.Fatalf("%s %s -> %d", tc.name, tc.body, status)
		}
	}
	s.HTTP = &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) { return response(500, `SECRET ACCESS TOKEN`), nil })}
	status, result := invoke(t, s, "search", `{"provider":"twitch","query":"q"}`, "")
	if status != 503 || strings.Contains(text(object(result["error"])["message"]), "SECRET") {
		t.Fatal("provider error leaked")
	}
	for _, name := range []string{"getEmotes", "getBadges"} {
		status, result := invoke(t, s, name, `{"provider":"kick","channelId":"123"}`, "")
		if status != 200 || len(array(result["result"])) != 0 {
			t.Fatal("unsupported provider fallback changed")
		}
	}
}
