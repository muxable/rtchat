package handler

import (
	"context"
	"errors"
	"os"

	"cloud.google.com/go/firestore"
	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/auth"
	"go.uber.org/zap"
	secretmanagerpb "google.golang.org/genproto/googleapis/cloud/secretmanager/v1"
)

type Handler struct {
	firestore *firestore.Client
	twitch    *TwitchHandler
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

	return &Handler{
		firestore: firestore,
		twitch: &TwitchHandler{
			firestore:    firestore,
			clientID:     twitchClientID,
			clientSecret: twitchClientSecret,
		},
	}, nil
}

type JoinContext struct {
	ReconnectCtx context.Context
	Close        func() error
}

func (h *Handler) Join(r *agent.Request) (*JoinContext, error) {
	switch r.Provider() {
	case agent.ProviderTwitch:
		// handle twitch request
		if userID, err := auth.TwitchUserIDFromUsername(h.firestore, h.twitch.clientID, h.twitch.clientSecret, r.Channel()); err != nil {
			zap.L().Info("failed to get twitch user id, probably never used realtimechat", zap.Error(err))
		} else if ctx, err := h.twitch.JoinAsUser(r, userID); err != nil {
			zap.L().Warn("failed to join channel as authed user", zap.Error(err))
		} else {
			return ctx, nil
		}

		// try again as realtimechat
		if ctx, err := h.twitch.JoinAsUser(r, "JSdHKOEgwcZijVsuXXdftmizt6E3"); err != nil {
			zap.L().Warn("failed to join channel as realtimechat", zap.Error(err))
		} else {
			return ctx, nil
		}

		// maybe we got banned, try again as anonymous
		if ctx, err := h.twitch.JoinAnonymously(r); err != nil {
			zap.L().Warn("failed to join channel as anonymous", zap.Error(err))
		} else {
			return ctx, nil
		}

		return nil, errors.New("failed to join channel")
	}
	return nil, errors.New("unknown provider")
}
