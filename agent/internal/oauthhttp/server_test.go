package oauthhttp

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"sync"
	"testing"
	"time"
)

type fakeStore struct {
	mu        sync.Mutex
	sessions  map[string]Session
	signIns   int
	links     int
	companion string
	metadata  map[string]any
	allow     bool
}

func (f *fakeStore) SaveSession(_ context.Context, id string, s Session) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.sessions[id] = s
	return nil
}
func (f *fakeStore) ConsumeSession(_ context.Context, id, p, state string) (Session, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	s, ok := f.sessions[id]
	if !ok || state == "" || s.State != state || s.Provider != p || time.Now().After(s.Expires) {
		return Session{}, errors.New("invalid session")
	}
	delete(f.sessions, id)
	return s, nil
}
func (f *fakeStore) Allow(context.Context, string) (bool, error) { return f.allow, nil }
func (f *fakeStore) SignIn(_ context.Context, _ string, _ map[string]any, _ map[string]any, c string) (string, error) {
	f.signIns++
	f.companion = c
	return "custom-token", nil
}
func (f *fakeStore) Verify(_ context.Context, token string) (string, error) {
	if token != "firebase-token" {
		return "", errors.New("invalid token")
	}
	return "uid", nil
}
func (f *fakeStore) Link(_ context.Context, uid, provider, linked string, token map[string]any) error {
	f.links++
	if uid != "uid" || linked != "twitch" {
		return errors.New("bad account")
	}
	return nil
}
func (f *fakeStore) Metadata(_ context.Context, _ string, data map[string]any) error {
	f.metadata = data
	return nil
}

type transport func(*http.Request) (*http.Response, error)

