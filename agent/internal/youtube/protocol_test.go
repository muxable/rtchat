package youtube

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"
)

func fixture(t *testing.T, name string) []byte {
	t.Helper()
	b, err := os.ReadFile("testdata/" + name)
	if err != nil {
		t.Fatal(err)
	}
	return b
}
func htmlFixture(t *testing.T, assignment string) string {
	return `<html><script>ytcfg.set({"INNERTUBE_API_KEY":"public-key","INNERTUBE_CLIENT_VERSION":"test-version"});` + assignment + string(fixture(t, "innertube_initial.json")) + `;</script></html>`
}
func TestInitialPage(t *testing.T) {
	for _, assignment := range []string{`window["ytInitialData"] = `, `var ytInitialData = `, `window [ 'ytInitialData' ] = `} {
		page, key, version, err := initialPage([]byte(htmlFixture(t, assignment)))
		if err != nil {
			t.Fatal(err)
		}
		token, delay := page.next()
		if key != "public-key" || version != "test-version" || token == "" || delay != 10*time.Second || len(page.Actions) == 0 {
			t.Fatalf("incorrect page: %+v", page)
		}
	}
	for _, html := range []string{`<html>consent</html>`, `"INNERTUBE_API_KEY":"key","INNERTUBE_CLIENT_VERSION":"version";var ytInitialData = {bad}`, `"INNERTUBE_API_KEY":"key","INNERTUBE_CLIENT_VERSION":"version";var ytInitialData = {};`} {
		if _, _, _, err := initialPage([]byte(html)); err == nil {
			t.Fatal("accepted invalid HTML")
		}
	}
}
func TestContinuations(t *testing.T) {
	for _, kind := range []string{"invalidationContinuationData", "timedContinuationData", "reloadContinuationData"} {
		var page chatPage
		if err := json.Unmarshal([]byte(`{"continuations":[{"`+kind+`":{"continuation":"token","timeoutMs":1234}}]}`), &page); err != nil {
			t.Fatal(err)
		}
		token, delay := page.next()
		if token != "token" || delay != 1234*time.Millisecond {
			t.Fatal(token, delay)
		}
	}
}
func TestHTTPProtocol(t *testing.T) {
	initial := htmlFixture(t, `window["ytInitialData"] = `)
	followup := fixture(t, "innertube_get_live_chat.json")
	server := newTestServer(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("User-Agent") != desktopUA {
			t.Error("missing desktop UA")
		}
		switch r.URL.Path {
		case "/channel/channel/live":
			io.WriteString(w, `<link href="https://www.youtube.com/watch?v=abcdefghijk" rel="canonical">`)
		case "/live_chat":
			if r.URL.Query().Get("v") != "abcdefghijk" || r.URL.Query().Get("is_popout") != "1" {
				t.Error("bad initial query")
			}
			io.WriteString(w, initial)
		case "/youtubei/v1/live_chat/get_live_chat":
			if r.Method != "POST" || r.URL.Query().Get("key") != "public-key" || r.URL.Query().Get("prettyPrint") != "false" || r.Header.Get("Content-Type") != "application/json" {
				t.Error("bad poll request")
			}
			var body interface{}
			if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
				t.Error(err)
			}
			assertJSON(t, body, `{"context":{"client":{"clientName":"WEB","clientVersion":"test-version"}},"continuation":"token"}`)
			w.Write(followup)
		default:
			t.Error(r.URL.Path)
			http.NotFound(w, r)
		}
	}))
	defer server.Close()
	discovery := &HTTPDiscovery{HTTP: server.Client(), BaseURL: server.URL}
	video, err := discovery.LiveChat(context.Background(), "channel")
	if err != nil || video != "abcdefghijk" {
		t.Fatal(video, err)
	}
	c, _ := newClient("channel", server.Client(), nil)
	c.baseURL = server.URL
	page, key, version, err := c.initial(context.Background(), video)
	if err != nil || len(page.Actions) == 0 {
		t.Fatal(err)
	}
	page, err = c.poll(context.Background(), key, version, "token")
	if err != nil {
		t.Fatal(err)
	}
	token, delay := page.next()
	if token == "" || delay != 10*time.Second {
		t.Fatal(token, delay)
	}
	if c.counts.requests.Load() != 2 {
		t.Fatal("request counter")
	}
}
func TestCanonicalVideo(t *testing.T) {
	for _, tc := range []struct{ html, want string }{
		{`<link rel="canonical" href="https://www.youtube.com/watch?v=abcdefghijk">`, "abcdefghijk"},
		{`<link href='https://www.youtube.com/watch?v=abc_DEF-123&amp;x=1' rel='canonical'>`, "abc_DEF-123"},
		{`<link rel="canonical" href="https://www.youtube.com/channel/UCfoo">`, ""},
		{`<link rel="canonical" href="https://evil.example/watch?v=abcdefghijk">`, ""},
		{`<link rel="canonical" href="https://www.youtube.com/watch?v=short">`, ""},
		{`<html>offline</html>`, ""},
	} {
		got, err := canonicalVideoID(strings.NewReader(tc.html))
		if err != nil || got != tc.want {
			t.Fatal(got, err)
		}
	}
}
