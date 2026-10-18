// Package actions ports the Firebase send, moderation and raid callable handlers.
package actions

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/provider"
)

type Tokens interface {
	AccessToken(context.Context, string, string) (string, error)
	AppAccessToken(context.Context, string) (string, error)
	Credentials(context.Context, string) (provider.Credentials, error)
}
type Store interface {
	Profile(context.Context, string) (map[string]any, error)
	RaidStart(context.Context, string, map[string]any, time.Time) error
	RaidCancel(context.Context, string, time.Time) error
}
type IRCSender func(context.Context, string, string, string, string) error

type Service struct {
	Tokens    Tokens
	Store     Store
	HTTP      *http.Client
	SendIRC   IRCSender
	mu        sync.Mutex
	liveChats map[string]liveChat
}

func NewService(db *firestore.Client, tokens Tokens, client *http.Client) *Service {
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	return &Service{Tokens: tokens, Store: FirestoreStore{DB: db}, HTTP: client, SendIRC: sendIRC}
}

type request struct {
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
func (s *Service) Register(api *callable.Server) {
	for _, name := range []string{"send", "ban", "unban", "timeout", "deleteMessage", "clear", "raid", "cancelRaid"} {
		name := name
		api.Register(name, true, func(ctx context.Context, data json.RawMessage) (any, error) {
			var r request
			if string(data) == "null" || json.Unmarshal(data, &r) != nil {
				return nil, invalid("invalid data")
			}
			if err := validate(name, r); err != nil {
				return nil, err
			}
			switch r.Provider {
			case "twitch":
				return s.twitch(ctx, callable.UID(ctx), name, r)
			case "kick":
				return s.kick(ctx, callable.UID(ctx), name, r)
			case "youtube":
				return s.youtube(ctx, callable.UID(ctx), name, r)
			}
			if name == "raid" || name == "cancelRaid" {
				return nil, nil
			}
			return nil, invalid("invalid provider")
		})
	}
}
func validate(action string, r request) error {
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
	case "deleteMessage":
		if r.ChannelID == "" || r.MessageID == "" {
			return invalid("missing provider, channelId, messageId")
		}
	case "clear", "cancelRaid":
		if r.ChannelID == "" {
			return invalid("missing provider, channelId")
		}
	case "raid":
		if r.From == "" || r.To == "" {
			return invalid("missing provider, fromChannelId, toChannelId")
		}
	}
	return nil
}
func (s *Service) userToken(ctx context.Context, uid, p string) (string, error) {
	token, err := s.Tokens.AccessToken(ctx, uid, p)
	if errors.Is(err, provider.ErrNoToken) || (err == nil && token == "") {
		return "", &callable.Error{Code: "failed-precondition", Message: p + " account not linked"}
	}
	return token, err
}
func object(v any) map[string]any               { m, _ := v.(map[string]any); return m }
func field(m map[string]any, key string) string { v, _ := m[key].(string); return v }
func first(m map[string]any, key string) map[string]any {
	items, _ := m[key].([]any)
	if len(items) == 0 {
		return nil
	}
	return object(items[0])
}
func query(path string, values url.Values) string { return path + "?" + values.Encode() }
func (s *Service) profileID(ctx context.Context, uid, p string) (string, error) {
	profile, err := s.Store.Profile(ctx, uid)
	if err != nil {
		return "", err
	}
	return field(object(profile[p]), "id"), nil
}
func strip(value, p string) string { return strings.TrimPrefix(value, p+":") }
