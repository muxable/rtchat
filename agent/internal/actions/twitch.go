package actions

import (
	"context"
	"errors"
	"time"

	"github.com/muxable/rtchat/agent/internal/clients"
	"github.com/muxable/rtchat/agent/internal/clients/twitch"
	"go.uber.org/zap"
)

func (s *Service) twitchClient(ctx context.Context, token string) (*twitch.Client, error) {
	credentials, err := s.Tokens.Credentials(ctx, "twitch")
	if err != nil {
		return nil, err
	}
	return twitch.New(s.HTTP, credentials.ClientID, token), nil
}

func (s *Service) twitchUser(ctx context.Context, key, value string) (twitch.User, error) {
	token, err := s.Tokens.AppAccessToken(ctx, "twitch")
	if err != nil {
		return twitch.User{}, err
	}
	client, err := s.twitchClient(ctx, token)
	if err != nil {
		return twitch.User{}, err
	}
	return client.User(ctx, key, value)
}
func (s *Service) twitch(ctx context.Context, uid, action string, r request) (any, error) {
	id, err := s.profileID(ctx, uid, "twitch")
	if err != nil {
		return nil, err
	}
	if id == "" {
		if action == "send" {
			return "not signed in with twitch", nil
		}
		return nil, nil
	}
	token, err := s.userToken(ctx, uid, "twitch")
	if err != nil {
		return nil, err
	}
	client, err := s.twitchClient(ctx, token)
	if err != nil {
		return nil, err
	}
	if action == "send" {
		message, err := client.SendMessage(ctx, r.ChannelID, id, r.Message, strip(r.ReplyID, "twitch"))
		var statusErr *clients.HTTPError
		if errors.As(err, &statusErr) && (statusErr.Status == 401 || statusErr.Status == 403) {
			target, err := s.twitchUser(ctx, "id", r.ChannelID)
			if err != nil {
				return nil, err
			}
			if target.Login == "" {
				return nil, nil
			}
			sender, err := s.twitchUser(ctx, "id", id)
			if err != nil {
				return nil, err
			}
			if sender.Login == "" {
				return nil, errors.New("Twitch sender unavailable")
			}
			return nil, s.SendIRC(ctx, token, sender.Login, target.Login, r.Message)
		}
		if err != nil {
			return nil, err
		}
		if message == "" {
			return nil, nil
		}
		return message, nil
	}
	target := r.UserID
	if (action == "ban" || action == "unban" || action == "timeout") && target == "" {
		user, err := s.twitchUser(ctx, "login", r.Username)
		if err != nil {
			return nil, err
		}
		target = user.ID
	}
	var status int
	var result map[string]any
	switch action {
	case "ban", "timeout":
		duration, reason := float64(0), ""
		if action == "timeout" {
			duration, reason = r.Length, r.Reason
		}
		status, result, err = client.Ban(ctx, r.ChannelID, id, target, duration, reason)
	case "unban":
		status, result, err = client.Unban(ctx, r.ChannelID, id, target)
	case "deleteMessage", "clear":
		message := ""
		if action == "deleteMessage" {
			message = strip(r.MessageID, "twitch")
		}
		status, result, err = client.DeleteMessages(ctx, r.ChannelID, id, message)
	case "raid":
		status, result, err = client.StartRaid(ctx, r.From, r.To)
	case "cancelRaid":
		status, result, err = client.CancelRaid(ctx, r.ChannelID)
	}
	// Existing callables return well-formed Twitch API errors as result objects.
	if err != nil && (status < 400 || result == nil) {
		return nil, err
	}
	if action == "raid" && status >= 200 && status < 300 {
		started, parseErr := time.Parse(time.RFC3339Nano, field(first(result, "data"), "created_at"))
		if parseErr == nil {
			user, lookupErr := client.User(ctx, "id", r.To)
			if lookupErr == nil {
				target := map[string]any{"id": r.To, "login": user.Login, "displayName": user.DisplayName}
				if target["displayName"] == "" {
					target["displayName"] = target["login"]
				}
				if err := s.Store.RaidStart(ctx, r.From, target, started); err != nil {
					zap.L().Warn("failed to record raid start")
				}
			}
		}
	}
	if action == "cancelRaid" && status == 204 {
		if err := s.Store.RaidCancel(ctx, r.ChannelID, time.Now()); err != nil {
			zap.L().Warn("failed to record raid cancel")
		}
	}
	if result == nil {
		return nil, nil
	}
	return result, nil
}
