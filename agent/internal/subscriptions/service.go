// Package subscriptions owns callable channel activation and donation address registration.
package subscriptions

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"regexp"
	"strconv"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

var youtubeID = regexp.MustCompile(`^UC[A-Za-z0-9_-]{22}$`)
var numericID = regexp.MustCompile(`^[0-9]+$`)

type Service struct {
	DB               *firestore.Client
	API              *API
	Enabled          bool
	TwitchSecret     string
	MaticWebhookID   string
	KickChannelLimit int
}

func (s *Service) Register(server *callable.Server) {
	server.Register("subscribe", false, s.Subscribe)
	server.Register("setRealTimeCashAddress", true, s.SetRealTimeCashAddress)
}
func invalid(message string) error {
	return &callable.Error{Code: "invalid-argument", Message: message}
}
func unavailable(message string) error { return &callable.Error{Code: "unavailable", Message: message} }
func profile(data map[string]interface{}, p string) map[string]interface{} {
	value, _ := data[p].(map[string]interface{})
	return value
}
func stringID(value interface{}) string {
	switch value := value.(type) {
	case string:
		return value
	case int64:
		return strconv.FormatInt(value, 10)
	case float64:
		return strconv.FormatFloat(value, 'f', -1, 64)
	}
	return ""
}

func (s *Service) Subscribe(ctx context.Context, data json.RawMessage) (interface{}, error) {
	var input struct {
		Provider  string          `json:"provider"`
		ChannelID json.RawMessage `json:"channelId"`
	}
	if err := json.Unmarshal(data, &input); err != nil {
		return nil, invalid("missing provider, channelId")
	}
	var channel string
	if json.Unmarshal(input.ChannelID, &channel) != nil {
		var number json.Number
		if json.Unmarshal(input.ChannelID, &number) == nil {
			channel = number.String()
		}
	}
	switch input.Provider {
	case "twitch", "kick":
		if !numericID.MatchString(channel) {
			return nil, invalid("invalid channel")
		}
		if input.Provider == "kick" {
			id, err := strconv.ParseUint(channel, 10, 53)
			if err != nil || id == 0 {
				return nil, invalid("invalid channel")
			}
		}
	case "youtube":
		if !youtubeID.MatchString(channel) {
			return nil, invalid("invalid channel")
		}
	default:
		return nil, invalid("invalid provider")
	}
	if !s.Enabled {
		return nil, &callable.Error{Code: "failed-precondition", Message: "subscription migration is not enabled"}
	}
	uid := callable.UID(ctx)
	switch input.Provider {
	case "youtube":
		_, err := s.DB.Collection("assignments").Doc("youtube:"+channel).Set(ctx, map[string]interface{}{"subscribedAt": firestore.ServerTimestamp})
		return channel, err
	case "twitch":
		return s.subscribeTwitch(ctx, uid, channel)
	case "kick":
		err := subscriptionlock.With(ctx, s.DB, "kick:"+channel, func(ctx context.Context) error { return s.ensureKick(ctx, channel) })
		if err != nil {
			return nil, err
		}
		if uid != "" {
			if err = s.touchKickProfile(ctx, uid, channel); err != nil {
				return nil, err
			}
		}
		return channel, nil
	}
	return nil, invalid("invalid provider")
}
func (s *Service) touchKickProfile(ctx context.Context, uid, channel string) error {
	ref := s.DB.Collection("profiles").Doc(uid)
	return s.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		doc, err := tx.Get(ref)
		if status.Code(err) == codes.NotFound {
			return nil
		}
		if err != nil {
			return err
		}
		p := profile(doc.Data(), "kick")
		if p == nil {
			return nil
		}
		if err := tx.Set(ref, map[string]interface{}{"lastActiveAt": firestore.ServerTimestamp}, firestore.MergeAll); err != nil {
			return err
		}
		if stringID(p["id"]) == channel {
			return tx.Set(s.DB.Collection("channels").Doc("kick:"+channel), map[string]interface{}{"lastActiveAt": firestore.ServerTimestamp}, firestore.MergeAll)
		}
		return nil
	})
}
func validAddress(address string) bool {
	if !strings.HasPrefix(address, "0x") || len(address) != 42 {
		return false
	}
	_, err := hex.DecodeString(address[2:])
	return err == nil
}
func (s *Service) SetRealTimeCashAddress(ctx context.Context, data json.RawMessage) (interface{}, error) {
	uid := callable.UID(ctx)
	if uid == "" {
		return nil, &callable.Error{Code: "permission-denied", Message: "missing auth"}
	}
	var input struct {
		Address string `json:"address"`
	}
	if json.Unmarshal(data, &input) != nil || !validAddress(input.Address) {
		return nil, invalid("invalid donation address")
	}
	if s.MaticWebhookID == "" {
		return nil, &callable.Error{Code: "failed-precondition", Message: "donation registration is not configured"}
	}
	// The verified Firebase identity determines the document; caller-supplied uid
	// fields cannot redirect ownership. Normalize for webhook address lookup.
	_, err := s.DB.Collection("realtimecash").Doc(uid).Set(ctx, map[string]interface{}{"address": strings.ToLower(input.Address), "maticWebhookId": s.MaticWebhookID}, firestore.MergeAll)
	return nil, err
}

func isStatus(err error, code int) bool {
	var apiErr *APIError
	return errors.As(err, &apiErr) && apiErr.Status == code
}

// activeCheck permits one-hour caching only for a complete persisted event set.
func activeCheck(data map[string]interface{}, now time.Time) bool {
	checked, _ := data["checkedAt"].(time.Time)
	count := 0
	switch ids := data["subscriptionIds"].(type) {
	case []interface{}:
		count = len(ids)
	case []string:
		count = len(ids)
	}
	return count >= len(KickEvents) && !checked.IsZero() && !checked.After(now) && now.Sub(checked) < time.Hour
}
