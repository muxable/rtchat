package youtube

import (
	"bytes"
	"context"
	"errors"
	"net/http"
	"net/url"
	"os"
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

// skipLiveInCI keeps the live tests out of CI, where YouTube bot-checks the
// runners, while still running them with every local go test ./...
func skipLiveInCI(t *testing.T) {
	t.Helper()
	if os.Getenv("CI") != "" {
		t.Skip("live YouTube tests only run locally")
	}
	if testing.Short() {
		t.Skip("live YouTube tests are skipped with -short")
	}
}

func liveHTTPClient() *http.Client { return &http.Client{Timeout: 30 * time.Second} }

// findLiveStream returns the first candidate whose /live page names a video
// and whose live_chat page parses. It skips only if every candidate's /live
// page is its offline channel page. Anything else fails: a failed request, a
// page liveVideoID does not recognize (e.g. a consent page), or a chat page
// we cannot parse. The later candidates are fallbacks for a stream that is
// offline or has chat turned off.
func findLiveStream(t *testing.T) liveStream {
	t.Helper()
	skipLiveInCI(t)
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
			failed = true
			continue
		}
		video, err := liveVideoID(body)
		if err != nil {
			if !errors.As(err, new(*unrecognizedPageError)) {
				t.Errorf("%s: liveVideoID returned an unexpected error type: %v", candidate.name, err)
			}
			t.Logf("%s: %v", candidate.name, err)
			failed = true
			continue
		}
		if video == "" {
			t.Logf("%s: not live", candidate.name)
			continue
		}
		if canonical, _ := canonicalVideoID(bytes.NewReader(body)); canonical == "" {
			// YouTube serves a bot check to some datacenter IPs, including
			// GitHub's runners; the video then comes from ytInitialData.
			t.Logf("%s: /live page has no canonical video (%s); found %s in the page data", candidate.name, describePage(body), video)
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
		t.Fatal("no live candidate could be read")
	}
	t.Skip("none of the candidate channels is live")
	return liveStream{}
}
