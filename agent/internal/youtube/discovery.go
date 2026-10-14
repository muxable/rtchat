package youtube

import (
	"context"
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
	return canonicalVideoID(io.LimitReader(resp.Body, 8<<20))
}
