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
	"time"
)

const desktopUA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/130.0.0.0 Safari/537.36"

type httpError struct{ code int }

func (e *httpError) Error() string { return fmt.Sprintf("YouTube HTTP status %d", e.code) }

type chatPage struct {
	Actions       []json.RawMessage `json:"actions"`
	Continuations []map[string]struct {
		Token   string `json:"continuation"`
		Timeout int64  `json:"timeoutMs"`
	} `json:"continuations"`
}

func (p chatPage) next() (string, time.Duration) {
	if len(p.Continuations) == 0 {
		return "", 0
	}
	for _, kind := range []string{"invalidationContinuationData", "timedContinuationData", "reloadContinuationData"} {
		if c, ok := p.Continuations[0][kind]; ok {
			return c.Token, time.Duration(c.Timeout) * time.Millisecond
		}
	}
	return "", 0
}

var keyPattern = regexp.MustCompile(`"INNERTUBE_API_KEY"\s*:\s*("(?:[^"\\]|\\.)*")`)
var versionPattern = regexp.MustCompile(`"INNERTUBE_CLIENT_VERSION"\s*:\s*("(?:[^"\\]|\\.)*")`)
var initialPattern = regexp.MustCompile(`(?:window\s*\[\s*["']ytInitialData["']\s*\]|var\s+ytInitialData)\s*=\s*`)

func initialPage(html []byte) (chatPage, string, string, error) {
	var key, version string
	for pattern, dest := range map[*regexp.Regexp]*string{keyPattern: &key, versionPattern: &version} {
		match := pattern.FindSubmatch(html)
		if len(match) != 2 || json.Unmarshal(match[1], dest) != nil || *dest == "" {
			return chatPage{}, "", "", fmt.Errorf("missing InnerTube configuration")
		}
	}
	loc := initialPattern.FindIndex(html)
	if loc == nil {
		return chatPage{}, "", "", fmt.Errorf("missing ytInitialData")
	}
	var initial struct {
		Contents struct {
			Chat *chatPage `json:"liveChatRenderer"`
		} `json:"contents"`
	}
	// Decode one JSON value, ignoring the semicolon and remaining HTML. Braces
	// inside strings cannot prematurely terminate the embedded JSON.
	if err := json.NewDecoder(bytes.NewReader(html[loc[1]:])).Decode(&initial); err != nil {
		return chatPage{}, "", "", err
	}
	if initial.Contents.Chat == nil {
		return chatPage{}, "", "", fmt.Errorf("missing liveChatRenderer")
	}
	return *initial.Contents.Chat, key, version, nil
}

func (c *Client) request(ctx context.Context, method, path string, body []byte) ([]byte, error) {
	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", desktopUA)
	if method == http.MethodPost {
		req.Header.Set("Content-Type", "application/json")
	}
	c.counts.requests.Add(1)
	resp, err := c.http.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusTooManyRequests {
		c.counts.rateLimits.Add(1)
	}
	if resp.StatusCode != http.StatusOK {
		return nil, &httpError{resp.StatusCode}
	}
	return io.ReadAll(io.LimitReader(resp.Body, 8<<20))
}

func (c *Client) initial(ctx context.Context, video string) (chatPage, string, string, error) {
	body, err := c.request(ctx, http.MethodGet, "/live_chat?v="+url.QueryEscape(video)+"&is_popout=1", nil)
	if err != nil {
		return chatPage{}, "", "", err
	}
	page, key, version, err := initialPage(body)
	if err != nil {
		c.counts.parseFailures.Add(1)
	}
	return page, key, version, err
}

func (c *Client) poll(ctx context.Context, key, version, token string) (chatPage, error) {
	body, err := json.Marshal(map[string]interface{}{"context": map[string]interface{}{"client": map[string]string{"clientName": "WEB", "clientVersion": version}}, "continuation": token})
	if err != nil {
		return chatPage{}, err
	}
	response, err := c.request(ctx, http.MethodPost, "/youtubei/v1/live_chat/get_live_chat?key="+url.QueryEscape(key)+"&prettyPrint=false", body)
	if err != nil {
		return chatPage{}, err
	}
	var result struct {
		Contents struct {
			Chat chatPage `json:"liveChatContinuation"`
		} `json:"continuationContents"`
	}
	if err := json.Unmarshal(response, &result); err != nil {
		c.counts.parseFailures.Add(1)
		return chatPage{}, err
	}
	return result.Contents.Chat, nil
}
