package handler

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/provider"
	"google.golang.org/api/option"
)

type refreshTransport func(*http.Request) (*http.Response, error)

func (f refreshTransport) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func TestIRCClearsRevokedAuthWithoutRemovingOtherAccounts(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST for revocation integration tests")
	}
	ctx := context.Background()
	db, err := firestore.NewClient(ctx, fmt.Sprintf("demo-irc-revocation-%d", time.Now().UnixNano()), option.WithoutAuthentication())
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	const expired = `{"access_token":"expired","refresh_token":"revoked","expires_at":"2000-01-01T00:00:00Z"}`
	const newer = `{"access_token":"reauthorized","refresh_token":"new-grant","expires_at":"2099-01-01T00:00:00Z"}`
	cases := []struct {
		name         string
		status       int
		body         string
		reauthorized bool
		remove       bool
	}{
		{"revoked", 400, `{"message":"Invalid refresh token"}`, false, true},
		{"invalid grant", 400, `{"error":"invalid_grant"}`, false, true},
		{"temporary provider failure", 503, `{"error":"temporarily_unavailable"}`, false, false},
		{"server error with grant payload", 503, `{"error":"invalid_grant"}`, false, false},
		{"client configuration error", 401, `{"error":"invalid_client"}`, false, false},
		{"reauthorized while old refresh failed", 400, `{"message":"Invalid refresh token"}`, true, false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			uid := strings.ReplaceAll(tc.name, " ", "-")
			tokens := db.Collection("tokens").Doc(uid)
			profile := db.Collection("profiles").Doc(uid)
			if _, err := tokens.Set(ctx, map[string]any{"twitch": expired, "kick": "other-provider-token"}); err != nil {
				t.Fatal(err)
			}
			if _, err := profile.Set(ctx, map[string]any{"twitch": map[string]any{"id": "42", "login": "original"}, "kick": map[string]any{"id": "99"}, "claims": map[string]any{"ads": true}}); err != nil {
				t.Fatal(err)
			}
			calls := 0
			service := provider.NewServiceWithStore(provider.FirestoreStore{DB: db}, &http.Client{Transport: refreshTransport(func(*http.Request) (*http.Response, error) {
				calls++
				if tc.reauthorized {
					// OAuth callbacks can replace this provider while retaining the old lease.
					if _, err := tokens.Set(ctx, map[string]any{"twitch": newer}, firestore.MergeAll); err != nil {
						t.Fatal(err)
					}
					if _, err := profile.Set(ctx, map[string]any{"twitch": map[string]any{"id": "84", "login": "new-login"}}, firestore.MergeAll); err != nil {
						t.Fatal(err)
					}
				}
				return &http.Response{StatusCode: tc.status, Header: http.Header{"Content-Type": []string{"application/json"}}, Body: io.NopCloser(strings.NewReader(tc.body))}, nil
			})}, func(context.Context, string) (string, error) { return "test-secret", nil })
			agent := &TwitchAgent{Firestore: db}
			agent.tokenServiceOnce.Do(func() { agent.tokenService = service })
			source, err := agent.tokens(uid)
			if err != nil {
				t.Fatal(err)
			}
			if _, err := source.Token(); err == nil {
				t.Fatal("refresh unexpectedly succeeded")
			}
			tokenDoc, err := tokens.Get(ctx)
			if err != nil {
				t.Fatal(err)
			}
			profileDoc, err := profile.Get(ctx)
			if err != nil {
				t.Fatal(err)
			}
			gotTokens, gotProfile := tokenDoc.Data(), profileDoc.Data()
			if gotTokens["kick"] != "other-provider-token" || gotProfile["kick"].(map[string]any)["id"] != "99" || gotProfile["claims"].(map[string]any)["ads"] != true {
				t.Fatal("unrelated account or settings removed")
			}
			if tc.remove {
				if gotTokens["twitch"] != nil || gotProfile["twitch"] != nil {
					t.Fatal("revoked provider remains signed in")
				}
				// A stale IRC source cannot keep retrying or resurrecting the removed grant.
				if _, err := source.Token(); !errors.Is(err, provider.ErrNoToken) {
					t.Fatal(err)
				}
				if calls != 1 {
					t.Fatal("revoked refresh token retried", calls)
				}
			} else {
				want := expired
				login := "original"
				if tc.reauthorized {
					want = newer
					login = "new-login"
				}
				if gotTokens["twitch"] != want || gotProfile["twitch"].(map[string]any)["login"] != login {
					t.Fatal("transient failure removed or overwrote current authorization")
				}
			}
		})
	}
}
