package youtube

import (
	"bytes"
	"context"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"strings"
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
// page we do not recognize (e.g. a consent or bot check), a live page without
// a canonical video, or a chat page we cannot parse. The later candidates are
// fallbacks for a stream that is offline or has chat turned off.
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
		video, err := canonicalVideoID(bytes.NewReader(body))
		if err != nil || video == "" {
			switch {
			case bytes.Contains(body, []byte(`"isLiveNow":true`)):
				t.Logf("%s: /live page is live but has no canonical video (err %v)", candidate.name, err)
				failed = true
			case bytes.Contains(body, []byte(`"channelMetadataRenderer"`)):
				t.Logf("%s: not live", candidate.name)
			default:
				t.Logf("%s: unrecognized /live page: %s", candidate.name, describePage(body))
				failed = true
				// A bot check hides the canonical link. Report whether chat
				// would still be readable through the video in ytInitialData.
				if m := watchEndpointPattern.FindSubmatch(body); m != nil {
					_, _, _, err := c.initial(ctx, string(m[1]))
					t.Logf("%s: live_chat for %s from ytInitialData: error %v", candidate.name, m[1], err)
				}
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
		t.Fatal("no live candidate could be read")
	}
	t.Skip("none of the candidate channels is live")
	return liveStream{}
}

var titlePattern = regexp.MustCompile(`(?s)<title[^>]*>(.*?)</title>`)
var playabilityPattern = regexp.MustCompile(`"playabilityStatus":\{"status":"([A-Z_]+)"(?:,"reason":"([^"]{0,200})")?`)
var watchEndpointPattern = regexp.MustCompile(`"currentVideoEndpoint":\{.{0,400}?"watchEndpoint":\{"videoId":"([A-Za-z0-9_-]{11})"`)
var pageVideoPattern = regexp.MustCompile(`"videoDetails":\{"videoId":"([A-Za-z0-9_-]{11})"`)

// describePage summarizes an unexpected page for the test log.
func describePage(body []byte) string {
	first := func(p *regexp.Regexp) []string {
		m := p.FindSubmatch(body)
		s := make([]string, p.NumSubexp())
		for i := range s {
			if m != nil {
				s[i] = strings.TrimSpace(string(m[i+1]))
			}
		}
		return s
	}
	playability := first(playabilityPattern)
	return fmt.Sprintf("%d bytes, title %q, ytInitialData %v, consent %v, videoDetails.videoId %q, playability %q %q",
		len(body), first(titlePattern)[0], initialPattern.Match(body), bytes.Contains(body, []byte("consent.youtube.com")),
		first(pageVideoPattern)[0], playability[0], playability[1])
}
