package main

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

func (s *chatRoutes) kick(ctx context.Context, token, action string, r chatRequest) (any, error) {
	client := kick.New(s.httpClient, token)
	var err error
	if action == "deleteMessage" {
		err = client.DeleteMessage(ctx, r.MessageID)
		return nil, err
	}
	broadcaster, err := kickID(r.ChannelID)
	if err != nil {
		return nil, err
	}
	if action == "send" {
		err = client.SendMessage(ctx, broadcaster, r.Message, r.ReplyID)
		return nil, err
	}
	target := r.UserID
	if target == "" {
		app, err := s.tokens.AppAccessToken(ctx, "kick")
		if err != nil {
			return nil, err
		}
		target, err = kick.New(s.httpClient, app).ChannelUser(ctx, r.Username)
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
	if action == "unban" {
		return nil, client.Unban(ctx, broadcaster, user)
	}
	if action == "timeout" {
		return nil, client.Ban(ctx, broadcaster, user, r.Length, r.Reason)
	}
	return nil, client.Ban(ctx, broadcaster, user, 0, "")
}
