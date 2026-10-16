package main

import (
	"net/http"
	"os"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/actions"
	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/catalog"
	"github.com/muxable/rtchat/agent/internal/provider"
	"github.com/muxable/rtchat/agent/internal/publichttp"
	"github.com/muxable/rtchat/agent/internal/subscriptions"
	"github.com/muxable/rtchat/agent/internal/webhook"
	"go.uber.org/zap"
)

// newHTTPServer is the production route composition, also exercised before retirement.
func newHTTPServer(client *firestore.Client, secrets webhook.Secrets, verifier callable.VerifyFunc, twitchClientID, twitchClientSecret string, recycleHandler http.Handler) *webhook.Server {
	server := webhook.NewServer(secrets)
	api := callable.NewServer(verifier)
	actions.NewService(client, provider.NewService(client, nil), nil).Register(api)
	subscriptionService := &subscriptions.Service{
		DB:             client,
		API:            &subscriptions.API{Tokens: provider.NewService(client, &http.Client{Timeout: 10 * time.Second})},
		Enabled:        os.Getenv("AGENT_PROVIDER_SUBSCRIPTIONS_ENABLED") == "true",
		TwitchSecret:   secrets.TwitchEventSubSecret,
		MaticWebhookID: secrets.AlchemyMaticWebhookID,
	}
	subscriptionService.Register(api)
	catalog.Register(api, client, provider.NewService(client, nil))
	// Register every callable package before Mount so readiness and webhooks remain intact.
	api.Mount(server.Mux)
	if err := publichttp.Register(server.Mux, client, provider.NewService(client, nil)); err != nil {
		zap.L().Warn("public HTTP configuration invalid; routes disabled")
		for _, path := range []string{"/embed", "/embedRedirect", "/metadata", "/api/metadata"} {
			server.Mux.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
				http.Error(w, "temporarily unavailable", http.StatusServiceUnavailable)
			})
		}
	}
	server.RegisterProvider("/kick/", webhook.NewKickHandler(webhook.NewKickFirestoreStore(client)))
	server.RegisterProvider("/twitch/", webhook.NewTwitchHandler(secrets.TwitchEventSubSecret, client, twitchClientID, twitchClientSecret))
	server.RegisterProvider("/alchemy/", webhook.NewAlchemyHandler(webhook.AlchemyConfig{
		Secrets:        secrets,
		MaticWebhookID: secrets.AlchemyMaticWebhookID,
	}, webhook.AlchemyFirestore{Client: client}, webhook.NewAlchemyRPC()))
	server.Mux.Handle("/", recycleHandler)
	return server
}
