package handler

import (
	"context"
	"errors"
	"os"

	"cloud.google.com/go/firestore"
	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"github.com/gempir/go-twitch-irc/v3"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/auth"
	"go.uber.org/zap"
	secretmanagerpb "google.golang.org/genproto/googleapis/cloud/secretmanager/v1"
)

type Handler struct {
	twitch *TwitchHandler
}

func twitchClientID() string {
	id, ok := os.LookupEnv("TWITCH_CLIENT_ID")
	if !ok {
		return "edfnh2q85za8phifif9jxt3ey6t9b9"
	}
	return id
}

func twitchClientSecret() (string, error) {
	secret, ok := os.LookupEnv("TWITCH_CLIENT_SECRET")
	if ok {
		return secret, nil
	}
	ctx := context.Background()

	c, err := secretmanager.NewClient(ctx)
	if err != nil {
		return "", err
	}
	defer c.Close()

	req := &secretmanagerpb.AccessSecretVersionRequest{
		Name: "projects/rtchat-47692/secrets/twitch-client-secret/versions/latest",
	}

	// Call the API.
	result, err := c.AccessSecretVersion(ctx, req)
	return string(result.Payload.Data), err
}

func NewHandler(lock *agent.RequestLock, firestore *firestore.Client) (*Handler, error) {
	twitchClientID := twitchClientID()
	twitchClientSecret, err := twitchClientSecret()
	if err != nil {
		return nil, err
	}

	h := &Handler{
		twitch: &TwitchHandler{
			firestore:    firestore,
			clientID:     twitchClientID,
			clientSecret: twitchClientSecret,
			sendClients:  make(map[string]*twitch.Client),
		},
	}

	go func() {
		if err := h.twitch.bindOutboundClient(context.Background()); err != nil {
			zap.L().Fatal("failed to bind outbound client", zap.Error(err))
		}
	}()

	return h, nil
}

func (h *Handler) Join(r *agent.Request) error {
	switch r.Provider() {
	case agent.ProviderTwitch:
		// handle twitch request
		if userID, err := auth.TwitchUserIDFromUsername(h.twitch.firestore, h.twitch.clientID, h.twitch.clientSecret, r.Channel()); err != nil {
			zap.L().Info("failed to get twitch user id, probably never used realtimechat", zap.Error(err))
		} else if err := h.twitch.JoinAsUser(r, userID); err != nil {
			zap.L().Warn("failed to join channel as authed user", zap.Error(err))
		} else {
			return nil
		}

		// try again as realtimechat
		if err := h.twitch.JoinAsUser(r, "JSdHKOEgwcZijVsuXXdftmizt6E3"); err != nil {
			zap.L().Warn("failed to join channel as realtimechat", zap.Error(err))
		} else {
			return nil
		}

		// maybe we got banned, try again as anonymous
		if err := h.twitch.JoinAnonymously(r); err != nil {
			zap.L().Warn("failed to join channel as anonymous", zap.Error(err))
		} else {
			return nil
		}

		return errors.New("failed to join channel")
	}
	return errors.New("unknown provider")
}
