//go:build live

package youtube

import (
	"bytes"
	"context"
	"net/http"
	"net/url"
	"testing"
	"time"
)

// liveCandidates stream around the clock with chat enabled. The live tests
// use the first one that is live, so one channel going offline is not a
// failure.
var liveCandidates = []struct{ name, id string }{
	{"Lofi Girl", "UCSJ4gkVC6NrvII8umztf0Ow"},
	{"Chillhop Music", "UCOxqgCwgOqC2lMqC5PYz_Dg"},
	{"Al Jazeera English", "UCNye-wNBqNL5ZzHSJj3l8Bg"},
	{"ABC News", "UCBi2mrWuNuyYy4gbM6fU18Q"},
}

// liveStream is a live video found through the same requests the reader makes.
type liveStream struct {
	name, channel, video, key, version string
	// watch is the /channel/{id}/live page, which is the watch page while live.
	watch []byte
	page  chatPage
}

func liveHTTPClient() *http.Client { return &http.Client{Timeout: 30 * time.Second} }

// findLiveStream returns the first candidate whose /live page names a video
// and whose live_chat page parses. It skips only if no candidate is live. If
// some are live but none can be read, it fails: a /live page that is live
// without a canonical video, or a chat page we cannot parse, is YouTube
// changing its format (or a stream with chat turned off, hence the fallbacks).
func findLiveStream(t *testing.T) liveStream {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	failed := false
	for _, candidate := range liveCandidates {
		c, err := newClient(candidate.id, liveHTTPClient(), &memoryStore{})
		if err != nil {
			t.Fatal(err)
		}
		body, err := c.request(ctx, http.MethodGet, "/channel/"+url.PathEscape(candidate.id)+"/live", nil)
		if err != nil {
			t.Logf("%s: /live: %v", candidate.name, err)
			continue
		}
		video, err := canonicalVideoID(bytes.NewReader(body))
		if err != nil || video == "" {
			if bytes.Contains(body, []byte(`"isLiveNow":true`)) {
				t.Logf("%s: /live page is live but has no canonical video (err %v)", candidate.name, err)
				failed = true
			} else {
				t.Logf("%s: not live", candidate.name)
			}
			continue
		}
		page, key, version, err := c.initial(ctx, video)
		if err != nil {
			t.Logf("%s: live_chat page for %s: %v", candidate.name, video, err)
			failed = true
			continue
		}
		if token, _ := page.next(); token == "" {
			t.Logf("%s: live_chat page for %s has no continuation", candidate.name, video)
			failed = true
			continue
		}
		t.Logf("using %s (%s), video %s, client version %s", candidate.name, candidate.id, video, version)
		return liveStream{name: candidate.name, channel: candidate.id, video: video, key: key, version: version, watch: body, page: page}
	}
	if failed {
		t.Fatal("candidates are live, but none of them could be read")
	}
	t.Skip("none of the candidate channels is live")
	return liveStream{}
}
