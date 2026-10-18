package actions

import (
	"context"
	"encoding/json"
	"math"
	"net/url"
	"strconv"
	"unicode/utf16"

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

// JavaScript slice counts UTF-16 code units, including surrogate pairs.
func truncateReason(reason string) string {
	units := utf16.Encode([]rune(reason))
	if len(units) > 100 {
		units = units[:100]
	}
	return string(utf16.Decode(units))
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
		_, _, err = kick.New(s.HTTP, token).DoJSON(ctx, "DELETE", "/chat/"+url.PathEscape(strip(r.MessageID, "kick")), nil)
		return nil, err
	}
	broadcaster, err := kickID(r.ChannelID)
	if err != nil {
		return nil, err
	}
	if action == "send" {
		body := map[string]any{"content": r.Message, "type": "user", "broadcaster_user_id": broadcaster}
		if r.ReplyID != "" {
			body["reply_to_message_id"] = strip(r.ReplyID, "kick")
		}
		_, _, err = kick.New(s.HTTP, token).DoJSON(ctx, "POST", "/chat", body)
		return nil, err
	}
	target := r.UserID
	if target == "" {
		app, err := s.Tokens.AppAccessToken(ctx, "kick")
		if err != nil {
			return nil, err
		}
		_, result, err := kick.New(s.HTTP, app).DoJSON(ctx, "GET", query("/channels", url.Values{"slug": {r.Username}}), nil)
		if err != nil {
			return nil, err
		}
		raw := first(result, "data")["broadcaster_user_id"]
		if raw == nil {
			return nil, &callable.Error{Code: "not-found", Message: "kick user not found"}
		}
		switch value := raw.(type) {
		case float64:
			target = strconv.FormatFloat(value, 'f', 0, 64)
		case string:
			target = value
		case json.Number:
			target = value.String()
		}
	}
	user, err := kickID(target)
	if err != nil {
		return nil, err
	}
	body := map[string]any{"broadcaster_user_id": broadcaster, "user_id": user}
	method := "POST"
	if action == "unban" {
		method = "DELETE"
	}
	if action == "timeout" {
		body["duration"] = math.Min(10080, math.Max(1, math.Ceil(r.Length/60)))
		if r.Reason != "" {
			body["reason"] = truncateReason(r.Reason)
		}
	}
	_, _, err = kick.New(s.HTTP, token).DoJSON(ctx, method, "/moderation/bans", body)
	return nil, err
}
