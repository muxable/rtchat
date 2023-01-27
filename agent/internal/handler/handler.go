package handler

import (
	"context"
	"errors"
	"io"

	"github.com/muxable/rtchat/agent/internal/agent"
	"go.uber.org/zap"
)

func (h *TwitchAgent) NewClient(r *agent.Request) (io.Closer, error) {
	// handle twitch request
	if userDoc, err := h.Firestore.Collection("profiles").Where("twitch.login", "==", r.Channel()).Documents(context.Background()).Next(); err != nil {
		zap.L().Info("failed to get twitch user id, probably never used realtimechat", zap.Error(err))
	} else if client, err := h.JoinAsUser(r, userDoc.Ref.ID); err != nil {
		zap.L().Warn("failed to join channel as authed user", zap.Error(err))
	} else {
		return client, nil
	}

	// try again as realtimechat
	if client, err := h.JoinAsUser(r, "JSdHKOEgwcZijVsuXXdftmizt6E3"); err != nil {
		zap.L().Warn("failed to join channel as realtimechat", zap.Error(err))
	} else {
		return client, nil
	}

	// maybe we got banned, try again as anonymous
	if client, err := h.JoinAnonymously(r); err != nil {
		zap.L().Warn("failed to join channel as anonymous", zap.Error(err))
	} else {
		return client, nil
	}

	return nil, errors.New("failed to join channel")
}
