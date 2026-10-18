package main

import (
	"context"
	"errors"
	"time"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/clients/youtube"
)

const quotaMessage = "YouTube's daily quota for sending and moderating chat is used up. It resets at midnight Pacific time."

type liveChat struct {
	id    string
	until time.Time
}

func chatGone(reason string) bool {
	return reason == "liveChatEnded" || reason == "liveChatNotFound" || reason == "liveChatDisabled"
}
func youtubeError(err error) error {
	var apiErr *youtube.APIError
	if !errors.As(err, &apiErr) {
		return err
	}
	status, reason := apiErr.Status, apiErr.Reason
	code, message := "internal", "YouTube request failed."
	switch {
	case reason == "quotaExceeded" || reason == "dailyLimitExceeded":
		code, message = "resource-exhausted", quotaMessage
	case reason == "rateLimitExceeded" || reason == "userRateLimitExceeded":
		code, message = "resource-exhausted", "YouTube is rate limiting chat actions. Try again in a moment."
	case chatGone(reason):
		code, message = "failed-precondition", "This YouTube live chat isn't active."
	case status == 401:
		code, message = "unauthenticated", "YouTube sign-in expired. Sign in with YouTube again."
	case status == 403:
		code, message = "permission-denied", "YouTube didn't allow this action."
	case status == 404:
		code, message = "not-found", "Not found on YouTube."
	case status >= 500:
		code = "unavailable"
	}
	return &callable.Error{Code: code, Message: message, Details: map[string]any{"provider": "youtube", "reason": reason, "status": status}}
}

func (s *chatRoutes) liveChat(ctx context.Context, uid, token, channel string, video *string) (string, error) {
	s.mu.Lock()
	cached := s.liveChats[channel]
	s.mu.Unlock()
	if video == nil && time.Now().Before(cached.until) {
		return cached.id, nil
	}
	var own string
	if video == nil {
		var err error
		own, err = s.profileID(ctx, uid, "youtube")
		if err != nil {
			return "", err
		}
	}
	id, err := youtube.New(s.httpClient, token).LiveChat(ctx, channel, video, own == channel)
	if err != nil {
		return "", youtubeError(err)
	}
	if id == "" {
		return "", &callable.Error{Code: "failed-precondition", Message: "This YouTube channel isn't live.", Details: map[string]any{"provider": "youtube", "reason": "notLive"}}
	}
	s.mu.Lock()
	if s.liveChats == nil {
		s.liveChats = map[string]liveChat{}
	}
	s.liveChats[channel] = liveChat{id: id, until: time.Now().Add(5 * time.Minute)}
	s.mu.Unlock()
	return id, nil
}
func (s *chatRoutes) youtube(ctx context.Context, uid, token, action string, r chatRequest) (any, error) {
	client := youtube.New(s.httpClient, token)
	if action == "deleteMessage" {
		id := r.MessageID
		if id == "" {
			return nil, invalid("invalid message")
		}
		err := client.DeleteMessage(ctx, id)
		return nil, youtubeError(err)
	}
	chat, err := s.liveChat(ctx, uid, token, r.ChannelID, r.VideoID)
	if err != nil {
		return nil, err
	}
	if action == "send" {
		err = client.SendMessage(ctx, chat, r.Message)
	} else if action == "timeout" {
		err = client.Ban(ctx, chat, r.UserID, r.Length)
	} else {
		err = client.Ban(ctx, chat, r.UserID, 0)
	}
	var apiErr *youtube.APIError
	if errors.As(err, &apiErr) && chatGone(apiErr.Reason) {
		s.mu.Lock()
		delete(s.liveChats, r.ChannelID)
		s.mu.Unlock()
	}
	return nil, youtubeError(err)
}
