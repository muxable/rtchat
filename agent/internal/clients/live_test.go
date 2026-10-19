package clients_test

import (
	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
	"context"
	"github.com/muxable/rtchat/agent/internal/clients/kick"
	"github.com/muxable/rtchat/agent/internal/clients/twitch"
	"github.com/muxable/rtchat/agent/internal/clients/youtube"
	"github.com/muxable/rtchat/agent/internal/provider"
	"net/http"
	"net/url"
	"os"
	"testing"
	"time"
)

// Live checks issue app tokens and GET public provider data only. They never
// refresh user grants or mutate chat, subscriptions, or production Firestore.
// Run with RTCHAT_LIVE_PROVIDER_TESTS=1 go test -v ./internal/clients -run Live.
func requireLiveProviderTests(t *testing.T) {
	t.Helper()
	if os.Getenv("RTCHAT_LIVE_PROVIDER_TESTS") != "1" {
		t.Skip("set RTCHAT_LIVE_PROVIDER_TESTS=1 to call real provider APIs")
	}
}
func TestLiveTwitch(t *testing.T) {
	requireLiveProviderTests(t)
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()
	httpClient := &http.Client{Timeout: 15 * time.Second}
	tokens := provider.NewServiceWithStore(nil, httpClient, nil)
	token, err := tokens.AppAccessToken(ctx, "twitch")
	if err != nil {
		t.Fatalf("app authorization unavailable: %v", err)
	}
	credentials, err := tokens.Credentials(ctx, "twitch")
	if err != nil {
		t.Fatal("credentials lookup failed")
	}
	client := twitch.New(httpClient, credentials.ClientID, token)
	user, err := client.User(ctx, "login", "twitch")
	if err != nil {
		t.Fatal(err)
	}
	if user.ID == "" || user.Login != "twitch" {
		t.Fatal("unexpected public user response")
	}
	var badges struct {
		Data []struct {
			SetID string `json:"set_id"`
		}
	}
	if err := client.Get(ctx, "/chat/badges/global", &badges); err != nil {
		t.Fatal(err)
	}
	if len(badges.Data) == 0 {
		t.Fatal("empty global badges")
	}
	t.Logf("real API: typed user lookup and %d global badge sets decoded", len(badges.Data))
}

func TestLiveKick(t *testing.T) {
	requireLiveProviderTests(t)
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()
	httpClient := &http.Client{Timeout: 15 * time.Second}
	tokens := provider.NewServiceWithStore(nil, httpClient, nil)
	token, err := tokens.AppAccessToken(ctx, "kick")
	if err != nil {
		t.Fatalf("app authorization unavailable: %v", err)
	}
	var channel struct {
		Data []struct {
			ID   int64 `json:"broadcaster_user_id"`
			Slug string
		}
	}
	if err := kick.New(httpClient, token).Get(ctx, "/channels?slug=xqc", &channel); err != nil {
		t.Fatal(err)
	}
	if len(channel.Data) == 0 || channel.Data[0].ID == 0 || channel.Data[0].Slug == "" {
		t.Fatal("unexpected public channel response")
	}
	var subscriptions struct {
		Data []struct {
			ID      string `json:"id"`
			Event   string `json:"event"`
			Version int    `json:"version"`
		}
	}
	if err := kick.New(httpClient, token).Get(ctx, "/events/subscriptions", &subscriptions); err != nil {
		t.Fatal(err)
	}
	if subscriptions.Data == nil {
		t.Fatal("subscription inventory missing data")
	}
	for _, sub := range subscriptions.Data {
		if sub.ID == "" || sub.Event == "" || sub.Version == 0 {
			t.Fatal("unexpected subscription inventory schema")
		}
	}
	t.Logf("real API: Kick channel and %d current event subscriptions decoded without mutation", len(subscriptions.Data))
}

func TestLiveYouTube(t *testing.T) {
	requireLiveProviderTests(t)
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()
	secretClient, err := secretmanager.NewClient(ctx)
	if err != nil {
		t.Fatal("Secret Manager credentials unavailable")
	}
	defer secretClient.Close()
	secret, err := secretClient.AccessSecretVersion(ctx, &secretmanagerpb.AccessSecretVersionRequest{Name: "projects/rtchat-47692/secrets/youtube-api-key/versions/latest"})
	if err != nil {
		t.Fatalf("API-key access unavailable: %v", err)
	}
	key := string(secret.GetPayload().GetData())
	if key == "" {
		t.Fatal("API key unavailable")
	}
	var channels struct {
		Items []struct {
			ID      string
			Snippet struct{ Title string }
		}
	}
	query := url.Values{"part": {"snippet"}, "forHandle": {"@LofiGirl"}, "key": {key}}
	if err := youtube.New(&http.Client{Timeout: 15 * time.Second}, "").Get(ctx, "/channels?"+query.Encode(), &channels); err != nil {
		t.Fatal(err)
	}
	if len(channels.Items) == 0 || channels.Items[0].ID == "" || channels.Items[0].Snippet.Title == "" {
		t.Fatal("unexpected public YouTube response")
	}
	t.Log("real API: API-key channel lookup and snippet decoded")
}
