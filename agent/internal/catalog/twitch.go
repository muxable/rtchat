package catalog

import (
	"context"
	"encoding/json"
	"net/url"
	"sort"
	"strings"

	"github.com/muxable/rtchat/agent/internal/callable"
)

func (s *Server) Badges(ctx context.Context, data json.RawMessage) (any, error) {
	p, channel, err := parseChannel(data, false)
	if err != nil {
		return nil, err
	}
	if p != "twitch" {
		return []any{}, nil
	}
	if channel != "" && !numericID.MatchString(channel) {
		return nil, bad("invalid channelId")
	}
	token, err := s.Tokens.AppAccessToken(ctx, "twitch")
	if err != nil {
		return nil, unavailable()
	}
	path := "chat/badges/global"
	q := url.Values{}
	if channel != "" {
		path = "chat/badges"
		q.Set("broadcaster_id", channel)
	}
	res, err := s.twitch(ctx, path, token, q)
	if err != nil {
		return nil, err
	}
	return array(res["data"]), nil
}
func (s *Server) Statistics(ctx context.Context, data json.RawMessage) (any, error) {
	p, channel, err := parseChannel(data, true)
	if err != nil {
		return nil, err
	}
	if p != "twitch" || !numericID.MatchString(channel) {
		return nil, bad("invalid provider or channelId")
	}
	token, err := s.Tokens.AppAccessToken(ctx, "twitch")
	if err != nil {
		return nil, unavailable()
	}
	streamData, err := s.twitch(ctx, "streams", token, url.Values{"user_id": {channel}, "first": {"1"}})
	if err != nil {
		return nil, err
	}
	followers, err := s.twitch(ctx, "channels/followers", token, url.Values{"broadcaster_id": {channel}, "first": {"1"}})
	if err != nil {
		return nil, err
	}
	channels, err := s.twitch(ctx, "channels", token, url.Values{"broadcaster_id": {channel}})
	if err != nil {
		return nil, err
	}
	stream := first(streamData["data"])
	channelData := first(channels["data"])
	if channelData == nil {
		return nil, unavailable()
	}
	viewers := any(0)
	if stream != nil {
		viewers = stream["viewer_count"]
	}
	return map[string]any{
		"isOnline":  stream != nil,
		"viewers":   viewers,
		"followers": followers["total"],
		"language":  channelData["broadcaster_language"],
	}, nil
}
func (s *Server) ViewerList(ctx context.Context, data json.RawMessage) (any, error) {
	uid := callable.UID(ctx)
	if uid == "" {
		return nil, &callable.Error{Code: "unauthenticated", Message: "must be authenticated"}
	}
	var raw string
	if json.Unmarshal(data, &raw) != nil {
		return nil, bad("invalid channel")
	}
	parts := strings.Split(raw, ":")
	if len(parts) != 2 || parts[0] != "twitch" || !numericID.MatchString(parts[1]) {
		return nil, bad("invalid channel")
	}
	channel := parts[1]
	// Preserve broadcaster-first authorization, falling back to the requesting user.
	// Twitch still enforces moderator scope/relationship; no app token is used.
	broadcaster, err := s.Store.BroadcasterUID(ctx, channel)
	if err != nil {
		return nil, unavailable()
	}
	if broadcaster != "" {
		if viewers, err := s.chatters(ctx, channel, broadcaster); err == nil {
			return viewers, nil
		}
	}
	return s.chatters(ctx, channel, uid)
}
func (s *Server) chatters(ctx context.Context, channel, uid string) (any, error) {
	token, err := s.userToken(ctx, uid)
	if err != nil {
		return nil, &callable.Error{Code: "permission-denied", Message: "Twitch account authorization required"}
	}
	profile, err := s.Store.Profile(ctx, uid, "twitch")
	if err != nil {
		return nil, unavailable()
	}
	moderator := text(profile["id"])
	if !numericID.MatchString(moderator) {
		return nil, &callable.Error{Code: "permission-denied", Message: "Twitch account authorization required"}
	}
	all := []map[string]any{}
	after := ""
	seen := map[string]bool{}
	for pages := 0; pages < 100; pages++ {
		q := url.Values{"broadcaster_id": {channel}, "moderator_id": {moderator}, "first": {"1000"}}
		if after != "" {
			q.Set("after", after)
		}
		res, err := s.twitch(ctx, "chat/chatters", token, q)
		if err != nil {
			return nil, err
		}
		all = append(all, array(res["data"])...)
		after = text(object(res["pagination"])["cursor"])
		if after == "" {
			break
		}
		if seen[after] || pages == 99 {
			return nil, unavailable()
		}
		seen[after] = true
	}
	broadcaster := []map[string]any{}
	for _, u := range all {
		if text(u["user_id"]) == channel {
			broadcaster = append(broadcaster, u)
		}
	}
	mods, _ := s.roles(ctx, "moderation/moderators", channel, token, all)
	vips, _ := s.roles(ctx, "channels/vips", channel, token, all)
	viewers := []map[string]any{}
	exclude := map[string]bool{}
	for _, group := range [][]map[string]any{broadcaster, mods, vips} {
		for _, u := range group {
			exclude[text(u["user_id"])] = true
		}
	}
	for _, u := range all {
		if !exclude[text(u["user_id"])] {
			viewers = append(viewers, u)
		}
	}
	result := map[string]any{}
	for name, users := range map[string][]map[string]any{"broadcaster": broadcaster, "moderators": mods, "vips": vips, "viewers": viewers} {
		if users == nil {
			users = []map[string]any{}
		}
		sort.SliceStable(users, func(i, j int) bool {
			return strings.ToLower(text(users[i]["user_name"])) < strings.ToLower(text(users[j]["user_name"]))
		})
		names := []string{}
		for _, u := range users {
			names = append(names, text(u["user_name"]))
		}
		result[name] = names
		result[name+"Data"] = users
	}
	return result, nil
}
func (s *Server) roles(ctx context.Context, path, channel, token string, users []map[string]any) ([]map[string]any, error) {
	result := []map[string]any{}
	for i := 0; i < len(users); i += 100 {
		q := url.Values{"broadcaster_id": {channel}, "first": {"100"}}
		end := i + 100
		if end > len(users) {
			end = len(users)
		}
		for _, u := range users[i:end] {
			q.Add("user_id", text(u["user_id"]))
		}
		res, err := s.twitch(ctx, path, token, q)
		if err != nil {
			return []map[string]any{}, err
		}
		result = append(result, array(res["data"])...)
	}
	return result, nil
}
