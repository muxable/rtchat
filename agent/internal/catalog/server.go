// Package catalog serves callable channel discovery and chat catalog APIs.
package catalog

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"time"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/clients"
	"github.com/muxable/rtchat/agent/internal/clients/twitch"
	"github.com/muxable/rtchat/agent/internal/provider"
)

type Tokens interface {
	AccessToken(context.Context, string, string) (string, error)
	AppAccessToken(context.Context, string) (string, error)
}
type Store interface {
	Profile(context.Context, string, string) (map[string]any, error)
	BroadcasterUID(context.Context, string) (string, error)
	CachedYouTube(context.Context, string) ([]map[string]any, bool, error)
	CacheYouTube(context.Context, string, []map[string]any) error
}
type Server struct {
	Tokens         Tokens
	Store          Store
	HTTP           *http.Client
	TwitchClientID string
	YouTubeAPIKey  func(context.Context) (string, error)
	EmoteSets      func(context.Context, string, string) ([]string, error)
}

func (s *Server) Register(api *callable.Server) {
	api.Register("search", false, s.Search)
	api.Register("getEmotes", false, s.Emotes)
	api.Register("getBadges", false, s.Badges)
	api.Register("getViewerList", true, s.ViewerList)
	api.Register("getStatistics", false, s.Statistics)
}
func bad(message string) error { return &callable.Error{Code: "invalid-argument", Message: message} }
func unavailable() error {
	return &callable.Error{Code: "unavailable", Message: "provider temporarily unavailable"}
}

// Keep redacted provider context in logs while returning the public callable error.
func upstreamError(operation string, cause error) error {
	return fmt.Errorf("%s: %w: %w", operation, unavailable(), cause)
}

var numericID = regexp.MustCompile(`^[0-9]{1,30}$`)

func parseChannel(data json.RawMessage, requireChannel bool) (string, string, error) {
	var input struct {
		Provider  string `json:"provider"`
		ChannelID string `json:"channelId"`
	}
	if json.Unmarshal(data, &input) != nil || input.Provider == "" || (requireChannel && input.ChannelID == "") {
		return "", "", bad("missing provider, channelId")
	}
	if len(input.ChannelID) > 128 {
		return "", "", bad("invalid channelId")
	}
	return input.Provider, input.ChannelID, nil
}
func object(v any) map[string]any { m, _ := v.(map[string]any); return m }
func array(v any) []map[string]any {
	out := []map[string]any{}
	items, _ := v.([]any)
	for _, v := range items {
		if m, ok := v.(map[string]any); ok {
			out = append(out, m)
		}
	}
	return out
}
func text(v any) string { s, _ := v.(string); return s }
func first(v any) map[string]any {
	items := array(v)
	if len(items) == 0 {
		return nil
	}
	return items[0]
}
func or(v any, fallback any) any {
	if v == nil {
		return fallback
	}
	if value, ok := v.(string); ok && value == "" {
		return fallback
	}
	return v
}

// Third-party emote catalogs are unauthenticated and may return JSON arrays.
func (s *Server) request(ctx context.Context, endpoint string) (map[string]any, error) {
	var result map[string]any
	err := s.fetch(ctx, endpoint, &result)
	return result, err
}
func (s *Server) fetch(ctx context.Context, endpoint string, out any) error {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	target, err := url.Parse(endpoint)
	if err != nil {
		return unavailable()
	}
	client := clients.Client{HTTP: s.HTTP, BaseURL: target.Scheme + "://" + target.Host}
	if err := client.Get(ctx, target.RequestURI(), out); err != nil {
		return unavailable()
	}
	return nil
}
func (s *Server) twitch(ctx context.Context, path, token string, q url.Values) (map[string]any, error) {
	var result map[string]any
	err := twitch.New(s.HTTP, s.TwitchClientID, token).Get(ctx, "/"+path+"?"+q.Encode(), &result)
	if err != nil {
		var response *clients.HTTPError
		if errors.As(err, &response) && (response.Status == 401 || response.Status == 403) {
			return nil, &callable.Error{Code: "permission-denied", Message: "provider did not authorize this request"}
		}
		return nil, upstreamError("twitch "+path, err)
	}
	return result, nil
}
func (s *Server) userToken(ctx context.Context, uid string) (string, error) {
	if uid == "" {
		return "", provider.ErrNoToken
	}
	token, err := s.Tokens.AccessToken(ctx, uid, "twitch")
	if errors.Is(err, provider.ErrNoToken) {
		return "", provider.ErrNoToken
	}
	if err != nil {
		return "", upstreamError("twitch access token", err)
	}
	return token, nil
}

// JSON decodes provider IDs as float64. fmt.Sprint would use scientific
// notation for large IDs, which does not match provider paths/object keys.
func identifier(value any) string {
	switch value := value.(type) {
	case float64:
		return strconv.FormatFloat(value, 'f', -1, 64)
	case string:
		return value
	default:
		return fmt.Sprint(value)
	}
}
