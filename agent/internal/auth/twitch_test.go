package auth

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"golang.org/x/oauth2"
)

type transport func(*http.Request) (*http.Response, error)

func (f transport) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

type trackedBody struct {
	io.Reader
	closed bool
}

func (b *trackedBody) Close() error { b.closed = true; return nil }

func TestProfileStringRejectsMalformed(t *testing.T) {
	for _, data := range []map[string]interface{}{{}, {"twitch": "broken"}, {"twitch": map[string]interface{}{"id": 123}}, {"twitch": map[string]interface{}{"id": ""}}} {
		if _, err := profileString(data, "id"); err == nil {
			t.Fatal("accepted malformed profile")
		}
	}
}

func TestValidateClosesResponseAndRejectsServerError(t *testing.T) {
	for _, code := range []int{200, 401, 500} {
		t.Run(http.StatusText(code), func(t *testing.T) {
			body := &trackedBody{Reader: strings.NewReader("{}")}
			c := &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) { return &http.Response{StatusCode: code, Body: body}, nil })}
			err := validateToken(c, &oauth2.Token{AccessToken: "secret"})
			if !body.closed {
				t.Error("response body leaked")
			}
			if (err != nil) != (code != 200) {
				t.Errorf("status=%d err=%v", code, err)
			}
		})
	}
}

func TestRefreshSourceSurvivesConstructionDeadline(t *testing.T) {
	// No network: replace the OAuth transport with a context-checking fake.
	previous := http.DefaultClient
	defer func() { http.DefaultClient = previous }()
	http.DefaultClient = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		if err := r.Context().Err(); err != nil {
			return nil, err
		}
		return &http.Response{StatusCode: 200, Header: http.Header{"Content-Type": []string{"application/json"}}, Body: io.NopCloser(strings.NewReader(`{"access_token":"fresh","refresh_token":"next","token_type":"bearer","expires_in":3600}`))}, nil
	})}
	cfg := &oauth2.Config{Endpoint: oauth2.Endpoint{TokenURL: "https://fake.invalid/token", AuthStyle: oauth2.AuthStyleInParams}}
	source := newRefreshSource(cfg, &oauth2.Token{RefreshToken: "old", Expiry: time.Now().Add(-time.Hour)})
	time.Sleep(5100 * time.Millisecond)
	token, err := source.Token()
	if errors.Is(err, context.DeadlineExceeded) || err != nil {
		t.Fatalf("refresh failed: %v", err)
	}
	if token.AccessToken != "fresh" {
		t.Fatal(token)
	}
}

func TestSecretPayloadReturnsAPIError(t *testing.T) {
	want := errors.New("permission denied")
	_, err := secretPayload(nil, want)
	if !errors.Is(err, want) {
		t.Fatal(err)
	}
}

func TestMergeTokenRejectsNull(t *testing.T) {
	if _, err := mergeToken("null", &oauth2.Token{}); err == nil {
		t.Fatal("accepted null stored token")
	}
}
func TestMergeTokenPreservesFields(t *testing.T) {
	expiry := time.Date(2026, 1, 2, 3, 4, 5, 6000000, time.UTC)
	data, err := mergeToken(`{"access_token":"old","refresh_token":"old-refresh","scope":["chat:read"],"other":true}`, &oauth2.Token{AccessToken: "fresh", RefreshToken: "rotated", Expiry: expiry})
	if err != nil {
		t.Fatal(err)
	}
	var got map[string]interface{}
	if err := json.Unmarshal(data, &got); err != nil {
		t.Fatal(err)
	}
	if got["access_token"] != "fresh" || got["refresh_token"] != "rotated" || got["expires_at"] != "2026-01-02T03:04:05.006Z" || got["other"] != true || got["scope"].([]interface{})[0] != "chat:read" {
		t.Fatal(got)
	}
	for _, text := range []string{"broken", "[]", "null"} {
		if _, err := mergeToken(text, &oauth2.Token{}); err == nil {
			t.Errorf("accepted %s", text)
		}
	}
}
