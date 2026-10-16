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
func TestSearchLegacyExactOrderingAndFallback(t *testing.T) {
	s, _, _ := fixture()
	kickFails := false
	s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		switch r.URL.Path {
		case "/helix/search/channels":
			if r.Header.Get("Authorization") != "Bearer twitch-app" || r.Header.Get("Client-Id") != "client" {
				t.Fatal("wrong Twitch app credentials")
			}
			return response(200, `{"data":[{"id":"1","broadcaster_login":"fuzzy","display_name":"Fuzzy","is_live":true},{"id":"2","broadcaster_login":"EXACT","display_name":"Exact","is_live":false}]}`), nil
		case "/public/v1/channels":
			if kickFails {
				return response(500, `secret`), nil
			}
			return response(200, `{"data":[{"broadcaster_user_id":1234567,"slug":"exact","stream":{"is_live":true,"viewer_count":4,"language":"en"},"category":{"name":"IRL"},"stream_title":"Title"}]}`), nil
		case "/public/v1/users":
			return response(503, `private`), nil
		default:
			t.Fatalf("unexpected endpoint %s", r.URL)
			return nil, nil
		}
	})}
	status, result := invoke(t, s, "search", `"exact"`, "")
	if status != 200 {
		t.Fatal(result)
	}
	items := array(result["result"])
	if len(items) != 3 || items[0]["login"] != "EXACT" || items[1]["provider"] != "kick" || items[2]["login"] != "fuzzy" {
		t.Fatalf("ordering %+v", items)
	}
	kick := items[1]
	if kick["channelId"] != "1234567" || kick["displayName"] != "exact" || kick["viewerCount"] != float64(4) || kick["imageUrl"] != "https://rtirl.com/pfp.png?provider=kick&channelId=1234567" {
		t.Fatalf("Kick fallback schema %+v", kick)
	}
	kickFails = true
	status, result = invoke(t, s, "search", `"exact"`, "")
	if status != 200 || len(array(result["result"])) != 2 {
		t.Fatal("Kick failure dropped Twitch results")
	}
}
func TestSearchFollowedAndMissingTokenFallback(t *testing.T) {
	s, store, tokens := fixture()
	tokens.user["uid:twitch"] = "user-token"
	store.profiles["uid:twitch"] = map[string]any{"id": "123"}
	followed := 0
	search := 0
	s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		if r.URL.Path == "/helix/streams/followed" {
			followed++
			if r.Header.Get("Authorization") != "Bearer user-token" || r.URL.Query().Get("user_id") != "123" {
				t.Fatal("followed used app token")
			}
			return response(200, `{"data":[{"user_id":"9","user_login":"followed","user_name":"Followed","type":"live","viewer_count":42,"language":"en","game_name":"IRL","title":"Title"}]}`), nil
		}
		search++
		return response(200, `{"data":[]}`), nil
	})}
	status, result := invoke(t, s, "search", `{"provider":"twitch","query":""}`, "uid")
	item := first(result["result"])
	if status != 200 || item["viewerCount"] != float64(42) || item["imageUrl"] != "https://rtirl.com/pfp.png?provider=twitch&channelId=9" || followed != 1 || search != 0 {
		t.Fatal(result)
	}
	delete(tokens.user, "uid:twitch")
	status, _ = invoke(t, s, "search", `{"provider":"twitch","query":""}`, "uid")
	if status != 200 || search != 1 {
		t.Fatal("missing user token did not fall back")
	}
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
func TestBadgesAndStatisticsSchemas(t *testing.T) {
	s, _, _ := fixture()
	online := false
	s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		if r.Header.Get("Authorization") != "Bearer twitch-app" {
			t.Fatal("public read did not use app credentials")
		}
		switch r.URL.Path {
		case "/helix/chat/badges/global", "/helix/chat/badges":
			return response(200, `{"data":[{"set_id":"subscriber","versions":[{"id":"1","image_url_1x":"one","image_url_2x":"two","image_url_4x":"four","title":"Subscriber","description":"desc","click_action":"visit_url","click_url":"https://twitch.tv"}]}]}`), nil
		case "/helix/streams":
			if online {
				return response(200, `{"data":[{"viewer_count":12}]}`), nil
			}
			return response(200, `{"data":[]}`), nil
		case "/helix/channels/followers":
			return response(200, `{"total":99,"data":[]}`), nil
		case "/helix/channels":
			return response(200, `{"data":[{"broadcaster_language":"en"}]}`), nil
		}
		t.Fatalf("unexpected %s", r.URL)
		return nil, nil
	})}
	for _, body := range []string{`{"provider":"twitch"}`, `{"provider":"twitch","channelId":"123"}`} {
		status, result := invoke(t, s, "getBadges", body, "")
		badge := first(result["result"])
		version := first(badge["versions"])
		if status != 200 || badge["set_id"] != "subscriber" || version["click_url"] != "https://twitch.tv" || version["image_url_4x"] != "four" {
			t.Fatal(result)
		}
	}
	for _, isOnline := range []bool{false, true} {
		online = isOnline
		status, result := invoke(t, s, "getStatistics", `{"provider":"twitch","channelId":"123"}`, "")
		stats := object(result["result"])
		want := float64(0)
		if online {
			want = 12
		}
		if status != 200 || stats["isOnline"] != online || stats["viewers"] != want || stats["followers"] != float64(99) || stats["language"] != "en" {
			t.Fatal(result)
		}
	}
}
func TestViewerAuthorizationPaginationRolesAndFallback(t *testing.T) {
	s, store, tokens := fixture()
	store.owner = "broadcaster"
	store.profiles["broadcaster:twitch"] = map[string]any{"id": "100"}
	store.profiles["viewer:twitch"] = map[string]any{"id": "200"}
	tokens.user["broadcaster:twitch"] = "broadcaster-token"
	tokens.user["viewer:twitch"] = "viewer-token"
	ownerDenied := false
	requests := 0
	s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		requests++
		switch r.URL.Path {
		case "/helix/chat/chatters":
			token := r.Header.Get("Authorization")
			if ownerDenied && token == "Bearer broadcaster-token" {
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
			return response(200, `{"data":[{"user_id":"100","user_name":"Owner","user_login":"owner"},{"user_id":"2","user_name":"Mod","user_login":"mod"},{"user_id":"3","user_name":"VIP","user_login":"vip"},{"user_id":"4","user_name":"Alpha","user_login":"alpha"}],"pagination":{"cursor":"next"}}`), nil
		case "/helix/moderation/moderators":
			if ownerDenied {
				return response(403, `denied`), nil
			}
			return response(200, `{"data":[{"user_id":"2","user_name":"Mod","user_login":"mod"}]}`), nil
		case "/helix/channels/vips":
			if ownerDenied {
				return response(403, `denied`), nil
			}
			return response(200, `{"data":[{"user_id":"3","user_name":"VIP","user_login":"vip"}]}`), nil
		}
		t.Fatalf("unexpected %s", r.URL)
		return nil, nil
	})}
	status, _ := invoke(t, s, "getViewerList", `"twitch:100"`, "")
	if status != 401 || requests != 0 {
		t.Fatal("unauthenticated viewer request reached Twitch")
	}
	status, result := invoke(t, s, "getViewerList", `"twitch:100"`, "viewer")
	groups := object(result["result"])
	if status != 200 || !reflect.DeepEqual(groups["viewers"], []any{"Alpha", "Zulu"}) || !reflect.DeepEqual(groups["moderators"], []any{"Mod"}) || len(array(groups["viewersData"])) != 2 {
		t.Fatal(result)
	}
	ownerDenied = true
	status, result = invoke(t, s, "getViewerList", `"twitch:100"`, "viewer")
	groups = object(result["result"])
	if status != 200 || len(array(groups["moderatorsData"])) != 0 || len(array(groups["viewersData"])) != 4 {
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
