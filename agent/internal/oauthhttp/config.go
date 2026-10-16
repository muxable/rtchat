package oauthhttp

import (
	"context"
	"net"
	"net/http"
	"os"
	"strings"

	"cloud.google.com/go/firestore"
	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
	firebase "firebase.google.com/go/v4"
	"github.com/muxable/rtchat/agent/internal/auth"
	"go.uber.org/zap"
)

// Register loads optional credentials without making the chat worker depend on OAuth.
func Register(ctx context.Context, mux *http.ServeMux, db *firestore.Client) error {
	app, err := firebase.NewApp(ctx, &firebase.Config{ProjectID: "rtchat-47692", DatabaseURL: "https://rtchat-47692-default-rtdb.firebaseio.com"})
	if err != nil {
		return err
	}
	authClient, err := app.Auth(ctx)
	if err != nil {
		return err
	}
	database, err := app.Database(ctx)
	if err != nil {
		return err
	}
	secrets, err := secretmanager.NewClient(ctx)
	if err != nil {
		return err
	}
	defer secrets.Close()
	load := func(name string) string {
		result, err := secrets.AccessSecretVersion(ctx, &secretmanagerpb.AccessSecretVersionRequest{Name: "projects/rtchat-47692/secrets/" + name + "/versions/latest"})
		if err != nil {
			zap.L().Warn("OAuth secret unavailable", zap.String("secret", name))
			return ""
		}
		return string(result.GetPayload().GetData())
	}
	providers := map[string]Provider{
		"twitch":         {AuthorizeURL: "https://id.twitch.tv/oauth2/authorize", TokenURL: "https://id.twitch.tv/oauth2/token", JSONBody: true, Scopes: "bits:read channel:bot channel:edit:commercial channel:manage:ads channel:manage:broadcast channel:manage:moderators channel:manage:polls channel:manage:predictions channel:manage:raids channel:manage:vips channel:moderate channel:read:ads channel:read:hype_train channel:read:redemptions channel:read:subscriptions chat:edit chat:read moderation:read moderator:manage:banned_users moderator:manage:chat_messages moderator:manage:chat_settings moderator:manage:shoutouts moderator:manage:warnings moderator:read:chatters moderator:read:followers moderator:read:shoutouts user:bot user:read:email user:read:emotes user:read:follows user:read:moderated_channels user:read:subscriptions user:write:chat"},
		"kick":           {AuthorizeURL: "https://id.kick.com/oauth/authorize", TokenURL: "https://id.kick.com/oauth/token", Scopes: "user:read channel:read chat:write events:subscribe moderation:ban moderation:chat_message:manage"},
		"youtube":        {AuthorizeURL: "https://accounts.google.com/o/oauth2/v2/auth", TokenURL: "https://oauth2.googleapis.com/token", Scopes: "https://www.googleapis.com/auth/youtube.force-ssl"},
		"streamlabs":     {AuthorizeURL: "https://www.streamlabs.com/api/v1.0/authorize", TokenURL: "https://www.streamlabs.com/api/v1.0/token", JSONBody: true, Scopes: "donations.read socket.token"},
		"streamelements": {AuthorizeURL: "https://api.streamelements.com/oauth2/authorize", TokenURL: "https://api.streamelements.com/oauth2/token", Scopes: "tips:read"},
	}
	for name, p := range providers {
		prefix := name
		if name == "youtube" {
			prefix = "youtube-oauth"
		}
		if name == "twitch" {
			p.ClientID = auth.TwitchClientID()
		} else {
			p.ClientID = load(prefix + "-client-id")
		}
		p.ClientSecret = load(prefix + "-client-secret")
		providers[name] = p
	}
	origin := os.Getenv("OAUTH_CALLBACK_ORIGIN")
	if origin == "" {
		origin = "https://chat.rtirl.com"
	}
	if origin != "https://chat.rtirl.com" && origin != "https://rtchat-api.rtirl.com" {
		return &configError{}
	}
	s := &Server{Store: &FirebaseStore{Firestore: db, Auth: authClient, Database: database}, Providers: providers, SessionKey: []byte(load("EXPRESS_SECRET")), CallbackOrigin: origin}
	for _, cidr := range strings.Split(os.Getenv("OAUTH_TRUSTED_PROXY_CIDRS"), ",") {
		if strings.TrimSpace(cidr) == "" {
			continue
		}
		_, network, err := net.ParseCIDR(strings.TrimSpace(cidr))
		if err != nil {
			return err
		}
		s.TrustedProxies = append(s.TrustedProxies, network)
	}
	s.Register(mux)
	return nil
}

type configError struct{}

func (*configError) Error() string { return "unsupported OAuth callback origin" }
