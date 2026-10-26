package handler

import (
	"context"
	"errors"
	"io"

	"github.com/muxable/rtchat/agent/internal/agent"
	"go.uber.org/zap"
	"google.golang.org/api/iterator"
)

func (h *TwitchAgent) NewClient(r *agent.Request) (io.Closer, error) {
	return newClientWithFallbacks(r, func(channel string) (string, error) {
		iter := h.Firestore.Collection("profiles").Where("twitch.login", "==", channel).Documents(context.Background())
		doc, err := agent.FirstDocument(iter)
		if err != nil {
			return "", err
		}
		return doc.Ref.ID, nil
	}, h.JoinAsUser, func(r *agent.Request) (io.Closer, error) { return h.JoinAnonymously(r) })
}

func newClientWithFallbacks(r *agent.Request, lookup func(string) (string, error), joinUser func(*agent.Request, string) (io.Closer, error), joinAnonymous func(*agent.Request) (io.Closer, error)) (io.Closer, error) {
	// handle twitch request
	if userID, err := lookup(r.Channel()); err != nil {
		if errors.Is(err, iterator.Done) {
			zap.L().Info("no Twitch profile for channel")
		} else {
			zap.L().Warn("failed to look up Twitch profile", zap.Error(err))
		}
	} else if client, err := joinUser(r, userID); err != nil {
		zap.L().Warn("failed to join channel as authed user", zap.Error(err))
	} else {
		return client, nil
	}

	// try again as realtimechat
	if client, err := joinUser(r, "JSdHKOEgwcZijVsuXXdftmizt6E3"); err != nil {
		zap.L().Warn("failed to join channel as realtimechat", zap.Error(err))
	} else {
		return client, nil
	}

	// maybe we got banned, try again as anonymous
	if client, err := joinAnonymous(r); err != nil {
		zap.L().Warn("failed to join channel as anonymous", zap.Error(err))
	} else {
		return client, nil
	}

	return nil, errors.New("failed to join channel")
}