func (f transport) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }
func fixture() (*Server, *fakeStore) {
	f := &fakeStore{sessions: map[string]Session{}, allow: true}
	s := &Server{Store: f, SessionKey: []byte(strings.Repeat("s", 32)), CallbackOrigin: "https://rtchat-api.rtirl.com", Providers: map[string]Provider{}}
	for _, p := range []string{"twitch", "kick", "youtube", "streamlabs", "streamelements"} {
		s.Providers[p] = Provider{ClientID: "client", ClientSecret: "secret", AuthorizeURL: "https://provider.test/authorize", TokenURL: "https://provider.test/token"}
	}
	return s, f
}
func request(path string) *http.Request {
	return httptest.NewRequest("GET", "https://rtchat-api.rtirl.com"+path, nil)
}
func begin(t *testing.T, s *Server, provider, query string) (*http.Cookie, url.Values) {
	t.Helper()
	w := httptest.NewRecorder()
	s.ServeHTTP(w, request("/auth/"+provider+"/redirect?"+query))
	if w.Code != 302 {
		t.Fatalf("redirect: %d %s", w.Code, w.Body)
	}
	location, _ := url.Parse(w.Header().Get("Location"))
	return w.Result().Cookies()[0], location.Query()
}
func TestStatePKCEAndCompanionAcrossReplicas(t *testing.T) {
	s, f := fixture()
	cookie, q := begin(t, s, "kick", "companion=desktop-123")
	var exchanged bool
	s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		body := `{"data":[{"user_id":12,"name":"Streamer","slug":"streamer"}]}`
		if r.Method == "POST" {
			r.ParseForm()
			verifier := r.Form.Get("code_verifier")
			hash := sha256.Sum256([]byte(verifier))
			if verifier == "" || q.Get("code_challenge") != base64.RawURLEncoding.EncodeToString(hash[:]) {
				t.Fatal("PKCE mismatch")
			}
			if r.Form.Get("redirect_uri") != "https://rtchat-api.rtirl.com/auth/kick/callback" {
				t.Fatal("wrong callback")
			}
			exchanged = true
			body = `{"access_token":"access","refresh_token":"refresh","expires_in":3600}`
		}
		return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(body)), Header: http.Header{}}, nil
	})}
	replica := *s
	bad := request("/auth/kick/callback?code=code&state=wrong")
	bad.AddCookie(cookie)
	w := httptest.NewRecorder()
	replica.ServeHTTP(w, bad)
	if w.Code != 400 || exchanged {
		t.Fatal("state mismatch accepted")
	}
	callback := func() *httptest.ResponseRecorder {
		r := request("/auth/kick/callback?code=code&state=" + q.Get("state"))
		r.AddCookie(cookie)
		w := httptest.NewRecorder()
		replica.ServeHTTP(w, r)
		return w
	}
	w = callback()
	if w.Code != 200 || !exchanged || f.signIns != 1 || f.companion != "desktop-123" {
		t.Fatalf("handoff failed: %d %s", w.Code, w.Body)
	}
	if callback().Code != 400 || f.signIns != 1 {
		t.Fatal("replay accepted")
	}
	if !cookie.Secure || !cookie.HttpOnly || cookie.SameSite != http.SameSiteLaxMode {
		t.Fatal("unsafe cookie")
	}
}
func TestEveryProviderRequiresState(t *testing.T) {
	for _, p := range []string{"twitch", "kick", "youtube", "streamlabs", "streamelements"} {
		t.Run(p, func(t *testing.T) {
			s, _ := fixture()
			query := ""
			if strings.HasPrefix(p, "stream") {
				query = "token=firebase-token&provider=twitch"
			}
			cookie, q := begin(t, s, p, query)
			if q.Get("state") == "" {
				t.Fatal("missing state")
			}
			r := request("/auth/" + p + "/callback?code=x")
			r.AddCookie(cookie)
			w := httptest.NewRecorder()
			s.ServeHTTP(w, r)
			if w.Code != 400 {
				t.Fatal("missing state accepted")
			}
		})
	}
}
func TestLinkingAndDeepLink(t *testing.T) {
	for _, p := range []string{"twitch", "youtube", "streamlabs", "streamelements"} {
		t.Run(p, func(t *testing.T) {
			s, f := fixture()
			s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
				body := `{"access_token":"access","expires_in":3600}`
				if r.Method == "GET" {
					body = `{"data":[{"id":"123","display_name":"Name","login":"name"}],"items":[{"id":"UC123","snippet":{"title":"Name"}}]}`
				}
				return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(body)), Header: http.Header{}}, nil
			})}
			cookie, q := begin(t, s, p, "token=firebase-token&provider=twitch")
			r := request("/auth/" + p + "/callback?code=ok&state=" + q.Get("state"))
			r.AddCookie(cookie)
			w := httptest.NewRecorder()
			s.ServeHTTP(w, r)
			want := "com.rtirl.chat://success?token=custom-token"
			if strings.HasPrefix(p, "stream") {
				want = "com.rtirl.chat://success?token=1"
				if f.links != 1 {
					t.Fatal("account not linked")
				}
			}
			if w.Header().Get("Location") != want {
				t.Fatalf("%d %s", w.Code, w.Body)
			}
		})
	}
}
func TestCanonicalHostBeforeCookie(t *testing.T) {
	s, f := fixture()
	r := httptest.NewRequest("GET", "https://chat.rtirl.com/auth/twitch/redirect?companion=x", nil)
	w := httptest.NewRecorder()
	s.ServeHTTP(w, r)
	if w.Header().Get("Location") != "https://rtchat-api.rtirl.com/auth/twitch/redirect?companion=x" || len(f.sessions) != 0 || len(w.Result().Cookies()) != 0 {
		t.Fatal("session created on incorrect hostname")
	}
}
func TestProxyDoesNotTrustUserHeaders(t *testing.T) {
	s, _ := fixture()
	_, network, _ := net.ParseCIDR("35.191.0.0/16")
	s.TrustedProxies = []*net.IPNet{network}
	r := request("/")
	r.RemoteAddr = "192.0.2.1:123"
	r.Header.Set("X-Forwarded-For", "1.1.1.1, 2.2.2.2")
	if s.peer(r) != "192.0.2.1" {
		t.Fatal("trusted spoofed forwarded header")
	}
	r.RemoteAddr = "35.191.0.1:123"
	r.Header.Set("X-Forwarded-For", "spoofed, 192.0.2.2, 34.1.2.3")
	if s.peer(r) != "192.0.2.2" {
		t.Fatal("incorrect trusted GFE client")
	}
}
func TestProviderExchangePreservesRefresh(t *testing.T) {
	s, _ := fixture()
	s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(`{"access_token":"a","refresh_token":"rotated","expires_in":3600}`)), Header: http.Header{}}, nil
	})}
	token, err := s.exchange(context.Background(), s.Providers["kick"], url.Values{})
	if err != nil || token["refresh_token"] != "rotated" || token["expires_at"] == nil {
		t.Fatal("incompatible token schema")
	}
	if _, err := json.Marshal(token); err != nil {
		t.Fatal(err)
	}
}

func TestKickProfilePreservesNumericIdentity(t *testing.T) {
	s, _ := fixture()
	s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		body := `{"data":[{"user_id":87654321,"name":"Broadcaster"}]}`
		if strings.HasSuffix(r.URL.Path, "/channels") {
			body = `{"data":[{"slug":"broadcaster"}]}`
		}
		return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(body)), Header: http.Header{}}, nil
	})}
	profile, err := s.profile(context.Background(), "kick", "", "token")
	if err != nil || profile["id"] != "87654321" {
		t.Fatalf("unstable Kick account identity: %v, %v", profile, err)
	}
}
