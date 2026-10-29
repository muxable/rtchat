package main

import (
	"context"
	"errors"
	"time"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/clients"
	"github.com/muxable/rtchat/agent/internal/clients/twitch"
	"go.uber.org/zap"
)

func (s *chatRoutes) twitch(ctx context.Context, uid, token, action string, r chatRequest) (any, error) {
	id, err := s.profileID(ctx, uid, "twitch")
	if err != nil {
		return nil, err
	}
	if id == "" {
		if action == "send" {
			return "not signed in with twitch", nil
		}
		return nil, nil
	}
	credentials, err := s.tokens.Credentials(ctx, "twitch")
	if err != nil {
		return nil, err
	}
	client := twitch.New(s.httpClient, credentials.ClientID, token)
	var app *twitch.Client
	user := func(key, value string) (twitch.User, error) {
		if app == nil {
			token, err := s.tokens.AppAccessToken(ctx, "twitch")
			if err != nil {
				return twitch.User{}, err
			}
			app = twitch.New(s.httpClient, credentials.ClientID, token)
		}
		return app.User(ctx, key, value)
	}
	if action == "send" {
		message, err := client.SendMessage(ctx, r.ChannelID, id, r.Message, r.ReplyID)
		var statusErr *clients.HTTPError
		if errors.As(err, &statusErr) && (statusErr.Status == 401 || statusErr.Status == 403) {
			target, err := user("id", r.ChannelID)
			if err != nil {
				return nil, err
			}
			if target.Login == "" {
				return nil, nil
			}
			sender, err := user("id", id)
			if err != nil {
				return nil, err
			}
			if sender.Login == "" {
				return nil, errors.New("sender unavailable on Twitch")
			}
			return nil, s.sendIRC(ctx, token, sender.Login, target.Login, r.Message)
		}
		if err != nil {
			return nil, err
		}
		if message == "" {
			return nil, nil
		}
		return message, nil
	}
	target := r.UserID
	if (action == "ban" || action == "unban" || action == "timeout") && target == "" {
		user, err := user("login", r.Username)
		if err != nil {
			return nil, err
		}
		if user.ID == "" {
			return nil, &callable.Error{Code: "not-found", Message: "Twitch user not found"}
		}
		target = user.ID
	}
	switch action {
	case "ban":
		err = client.Ban(ctx, r.ChannelID, id, target, 0, "")
	case "timeout":
		err = client.Ban(ctx, r.ChannelID, id, target, r.Length, r.Reason)
	case "unban":
		err = client.Unban(ctx, r.ChannelID, id, target)
	case "deleteMessage":
		err = client.DeleteMessages(ctx, r.ChannelID, id, r.MessageID)
	case "clear":
		err = client.DeleteMessages(ctx, r.ChannelID, id, "")
	case "raid":
		var started time.Time
		started, err = client.StartRaid(ctx, r.From, r.To)
		var rejected *twitch.RaidRejected
		if errors.As(err, &rejected) {
			return nil, &callable.Error{Code: "failed-precondition", Message: rejected.Message}
		}
		if err == nil && !started.IsZero() {
			if user, lookupErr := client.User(ctx, "id", r.To); lookupErr == nil {
				user.ID = r.To
				if s.store.RaidStart(ctx, r.From, user, started) != nil {
					zap.L().Warn("failed to record raid start")
				}
			}
		}
	case "shoutout":
		var reason string
		reason, err = client.Shoutout(ctx, r.From, r.To, id)
		if err == nil && reason != "" {
			err = &callable.Error{Code: "failed-precondition", Message: reason}
		}
	case "cancelRaid":
		err = client.CancelRaid(ctx, r.ChannelID)
		var rejected *twitch.RaidRejected
		if errors.As(err, &rejected) {
			return nil, &callable.Error{Code: "failed-precondition", Message: rejected.Message}
		}
		if err == nil && s.store.RaidCancel(ctx, r.ChannelID, time.Now()) != nil {
			zap.L().Warn("failed to record raid cancel")
		}
	}
	var rejected *twitch.ModerationRejected
	if errors.As(err, &rejected) {
		return nil, &callable.Error{Code: "failed-precondition", Message: rejected.Message}
	}
	return nil, err
}
