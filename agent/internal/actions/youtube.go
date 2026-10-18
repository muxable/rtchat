package actions

import (
	"context"
	"errors"
	"io"
	"math"
	"net/http"
	"net/url"
	"regexp"
	"time"
	"unicode/utf8"

	"github.com/muxable/rtchat/agent/internal/callable"

	"github.com/muxable/rtchat/agent/internal/clients/youtube"
)

var channelPattern = regexp.MustCompile(`^UC[A-Za-z0-9_-]{22}$`)
var videoPattern = regexp.MustCompile(`^[A-Za-z0-9_-]{11}$`)
var canonicalPattern = regexp.MustCompile(`<link[^>]+rel="canonical"[^>]+href="https://www\.youtube\.com/watch\?v=([A-Za-z0-9_-]{11})"`)

const quotaMessage = "YouTube's daily quota for sending and moderating chat is used up. It resets at midnight Pacific time."

type liveChat struct {
	id    string
	until time.Time
}

func chatGone(reason string) bool {
	return reason == "liveChatEnded" || reason == "liveChatNotFound" || reason == "liveChatDisabled"
}
func youtubeError(status int, body map[string]any) *callable.Error {
	payload := object(body["error"])
	reason := field(first(payload, "errors"), "reason")
	if reason == "" {
		reason = field(payload, "status")
	}
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
func (s *Service) liveVideo(ctx context.Context, channel string) (string, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", "https://www.youtube.com/channel/"+url.PathEscape(channel)+"/live", nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("Accept-Language", "en")
	resp, err := s.HTTP.Do(req)
	if err != nil {
		return "", errors.New("YouTube discovery failed")
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", nil
	}
	data, err := io.ReadAll(io.LimitReader(resp.Body, 4*1024*1024))
	if err != nil {
		return "", err
	}
	match := canonicalPattern.FindSubmatch(data)
	if len(match) < 2 {
		return "", nil
	}
	return string(match[1]), nil
}
func (s *Service) liveChat(ctx context.Context, uid, token, channel string, video *string) (string, error) {
	s.mu.Lock()
	cached := s.liveChats[channel]
	s.mu.Unlock()
	if video == nil && time.Now().Before(cached.until) {
		return cached.id, nil
	}
	var id string
	if video == nil {
		own, err := s.profileID(ctx, uid, "youtube")
		if err != nil {
			return "", err
		}
		if own == channel {
			_, body, err := s.youtubeRequest(ctx, token, "GET", "/liveBroadcasts?part=snippet&broadcastStatus=active&broadcastType=all&maxResults=50", nil)
			if err != nil {
				return "", err
			}
			items, _ := body["items"].([]any)
			for _, item := range items {
				snippet := object(object(item)["snippet"])
				if field(snippet, "liveChatId") != "" && (field(snippet, "channelId") == "" || field(snippet, "channelId") == channel) {
					id = field(snippet, "liveChatId")
					break
				}
			}
		}
	}
	if id == "" {
		var v string
		var err error
		if video != nil {
			v = *video
		} else {
			v, err = s.liveVideo(ctx, channel)
		}
		if err != nil {
			return "", err
		}
		if v != "" {
			_, body, err := s.youtubeRequest(ctx, token, "GET", query("/videos", url.Values{"part": {"liveStreamingDetails,snippet"}, "id": {v}}), nil)
			if err != nil {
				return "", err
			}
			item := first(body, "items")
			owner := field(object(item["snippet"]), "channelId")
			if owner == "" || owner == channel {
				id = field(object(item["liveStreamingDetails"]), "activeLiveChatId")
			}
		}
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
		_, _, err = s.youtubeRequest(ctx, token, "DELETE", query("/liveChat/messages", url.Values{"id": {id}}), nil)
		return nil, err
	}
	chat, err := s.liveChat(ctx, uid, token, r.ChannelID, r.VideoID)
	if err != nil {
		return nil, err
	}
	snippet := map[string]any{"liveChatId": chat}
	path := "/liveChat/messages?part=snippet"
	if action == "send" {
		snippet["type"] = "textMessageEvent"
		snippet["textMessageDetails"] = map[string]any{"messageText": r.Message}
	} else {
		path = "/liveChat/bans?part=snippet"
		snippet["type"] = "permanent"
		snippet["bannedUserDetails"] = map[string]any{"channelId": r.UserID}
		if action == "timeout" {
			snippet["type"] = "temporary"
			snippet["banDurationSeconds"] = math.Max(1, math.Ceil(r.Length))
		}
	}
	_, _, err = s.youtubeRequest(ctx, token, "POST", path, map[string]any{"snippet": snippet})
	var ce *callable.Error
	if errors.As(err, &ce) {
		details, _ := ce.Details.(map[string]any)
		reason, _ := details["reason"].(string)
		if chatGone(reason) {
			s.mu.Lock()
			delete(s.liveChats, r.ChannelID)
			s.mu.Unlock()
		}
	}
	return nil, err
}

func (s *Service) youtubeRequest(ctx context.Context, token, method, path string, body any) (int, map[string]any, error) {
	status, result, err := youtube.New(s.HTTP, token).DoJSON(ctx, method, path, body)
	if status >= 400 {
		return status, nil, youtubeError(status, result)
	}
	return status, result, err
}
