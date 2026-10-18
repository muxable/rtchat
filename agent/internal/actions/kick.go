package actions

import (
	"context"
	"strconv"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/clients/kick"
)

func kickID(value string) (int64, error) {
	id, err := strconv.ParseInt(value, 10, 64)
	if err != nil || id <= 0 {
		return 0, invalid("invalid Kick user id")
	}
	return id, nil
}

func (s *Service) kick(ctx context.Context, uid, action string, r request) (any, error) {
	if action == "raid" || action == "cancelRaid" {
		return nil, nil
	}
	if action == "clear" {
		return nil, invalid("invalid provider")
	}
	token, err := s.userToken(ctx, uid, "kick")
	if err != nil {
		return nil, err
	}
	if action == "deleteMessage" {
		err = kick.New(s.HTTP, token).DeleteMessage(ctx, strip(r.MessageID, "kick"))
		return nil, err
	}
	broadcaster, err := kickID(r.ChannelID)
	if err != nil {
		return nil, err
	}
	if action == "send" {
		err = kick.New(s.HTTP, token).SendMessage(ctx, broadcaster, r.Message, strip(r.ReplyID, "kick"))
		return nil, err
	}
	target := r.UserID
	if target == "" {
		app, err := s.Tokens.AppAccessToken(ctx, "kick")
		if err != nil {
			return nil, err
		}
		target, err = kick.New(s.HTTP, app).ChannelUser(ctx, r.Username)
		if err != nil {
			return nil, err
		}
		if target == "" {
			return nil, &callable.Error{Code: "not-found", Message: "kick user not found"}
		}
	}
	user, err := kickID(target)
	if err != nil {
		return nil, err
	}
	client := kick.New(s.HTTP, token)
	if action == "unban" {
		return nil, client.Unban(ctx, broadcaster, user)
	}
	duration, reason := float64(0), ""
	if action == "timeout" {
		duration, reason = r.Length, r.Reason
	}
	return nil, client.Ban(ctx, broadcaster, user, duration, reason)
}
