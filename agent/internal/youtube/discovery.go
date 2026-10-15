package youtube

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strings"

	"golang.org/x/net/html"
)

// HTTPClient is the HTTP transport used for quota-free channel discovery.
type HTTPClient interface {
	Do(*http.Request) (*http.Response, error)
}

type HTTPDiscovery struct {
	HTTP    HTTPClient
	BaseURL string
}

var videoIDPattern = regexp.MustCompile(`^[A-Za-z0-9_-]{11}$`)

func canonicalVideoID(r io.Reader) (string, error) {
	tokenizer := html.NewTokenizer(r)
	for {
		switch tokenizer.Next() {
		case html.ErrorToken:
			if tokenizer.Err() == io.EOF {
				return "", nil
			}
			return "", tokenizer.Err()
		case html.StartTagToken, html.SelfClosingTagToken:
			token := tokenizer.Token()
			if token.Data != "link" {
				continue
			}
			var rel, href string
			for _, attr := range token.Attr {
				switch attr.Key {
				case "rel":
					rel = attr.Val
				case "href":
					href = attr.Val
				}
			}
			canonical := false
			for _, value := range strings.Fields(rel) {
				if strings.EqualFold(value, "canonical") {
					canonical = true
				}
			}
			if !canonical {
				continue
			}
			u, err := url.Parse(href)
			if err != nil {
				return "", nil
			}
			if u.Scheme != "https" || u.Host != "www.youtube.com" || u.Path != "/watch" {
				return "", nil
			}
			id := u.Query().Get("v")
			if !videoIDPattern.MatchString(id) {
				return "", nil
			}
			return id, nil
		}
	}
}

var playerResponsePattern = regexp.MustCompile(`(?:window\s*\[\s*["']ytInitialPlayerResponse["']\s*\]|var\s+ytInitialPlayerResponse)\s*=\s*`)

// decodeEmbedded decodes the JSON value assigned to the script variable that
// pattern matches. It reports false if the page has no such variable or it
// does not decode.
func decodeEmbedded(page []byte, pattern *regexp.Regexp, v interface{}) bool {
	loc := pattern.FindIndex(page)
	return loc != nil && json.NewDecoder(bytes.NewReader(page[loc[1]:])).Decode(v) == nil
}

// unrecognizedPageError is a /live page that is neither a live video nor an
// offline channel page, such as a consent page or a changed layout.
type unrecognizedPageError struct{ page string }

func (e *unrecognizedPageError) Error() string {
	return "unrecognized YouTube /live page: " + e.page
}

// liveVideoID reads the /channel/{id}/live page, which is the watch page of
// the channel's live video while it is live and the channel page otherwise.
// It returns the video ID if live, "" if the page is an offline channel page,
// and an *unrecognizedPageError for anything else.
//
// The canonical link is the primary source, but YouTube's "Sign in to confirm
// you're not a bot" page (served to some datacenter IPs) has no canonical link
// and no videoDetails, while its ytInitialData still names the video.
func liveVideoID(page []byte) (string, error) {
	if id, err := canonicalVideoID(bytes.NewReader(page)); err == nil && id != "" {
		return id, nil
	}
	var player struct {
		VideoDetails struct {
			VideoID string `json:"videoId"`
		} `json:"videoDetails"`
	}
	if decodeEmbedded(page, playerResponsePattern, &player) && videoIDPattern.MatchString(player.VideoDetails.VideoID) {
		return player.VideoDetails.VideoID, nil
	}
	var initial struct {
		CurrentVideoEndpoint struct {
			WatchEndpoint struct {
				VideoID string `json:"videoId"`
			} `json:"watchEndpoint"`
		} `json:"currentVideoEndpoint"`
		Metadata struct {
			Channel *json.RawMessage `json:"channelMetadataRenderer"`
		} `json:"metadata"`
	}
	if decodeEmbedded(page, initialPattern, &initial) {
		if id := initial.CurrentVideoEndpoint.WatchEndpoint.VideoID; videoIDPattern.MatchString(id) {
			return id, nil
		}
		if initial.Metadata.Channel != nil {
			return "", nil
		}
	}
	return "", &unrecognizedPageError{describePage(page)}
}

var titlePattern = regexp.MustCompile(`(?s)<title[^>]*>(.*?)</title>`)
var playabilityPattern = regexp.MustCompile(`"playabilityStatus":\{"status":"([A-Z_]+)"(?:,"reason":"([^"]{0,200})")?`)

// describePage summarizes an unrecognized page for the logs.
func describePage(page []byte) string {
	first := func(p *regexp.Regexp) []string {
		m := p.FindSubmatch(page)
		s := make([]string, p.NumSubexp())
		for i := range s {
			if m != nil {
				s[i] = strings.TrimSpace(string(m[i+1]))
			}
		}
		return s
	}
	playability := first(playabilityPattern)
	return fmt.Sprintf("%d bytes, title %q, ytInitialData %v, consent %v, playability %q %q",
		len(page), first(titlePattern)[0], initialPattern.Match(page), bytes.Contains(page, []byte("consent.youtube.com")),
		playability[0], playability[1])
}

func (d *HTTPDiscovery) LiveChat(ctx context.Context, channel string) (string, error) {
	base := d.BaseURL
	if base == "" {
		base = "https://www.youtube.com"
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, base+"/channel/"+url.PathEscape(channel)+"/live", nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", desktopUA)
	resp, err := d.HTTP.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return "", &httpError{resp.StatusCode}
	}
	page, err := io.ReadAll(io.LimitReader(resp.Body, 8<<20))
	if err != nil {
		return "", err
	}
	return liveVideoID(page)
}
