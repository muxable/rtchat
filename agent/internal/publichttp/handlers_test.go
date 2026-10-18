package publichttp

import (
	"context"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
)

type fakeStore struct {
	channel string
	data    map[string]any
	err     error
}

func (f *fakeStore) Metadata(_ context.Context, channel string, data map[string]any) error {
	f.channel = channel
	f.data = data
	return f.err
}

type transport func(*http.Request) (*http.Response, error)

func (f transport) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }
func response(code int, body string) *http.Response {
	return &http.Response{StatusCode: code, Body: io.NopCloser(strings.NewReader(body)), Header: http.Header{}}
}
func fixture() (*Server, *fakeStore, *http.ServeMux) {
	store := &fakeStore{}
	s := &Server{Store: store, TwitchClientID: "twitch-client", MetadataClients: map[string]string{}, AppToken: func(context.Context, string) (string, error) { return "app-token", nil }}
	mux := http.NewServeMux()
	s.Register(mux)
	return s, store, mux
}
func TestEmbeds(t *testing.T) {
	for _, provider := range []string{"twitch", "kick"} {
		t.Run(provider, func(t *testing.T) {
			s, _, mux := fixture()
			s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
				if r.Header.Get("Authorization") != "Bearer app-token" {
					t.Fatal("missing provider auth")
				}
				if provider == "twitch" && (r.Header.Get("Client-Id") != "twitch-client" || r.URL.Query().Get("id") != "123") {
					t.Fatal("incorrect twitch lookup")
				}
				if provider == "kick" && r.URL.Query().Get("broadcaster_user_id") != "123" {
					t.Fatal("incorrect kick lookup")
				}
				return response(200, `{"data":[{"login":"streamer","slug":"a/b ?#"}]}`), nil
			})}
			for _, path := range []string{"/embed", "/embedRedirect"} {
				w := httptest.NewRecorder()
				mux.ServeHTTP(w, httptest.NewRequest("GET", path+"?provider="+provider+"&channelId=123", nil))
				location, _ := url.Parse(w.Header().Get("Location"))
				if w.Code != 302 {
					t.Fatal("embed failed")
				}
				if provider == "twitch" && (location.Host != "player.twitch.tv" || location.Query().Get("parent") != "chat.rtirl.com" || location.Query().Get("channel") != "streamer" || location.Query().Get("muted") != "true") {
					t.Fatal("wrong Twitch player arguments")
				}
				if provider == "kick" && (location.Host != "player.kick.com" || location.EscapedPath() != "/a%2Fb%20%3F%23" || location.Query().Get("muted") != "true") {
					t.Fatalf("unsafe slug URL %s", location)
				}
			}
		})
	}
}
func TestEmbedErrors(t *testing.T) {
	for _, query := range []string{"", "provider=twitch", "provider=unknown&channelId=123", "provider=twitch&channelId=123%26id=456"} {
		_, _, mux := fixture()
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, httptest.NewRequest("GET", "/embed?"+query, nil))
		if w.Code != 400 {
			t.Fatalf("%s: %d", query, w.Code)
		}
	}
	s, _, mux := fixture()
	for _, tc := range []struct {
		status int
		body   string
		want   int
	}{{200, `{"data":[]}`, 404}, {503, `secret provider response`, 502}, {200, `invalid JSON`, 502}} {
		s.HTTP = &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) { return response(tc.status, tc.body), nil })}
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, httptest.NewRequest("GET", "/embed?provider=twitch&channelId=123", nil))
		if w.Code != tc.want || strings.Contains(w.Body.String(), "secret") {
			t.Fatalf("lookup failure %d %s", w.Code, w.Body)
		}
	}
	s.AppToken = func(context.Context, string) (string, error) { return "", errors.New("secret") }
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, httptest.NewRequest("GET", "/embed?provider=kick&channelId=123", nil))
	if w.Code != 503 {
		t.Fatal("missing app credentials accepted")
	}
}
func TestMetadataAllowlist(t *testing.T) {
	for _, allowed := range []bool{false, true} {
		s, store, mux := fixture()
		s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
			if r.URL.String() != "https://id.twitch.tv/oauth2/validate" || r.Header.Get("Authorization") != "OAuth user-token" {
				t.Fatal("missing provider validation")
			}
			return response(200, `{"client_id":"client","user_id":"123"}`), nil
		})}
		if allowed {
			s.MetadataClients["client"] = "Reviewed App"
		}
		for _, path := range []string{"/metadata", "/api/metadata"} {
			w := httptest.NewRecorder()
			mux.ServeHTTP(w, httptest.NewRequest("POST", path, strings.NewReader(`{"provider":"twitch","token":"user-token","key":"speed","value":0}`)))
			if allowed {
				if w.Code != 204 || store.channel != "twitch:123" || store.data["name"] != "Reviewed App" || store.data["clientId"] != "client" || store.data["key"] != "speed" || store.data["value"] != float64(0) {
					t.Fatalf("metadata schema %d %+v", w.Code, store)
				}
			} else if w.Code != 403 || store.data != nil {
				t.Fatal("unregistered app allowed")
			}
		}
	}
}
func TestMetadataInvalidToken(t *testing.T) {
	for _, tc := range []struct {
		status int
		body   string
	}{{401, `{"client_id":"client","user_id":"123"}`}, {200, `{"client_id":"client"}`}, {200, `invalid`}} {
		s, store, mux := fixture()
		s.MetadataClients["client"] = "App"
		s.HTTP = &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) { return response(tc.status, tc.body), nil })}
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, httptest.NewRequest("POST", "/metadata", strings.NewReader(`{"provider":"twitch","token":"token","key":"k","value":"v"}`)))
		if w.Code != 401 || store.data != nil {
			t.Fatal("invalid token authorized")
		}
	}
}
func TestMethodsAndInvalidMetadata(t *testing.T) {
	_, _, mux := fixture()
	for _, path := range []string{"/embed", "/embedRedirect", "/metadata", "/api/metadata"} {
		method := "POST"
		if strings.Contains(path, "metadata") {
			method = "GET"
		}
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, httptest.NewRequest(method, path, nil))
		if w.Code != 405 {
			t.Fatalf("%s wrong method %d", path, w.Code)
		}
	}
	for _, body := range []string{`{`, `{}`, `{"provider":"kick","token":"t","key":"k","value":"v"}`, `{"provider":"twitch","token":"t","key":"k"}`, `{"provider":"twitch","token":"t","key":"k","value":"` + strings.Repeat("x", 64<<10) + `"}`} {
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, httptest.NewRequest("POST", "/metadata", strings.NewReader(body)))
		if w.Code != 400 {
			t.Fatalf("invalid metadata status %d", w.Code)
		}
	}
}
func TestMetadataClientConfig(t *testing.T) {
	for _, raw := range []string{`null`, `[]`, `{"id":123}`, `{"":"name"}`, `{"id":""}`, `broken`} {
		if _, err := ParseMetadataClients(raw); err == nil {
			t.Fatalf("accepted %q", raw)
		}
	}
	for _, raw := range []string{"", `{}`, `{"id":"Reviewed"}`} {
		if _, err := ParseMetadataClients(raw); err != nil {
			t.Fatal(err)
		}
	}
}

func TestYouTubeEmbed(t *testing.T) {
	s, _, mux := fixture()
	s.AppToken = nil // YouTube embeds need no provider credentials or HTTP calls.
	for _, path := range []string{"/embed", "/embedRedirect"} {
		for _, id := range []string{"UCabcdefghijklmnopqr12_-", "@creator", "UCabcdefghijklmnopqr12_-&x=1", ""} {
			w := httptest.NewRecorder()
			mux.ServeHTTP(w, httptest.NewRequest("GET", path+"?provider=youtube&channelId="+url.QueryEscape(id), nil))
			if id == "UCabcdefghijklmnopqr12_-" {
				want := "https://www.youtube.com/embed/live_stream?channel=" + id + "&autoplay=1&mute=1"
				if w.Code != 302 || w.Header().Get("Location") != want {
					t.Fatalf("%s: %d %s", path, w.Code, w.Header().Get("Location"))
				}
			} else if w.Code != 404 {
				t.Fatalf("accepted invalid YouTube channel %q: %d", id, w.Code)
			}
		}
	}
}
