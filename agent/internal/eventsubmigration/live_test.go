package eventsubmigration

import (
	"context"
	"encoding/json"
	"net/http"
	"net/url"
	"os"
	"testing"
	"time"

	"github.com/muxable/rtchat/agent/internal/provider"
)

// Opt-in inventory validation: GET only, no migration or subscription changes.
func TestLiveTwitchSubscriptionInventory(t *testing.T) {
	if os.Getenv("RTCHAT_LIVE_PROVIDER_TESTS") != "1" {
		t.Skip("set RTCHAT_LIVE_PROVIDER_TESTS=1")
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	httpClient := &http.Client{Timeout: 15 * time.Second}
	tokens := provider.NewServiceWithStore(nil, httpClient, nil)
	token, err := tokens.AppAccessToken(ctx, "twitch")
	if err != nil {
		t.Fatal("Twitch app authorization unavailable")
	}
	credentials, err := tokens.Credentials(ctx, "twitch")
	if err != nil {
		t.Fatal("Twitch credentials unavailable")
	}
	api := API{Client: httpClient, ClientID: credentials.ClientID, Token: token}
	// Sample a single page: a smoke test must not consume the app's entire
	// inventory or shared rate-limit budget.
	var listing Listing
	err = api.request(ctx, http.MethodGet, url.Values{"first": {"100"}}, nil, &listing)
	if err != nil {
		t.Fatal(err)
	}
	for _, sub := range listing.Data {
		if sub.ID == "" || sub.Type == "" || sub.Version == "" || !json.Valid(sub.Condition) {
			t.Fatal("unexpected live subscription schema")
		}
	}
	t.Logf("real API: decoded %d sampled EventSub subscriptions (more pages: %t) without mutation", len(listing.Data), listing.Pagination.Cursor != "")
}
