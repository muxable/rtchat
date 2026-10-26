package auth

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"testing"

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

func TestSecretPayloadReturnsAPIError(t *testing.T) {
	want := errors.New("permission denied")
	_, err := secretPayload(nil, want)
	if !errors.Is(err, want) {
		t.Fatal(err)
	}
}

type tokenProviderFunc func(context.Context, string, string) (string, error)

func (f tokenProviderFunc) AccessToken(ctx context.Context, uid, provider string) (string, error) {
	return f(ctx, uid, provider)
}

func TestIRCTokenSourceUsesSharedProviderOnEveryCall(t *testing.T) {
	calls := 0
	source := NewTwitchTokenSource(tokenProviderFunc(func(ctx context.Context, uid, p string) (string, error) {
		calls++
		if uid != "user" || p != "twitch" || ctx.Err() != nil {
			t.Fatal("wrong account or expired request context")
		}
		if _, ok := ctx.Deadline(); !ok {
			t.Fatal("missing operation deadline")
		}
		return "access", nil
	}), "user")
	validates := 0
	source.client = &http.Client{Transport: transport(func(request *http.Request) (*http.Response, error) {
		validates++
		if request.Header.Get("Authorization") != "OAuth access" {
			t.Fatal("wrong validation token")
		}
		return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader("{}"))}, nil
	})}
	for i := 0; i < 2; i++ {
		token, err := source.Token()
		if err != nil || token.AccessToken != "access" {
			t.Fatal(token, err)
		}
	}
	if calls != 2 || validates != 2 {
		t.Fatal("reconnect reused stale token", calls, validates)
	}
}

func TestIRCTokenSourcePropagatesRevocationWithoutValidatingStaleToken(t *testing.T) {
	want := errors.New("provider token unavailable")
	source := NewTwitchTokenSource(tokenProviderFunc(func(context.Context, string, string) (string, error) { return "", want }), "user")
	source.client = &http.Client{Transport: transport(func(*http.Request) (*http.Response, error) {
		t.Fatal("validated an unavailable token")
		return nil, nil
	})}
	if _, err := source.Token(); !errors.Is(err, want) {
		t.Fatal(err)
	}
}
