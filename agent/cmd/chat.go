package main

import (
	"context"
	"encoding/json"
	"errors"
	"math"
	"net/http"
	"regexp"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/clients"
	"github.com/muxable/rtchat/agent/internal/clients/twitch"
	"github.com/muxable/rtchat/agent/internal/provider"
)

type chatTokens interface {
	AccessToken(context.Context, string, string) (string, error)
	AppAccessToken(context.Context, string) (string, error)
	Credentials(context.Context, string) (provider.Credentials, error)
}
type chatStore interface {
	Profile(context.Context, string) (map[string]any, error)
	RaidStart(context.Context, string, twitch.User, time.Time) error
	RaidCancel(context.Context, string, time.Time) error
}

type chatRoutes struct {
	tokens     chatTokens
	store      chatStore
	httpClient *http.Client
	sendIRC    func(context.Context, string, string, string, string) error
	mu         sync.Mutex
	liveChats  map[chatCacheKey]liveChat
}

var channelPattern = regexp.MustCompile(`^UC[A-Za-z0-9_-]{22}$`)
var videoPattern = regexp.MustCompile(`^[A-Za-z0-9_-]{11}$`)

type chatRequest struct {
	Provider  string  `json:"provider"`
	ChannelID string  `json:"channelId"`
	Message   string  `json:"message"`
	MessageID string  `json:"messageId"`
	Username  string  `json:"username"`
	UserID    string  `json:"userId"`
	ReplyID   string  `json:"replyToMessageId"`
	VideoID   *string `json:"videoId"`
	Length    float64 `json:"length"`
	Reason    string  `json:"reason"`
	From      string  `json:"fromChannelId"`
	To        string  `json:"toChannelId"`
}

func invalid(message string) error {
	return &callable.Error{Code: "invalid-argument", Message: message}
}
func registerChat(api *callable.Server, s *chatRoutes) {
	if s.httpClient == nil {
		s.httpClient = &http.Client{Timeout: 10 * time.Second}
	}
	if s.sendIRC == nil {
		s.sendIRC = twitch.SendIRC
	}
	for _, name := range []string{"send", "ban", "unban", "timeout", "deleteMessage", "clear", "raid", "cancelRaid", "shoutout"} {
		name := name
		api.Register(name, true, func(ctx context.Context, data json.RawMessage) (any, error) {
			var r chatRequest
			if string(data) == "null" || json.Unmarshal(data, &r) != nil {
				return nil, invalid("invalid data")
			}
			r.MessageID = strings.TrimPrefix(r.MessageID, r.Provider+":")
			r.ReplyID = strings.TrimPrefix(r.ReplyID, r.Provider+":")
			if err := r.validate(name); err != nil {
				return nil, err
			}
			if (name == "raid" || name == "cancelRaid") && r.Provider != "twitch" {
				return nil, nil
			}
			token, err := s.tokens.AccessToken(ctx, callable.UID(ctx), r.Provider)
			if errors.Is(err, provider.ErrNoToken) || (err == nil && token == "") {
				return nil, &callable.Error{Code: "failed-precondition", Message: r.Provider + " account not linked"}
			}
			if err != nil {
				return nil, err
			}
			var result any
			switch r.Provider {
			case "twitch":
				result, err = s.twitch(ctx, callable.UID(ctx), token, name, r)
			case "kick":
				result, err = s.kick(ctx, token, name, r)
			case "youtube":
				result, err = s.youtube(ctx, callable.UID(ctx), token, name, r)
			default:
				return nil, invalid("invalid provider")
			}
			// A provider rate limit is the user acting too fast, not a server error.
			var status *clients.HTTPError
			if errors.As(err, &status) && status.Status == http.StatusTooManyRequests {
				return nil, &callable.Error{Code: "resource-exhausted", Message: "too many requests, try again shortly"}
			}
			return result, err
		})
	}
}
func (r chatRequest) validate(action string) error {
	if r.Provider == "" {
		return invalid("missing provider")
	}
	switch action {
	case "send":
		if r.ChannelID == "" || r.Message == "" {
			return invalid("missing provider, channelId, message")
		}
	case "ban", "unban", "timeout":
		if r.ChannelID == "" || (r.Username == "" && r.UserID == "") {
			return invalid("missing provider, channelId, username")
		}
		if action == "timeout" && (r.Length == 0 || r.Reason == "") {
			return invalid("missing provider, channelId, username, length, reason")
		}
		// Twitch's documented timeout bounds; checked here so that a 400 from
		// Twitch can only be a refusal of the moderation action.
		if action == "timeout" && r.Provider == "twitch" && (r.Length < 1 || r.Length > 1209600 || r.Length != math.Trunc(r.Length) || utf8.RuneCountInString(r.Reason) > 500) {
			return invalid("invalid length, reason")
		}
	case "deleteMessage":
		if r.ChannelID == "" || r.MessageID == "" {
			return invalid("missing provider, channelId, messageId")
		}
	case "clear", "cancelRaid":
		if r.ChannelID == "" {
			return invalid("missing provider, channelId")
		}
	case "raid", "shoutout":
		if r.From == "" || r.To == "" {
			return invalid("missing provider, fromChannelId, toChannelId")
		}
		if action == "shoutout" && r.Provider != "twitch" {
			return invalid("invalid provider")
		}
	}
	if action != "raid" && action != "cancelRaid" {
		switch r.Provider {
		case "twitch":
		case "kick":
			if action == "clear" {
				return invalid("invalid provider")
			}
		case "youtube":
			if action != "send" && action != "ban" && action != "timeout" && action != "deleteMessage" {
				return invalid("invalid provider")
			}
			if r.VideoID != nil && !videoPattern.MatchString(*r.VideoID) {
				return invalid("invalid videoId")
			}
			if action != "deleteMessage" {
				if !channelPattern.MatchString(r.ChannelID) {
					return invalid("invalid channel")
				}
				if action == "send" && utf8.RuneCountInString(r.Message) > 200 {
					return invalid("YouTube messages can be at most 200 characters.")
				}
				if (action == "ban" || action == "timeout") && !channelPattern.MatchString(r.UserID) {
					return invalid("invalid user")
				}
			}

		default:
			return invalid("invalid provider")
		}
	}
	return nil
}
func object(v any) map[string]any               { m, _ := v.(map[string]any); return m }
func field(m map[string]any, key string) string { v, _ := m[key].(string); return v }
func (s *chatRoutes) profileID(ctx context.Context, uid, p string) (string, error) {
	profile, err := s.store.Profile(ctx, uid)
	if err != nil {
		return "", err
	}
	return field(object(profile[p]), "id"), nil
}
