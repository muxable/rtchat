package oauthhttp

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
)

var errNoChannel = errors.New("no YouTube channel")

func (s *Server) get(ctx context.Context, endpoint, token, id string) (map[string]any, error) {
	req, _ := http.NewRequestWithContext(ctx, "GET", endpoint, nil)
	req.Header.Set("Authorization", "Bearer "+token)
	if id != "" {
		req.Header.Set("Client-Id", id)
	}
	var result map[string]any
	err := s.json(req, &result)
	return result, err
}
func first(result map[string]any, key string) map[string]any {
	items, _ := result[key].([]any)
	if len(items) == 0 {
		return nil
	}
	v, _ := items[0].(map[string]any)
	return v
}
func object(v any) map[string]any { m, _ := v.(map[string]any); return m }
func str(v any) string {
	if v == nil {
		return ""
	}
	if number, ok := v.(float64); ok {
		return strconv.FormatFloat(number, 'f', -1, 64)
	}
	return fmt.Sprint(v)
}
func (s *Server) profile(ctx context.Context, name, id, token string) (map[string]any, error) {
	switch name {
	case "twitch":
		data, e := s.get(ctx, "https://api.twitch.tv/helix/users", token, id)
		if e != nil {
			return nil, e
		}
		u := first(data, "data")
		if str(u["id"]) == "" {
			return nil, errors.New("missing user")
		}
		return map[string]any{"id": u["id"], "displayName": u["display_name"], "login": u["login"], "profilePictureUrl": u["profile_image_url"], "email": u["email"]}, nil
	case "kick":
		data, e := s.get(ctx, "https://api.kick.com/public/v1/users", token, "")
		if e != nil {
			return nil, e
		}
		u := first(data, "data")
		if str(u["user_id"]) == "" {
			return nil, errors.New("missing user")
		}
		channels, e := s.get(ctx, "https://api.kick.com/public/v1/channels", token, "")
		if e != nil {
			return nil, e
		}
		channel := first(channels, "data")
		slug := str(channel["slug"])
		if slug == "" {
			slug = strings.ToLower(str(u["name"]))
		}
		return map[string]any{"id": str(u["user_id"]), "slug": slug, "displayName": u["name"], "profilePictureUrl": u["profile_picture"], "email": u["email"]}, nil
	case "youtube":
		data, e := s.get(ctx, "https://www.googleapis.com/youtube/v3/channels?part=snippet&mine=true", token, "")
		if e != nil {
			return nil, e
		}
		channel := first(data, "items")
		if str(channel["id"]) == "" {
			return nil, errNoChannel
		}
		snippet := object(channel["snippet"])
		thumbs := object(snippet["thumbnails"])
		picture := object(thumbs["medium"])["url"]
		if picture == nil {
			picture = object(thumbs["default"])["url"]
		}
		display := str(snippet["title"])
		if display == "" {
			display = str(channel["id"])
		}
		login := str(snippet["customUrl"])
		if login == "" {
			login = str(channel["id"])
		}
		return map[string]any{"id": channel["id"], "displayName": display, "login": login, "profilePictureUrl": picture, "email": nil}, nil
	}
	return nil, errors.New("unknown provider")
}
