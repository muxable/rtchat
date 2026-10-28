package handler

import (
	"context"
	"errors"
	"io"

	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/cancel"
	"github.com/muxable/rtchat/agent/internal/provider"
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
	// Reading public chat should not depend on a broadcaster's grant or the
	// shared bot account's authentication queue and channel limits.
	if client, err := joinAnonymous(r); err == nil {
		return client, nil
	} else if cancel.IsCanceled(err) {
		return nil, err
	} else {
		zap.L().Warn("failed to join channel as anonymous", zap.Error(err), zap.String("channel", r.Channel()))
	}

	// handle twitch request
	if userID, err := lookup(r.Channel()); err != nil {
		if errors.Is(err, iterator.Done) {
			zap.L().Info("no Twitch profile for channel")
		} else {
			zap.L().Warn("failed to look up Twitch profile", zap.Error(err))
		}
	} else if client, err := joinUser(r, userID); err != nil {
		level := zap.WarnLevel
		if errors.Is(err, provider.ErrNoToken) {
			level = zap.InfoLevel
		}
		zap.L().Log(level, "failed to join channel as authed user", zap.Error(err))
	} else {
		return client, nil
	}

	// try again as realtimechat
	if client, err := joinUser(r, "JSdHKOEgwcZijVsuXXdftmizt6E3"); err != nil {
		zap.L().Warn("failed to join channel as realtimechat", zap.Error(err))
	} else {
		return client, nil
	}

	return nil, errors.New("failed to join channel")
}
