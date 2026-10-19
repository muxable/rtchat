package youtube

import (
	"errors"
	"io"
	"net/http"
	"strings"
	"sync"
	"testing"
	"time"
)

// offlinePage is the smallest /live page that liveVideoID reads as offline.
const offlinePage = `<html><script>var ytInitialData = {"metadata":{"channelMetadataRenderer":{"title":"channel"}}};</script></html>`

// The discovery_*.html fixtures are real /channel/{id}/live pages fetched on
// 2026-10-14 with desktopUA, trimmed to the head links and the parts of
// ytInitialPlayerResponse and ytInitialData that matter here:
//   - discovery_live.html: Lofi Girl while live, fetched from a residential IP.
//   - discovery_botcheck.html: the same stream fetched from a GitHub Actions
//     runner, which got "Sign in to confirm you're not a bot": the canonical
//     href is "undefined" and the player response has no videoDetails.
//   - discovery_offline.html: Google for Developers while offline, fetched
//     from the same runner.
func TestLiveVideoID(t *testing.T) {
	for _, tc := range []struct{ file, want string }{
		{"discovery_live.html", "1-LpQekNa9g"},
		{"discovery_botcheck.html", "1-LpQekNa9g"},
		{"discovery_offline.html", ""},
	} {
		got, err := liveVideoID(fixture(t, tc.file))
		if err != nil || got != tc.want {
			t.Errorf("%s: got %q, %v; want %q", tc.file, got, err, tc.want)
		}
	}
}

func TestLiveVideoIDFallbacks(t *testing.T) {
	for _, tc := range []struct{ name, page, want string }{
		{"videoDetails without canonical",
			`<script>var ytInitialPlayerResponse = {"videoDetails":{"videoId":"abc_DEF-123"}};</script>`, "abc_DEF-123"},
		{"currentVideoEndpoint without canonical",
			`<link rel="canonical" href="undefined"><script>var ytInitialData = {"currentVideoEndpoint":{"watchEndpoint":{"videoId":"abc_DEF-123"}}};</script>`, "abc_DEF-123"},
		{"window assignment",
			`<script>window["ytInitialData"] = {"currentVideoEndpoint":{"watchEndpoint":{"videoId":"abc_DEF-123"}}};</script>`, "abc_DEF-123"},
		{"channel page",
			`<script>var ytInitialData = {"metadata":{"channelMetadataRenderer":{"title":"x"}}};</script>`, ""},
	} {
		got, err := liveVideoID([]byte(tc.page))
		if err != nil || got != tc.want {
			t.Errorf("%s: got %q, %v; want %q", tc.name, got, err, tc.want)
		}
	}
}

func TestLiveVideoIDUnrecognized(t *testing.T) {
	for name, page := range map[string]string{
		"empty":            ``,
		"plain html":       `<html>offline</html>`,
		"consent":          `<html><title>Before you continue to YouTube</title><form action="https://consent.youtube.com/save"></form></html>`,
		"bad video id":     `<script>var ytInitialData = {"currentVideoEndpoint":{"watchEndpoint":{"videoId":"short"}}};</script>`,
		"truncated json":   `<script>var ytInitialData = {"metadata":{"channelMetadataRenderer":{`,
		"no channel or id": `<script>var ytInitialData = {"contents":{}};</script>`,
		"bot check without ytInitialData": `<link rel="canonical" href="undefined">` +
			`<script>var ytInitialPlayerResponse = {"playabilityStatus":{"status":"LOGIN_REQUIRED","reason":"Sign in to confirm you’re not a bot"}};</script>`,
	} {
		got, err := liveVideoID([]byte(page))
		if got != "" || !errors.As(err, new(*unrecognizedPageError)) {
			t.Errorf("%s: got %q, %v", name, got, err)
		}
	}
	_, err := liveVideoID([]byte(`<title>Before you continue</title><a href="https://consent.youtube.com/">`))
	if err == nil || !strings.Contains(err.Error(), `title "Before you continue"`) || !strings.Contains(err.Error(), "consent true") {
		t.Errorf("description: %v", err)
	}
}

func TestBotCheckPageReadsChat(t *testing.T) {
	watch := fixture(t, "discovery_botcheck.html")
	initial := htmlFixture(t, `var ytInitialData = `)
	var mu sync.Mutex
	var chatVideo string
	server := newTestServer(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/channel/channel/live":
			w.Write(watch)
		case "/live_chat":
			mu.Lock()
			chatVideo = r.URL.Query().Get("v")
			mu.Unlock()
			io.WriteString(w, initial)
		default:
			io.WriteString(w, `{}`)
		}
	}))
	defer server.Close()
	store := &memoryStore{}
	c := testClient(t, server, store)
	c.start()
	defer c.Close()
	eventually(t, func() bool {
		store.mu.Lock()
		defer store.mu.Unlock()
		return len(store.online) > 0
	})
	closeClient(t, c)
	mu.Lock()
	defer mu.Unlock()
	store.mu.Lock()
	defer store.mu.Unlock()
	if chatVideo != "1-LpQekNa9g" || store.online[0] == nil || c.counts.unrecognizedPages.Load() != 0 {
		t.Fatalf("video %q, online %v, unrecognized %d", chatVideo, store.online, c.counts.unrecognizedPages.Load())
	}
}

func TestUnrecognizedPageIsNotOffline(t *testing.T) {
	var mu sync.Mutex
	var times []time.Time
	server := newTestServer(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		times = append(times, time.Now())
		mu.Unlock()
		io.WriteString(w, `<html><title>Before you continue to YouTube</title></html>`)
	}))
	defer server.Close()
	store := &memoryStore{}
	c := testClient(t, server, store)
	c.pollInterval = time.Hour
	c.start()
	defer c.Close()
	eventually(t, func() bool { return c.counts.unrecognizedPages.Load() >= 3 })
	closeClient(t, c)
	if n := c.counts.unrecognizedPages.Load(); n < 3 {
		t.Fatalf("unrecognized pages %d", n)
	}
	store.mu.Lock()
	defer store.mu.Unlock()
	if len(store.online) != 0 {
		t.Fatalf("an unrecognized page changed the channel's state: %v", store.online)
	}
	mu.Lock()
	defer mu.Unlock()
	if times[2].Sub(times[1]) < 20*time.Millisecond {
		t.Fatal("unrecognized pages were not retried with backoff")
	}
}
