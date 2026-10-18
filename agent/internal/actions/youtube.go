package actions

import (
	"context"
	"errors"
	"regexp"
	"time"
	"unicode/utf8"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/clients/youtube"
)

var channelPattern = regexp.MustCompile(`^UC[A-Za-z0-9_-]{22}$`)
var videoPattern = regexp.MustCompile(`^[A-Za-z0-9_-]{11}$`)

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
	var detailReason any
	if reason != "" {
		detailReason = reason
	}
	e := &callable.Error{Code: "internal", Message: "YouTube request failed.", Details: map[string]any{"provider": "youtube", "reason": detailReason, "status": status}}
	switch reason {
	case "quotaExceeded", "dailyLimitExceeded":
		e.Code = "resource-exhausted"
		e.Message = quotaMessage
		return e
	case "rateLimitExceeded", "userRateLimitExceeded":
		e.Code = "resource-exhausted"
		e.Message = "YouTube is rate limiting chat actions. Try again in a moment."
		return e
	}
	if chatGone(reason) {
		e.Code = "failed-precondition"
		e.Message = "This YouTube live chat isn't active."
		return e
	}
	switch status {
	case 401:
		e.Code = "unauthenticated"
		e.Message = "YouTube sign-in expired. Sign in with YouTube again."
	case 403:
		e.Code = "permission-denied"
		e.Message = "YouTube didn't allow this action."
	case 404:
		e.Code = "not-found"
		e.Message = "Not found on YouTube."
	default:
		if status >= 500 {
			e.Code = "unavailable"
		}
	}
	return e
}
func (s *Service) liveChat(ctx context.Context, uid, token, channel string, video *string) (string, error) {
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
	id, err := youtube.New(s.HTTP, token).LiveChat(ctx, channel, video, own == channel)
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
func (s *Service) youtube(ctx context.Context, uid, action string, r request) (any, error) {
	if action == "raid" || action == "cancelRaid" {
		return nil, nil
	}
	if action != "send" && action != "ban" && action != "timeout" && action != "deleteMessage" {
		return nil, invalid("invalid provider")
	}
	if r.VideoID != nil && !videoPattern.MatchString(*r.VideoID) {
		return nil, invalid("invalid videoId")
	}
	if action != "deleteMessage" {
		if !channelPattern.MatchString(r.ChannelID) {
			return nil, invalid("invalid channel")
		}
		if action == "send" && utf8.RuneCountInString(r.Message) > 200 {
			return nil, invalid("YouTube messages can be at most 200 characters.")
		}
		if (action == "ban" || action == "timeout") && !channelPattern.MatchString(r.UserID) {
			return nil, invalid("invalid user")
		}
	}
	token, err := s.userToken(ctx, uid, "youtube")
	if err != nil {
		return nil, err
	}
	if action == "deleteMessage" {
		id := strip(r.MessageID, "youtube")
		if id == "" {
			return nil, invalid("invalid message")
		}
		err = youtube.New(s.HTTP, token).DeleteMessage(ctx, id)
		return nil, youtubeError(err)
	}
	chat, err := s.liveChat(ctx, uid, token, r.ChannelID, r.VideoID)
	if err != nil {
		return nil, err
	}
	client := youtube.New(s.HTTP, token)
	if action == "send" {
		err = client.SendMessage(ctx, chat, r.Message)
	} else {
		duration := float64(0)
		if action == "timeout" {
			duration = r.Length
		}
		err = client.Ban(ctx, chat, r.UserID, duration)
	}
	var apiErr *youtube.APIError
	if errors.As(err, &apiErr) && chatGone(apiErr.Reason) {
		s.mu.Lock()
		delete(s.liveChats, r.ChannelID)
		s.mu.Unlock()
	}
	return nil, youtubeError(err)
}
