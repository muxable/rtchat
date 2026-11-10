// Package clients provides bounded JSON transport for provider-specific clients.
package clients

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

type Client struct {
	HTTP    *http.Client
	BaseURL string
	Headers http.Header
}

type Response struct {
	StatusCode int
	Header     http.Header
	Body       []byte
}

// HTTPError deliberately excludes response bodies, which may contain credentials.
// Explained records only whether the provider gave a reason for the rejection.
type HTTPError struct {
	Status    int
	Explained bool
}

func (e *HTTPError) Error() string { return fmt.Sprintf("provider returned HTTP %d", e.Status) }

func (r *Response) Err() error {
	if r.StatusCode < 200 || r.StatusCode >= 300 {
		return &HTTPError{Status: r.StatusCode, Explained: explained(r.Body)}
	}
	return nil
}

// explained reports whether a JSON error body carries a non-blank "message",
// the field Twitch and Kick use to say why they rejected a request.
func explained(body []byte) bool {
	var result struct{ Message any }
	if json.Unmarshal(body, &result) != nil {
		return false
	}
	message, _ := result.Message.(string)
	return strings.TrimSpace(message) != ""
}

func (r *Response) Decode(out any) error {
	if out != nil && json.Unmarshal(r.Body, out) != nil {
		return errors.New("invalid provider response")
	}
	return nil
}

// Do sends one request. Callers decide which rejected or idempotent operations
// may be retried; an ambiguous POST is never retried by the transport.
func (c Client) Do(ctx context.Context, method, path string, body any) (*Response, error) {
	if !strings.HasPrefix(path, "/") || strings.HasPrefix(path, "//") {
		return nil, errors.New("provider request requires a relative path")
	}
	var encoded []byte
	var err error
	if body != nil {
		encoded, err = json.Marshal(body)
		if err != nil {
			return nil, err
		}
	}
	req, err := http.NewRequestWithContext(ctx, method, strings.TrimRight(c.BaseURL, "/")+path, bytes.NewReader(encoded))
	if err != nil {
		return nil, errors.New("invalid provider request")
	}
	req.Header = c.Headers.Clone()
	if req.Header == nil {
		req.Header = make(http.Header)
	}
	req.Header.Set("Accept", "application/json")
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	client := c.HTTP
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	response, err := client.Do(req)
	if err != nil {
		if ctx.Err() != nil {
			return nil, ctx.Err()
		}
		return nil, errors.New("provider transport failure")
	}
	defer response.Body.Close()
	data, err := io.ReadAll(io.LimitReader(response.Body, (8<<20)+1))
	if err != nil {
		return nil, errors.New("provider response read failed")
	}
	if len(data) > 8<<20 {
		return nil, errors.New("provider response too large")
	}
	return &Response{StatusCode: response.StatusCode, Header: response.Header, Body: data}, nil
}

// Get retries provider 5xx responses up to three times, honoring server backoff
// and the caller's context. Do remains single-attempt for callers with their own policy.
func (c Client) Get(ctx context.Context, path string, out any) error {
	for attempt := 0; ; attempt++ {
		response, err := c.Do(ctx, http.MethodGet, path, nil)
		if err != nil {
			return err
		}
		if response.StatusCode >= 500 && response.StatusCode < 600 && attempt < 3 {
			if err := Wait(ctx, RetryDelay(response.Header, attempt)); err != nil {
				return err
			}
			continue
		}
		if err := response.Err(); err != nil {
			return err
		}
		return response.Decode(out)
	}
}

func (c Client) DoJSON(ctx context.Context, method, path string, body any) (int, map[string]any, error) {
	response, err := c.Do(ctx, method, path, body)
	if err != nil {
		return 0, nil, err
	}
	var data map[string]any
	if len(response.Body) > 0 {
		err = response.Decode(&data)
	}
	if statusErr := response.Err(); statusErr != nil {
		return response.StatusCode, data, statusErr
	}
	return response.StatusCode, data, err
}
