package handler

import (
	"context"
	"errors"
	"os"
	"sync"

	"cloud.google.com/go/firestore"
	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/auth"
	"go.uber.org/zap"
	secretmanagerpb "google.golang.org/genproto/googleapis/cloud/secretmanager/v1"
)

type Handler struct {
	lock           *agent.RequestLock
	activeChannels map[string]bool
	activeLock     *sync.Mutex

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
		lock:           lock,
		activeChannels: make(map[string]bool),
		activeLock:     &sync.Mutex{},
		firestore:      firestore,
		twitch: &TwitchHandler{
			lock:         lock,
			firestore:    firestore,
			clientID:     twitchClientID,
			clientSecret: twitchClientSecret,
		},
	}, nil
}

func (h *Handler) HandleRequest(r *agent.Request) error {
	h.activeLock.Lock()
	if h.activeChannels[r.Channel()] {
		h.activeLock.Unlock()
		return errors.New("channel already active")
	}
	h.activeChannels[r.Channel()] = true
	h.activeLock.Unlock()

	defer func() {
		h.activeLock.Lock()
		delete(h.activeChannels, r.Channel())
		h.activeLock.Unlock()
	}()

	switch r.Provider() {
	case agent.ProviderTwitch:
		// handle twitch request
		for {
			userID, err := auth.TwitchUserIDFromUsername(h.firestore, h.twitch.clientID, h.twitch.clientSecret, r.Channel())
			if err != nil {
				zap.L().Info("failed to get twitch user id, probably never used realtimechat", zap.Error(err))
				break
			}
			if err := h.twitch.HandleRequest(r, userID); err != nil {
				if err == errReconnect {
					continue
				}
				zap.L().Warn("failed to join channel as authed user", zap.Error(err))
				break
			}
			// completed successfully.
			return nil
		}
		// try again as realtimechat
		for {
			if err := h.twitch.HandleRequest(r, "JSdHKOEgwcZijVsuXXdftmizt6E3"); err != nil {
				if err == errReconnect {
					continue
				}
				zap.L().Warn("failed to join channel as realtimechat", zap.Error(err))
				break
			}
			// completed successfully.
			return nil
		}
		// maybe we got banned, try again as anonymous
		for {
			if err := h.twitch.HandleRequestAnonymously(r); err != nil {
				if err == errReconnect {
					continue
				}
				zap.L().Warn("failed to join channel as anonymous", zap.Error(err))
				break
			}
			// completed successfully.
			return nil
		}
		return errors.New("failed to join channel")
	}
	return errors.New("unknown provider")
}
