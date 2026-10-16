package actions

import (
	"context"
	"crypto/tls"
	"errors"
	"net"
	"net/url"
	"strings"
	"time"

	"go.uber.org/zap"
	"golang.org/x/net/websocket"
)

func (s *Service) twitchUser(ctx context.Context, key, value string) (map[string]any, error) {
	token, err := s.Tokens.AppAccessToken(ctx, "twitch")
	if err != nil {
		return nil, err
	}
	_, result, err := s.request(ctx, "twitch", token, "GET", query("/users", url.Values{key: {value}}), nil)
	return first(result, "data"), err
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
	if action == "send" {
		body := map[string]any{"broadcaster_id": r.ChannelID, "sender_id": id, "message": r.Message}
		if r.ReplyID != "" {
			body["reply_parent_message_id"] = strip(r.ReplyID, "twitch")
		}
		status, result, err := s.request(ctx, "twitch", token, "POST", "/chat/messages", body)
		if status == 401 || status == 403 {
			target, err := s.twitchUser(ctx, "id", r.ChannelID)
			if err != nil {
				return nil, err
			}
			if field(target, "login") == "" {
				return nil, nil
			}
			sender, err := s.twitchUser(ctx, "id", id)
			if err != nil {
				return nil, err
			}
			if field(sender, "login") == "" {
				return nil, errors.New("Twitch sender unavailable")
			}
			return nil, s.SendIRC(ctx, token, field(sender, "login"), field(target, "login"), r.Message)
		}
		if err != nil {
			return nil, err
		}
		item := first(result, "data")
		if sent, _ := item["is_sent"].(bool); sent {
			return nil, nil
		}
		message := field(object(item["drop_reason"]), "message")
		if message == "" {
			message = field(result, "message")
		}
		if message == "" {
			message = "failed to send"
		}
		return message, nil
	}
	target := r.UserID
	if (action == "ban" || action == "unban" || action == "timeout") && target == "" {
		user, err := s.twitchUser(ctx, "login", r.Username)
		if err != nil {
			return nil, err
		}
		target = field(user, "id")
	}
	params := url.Values{"broadcaster_id": {r.ChannelID}, "moderator_id": {id}}
	var path, method string
	var body any
	switch action {
	case "ban", "timeout":
		path = "/moderation/bans"
		method = "POST"
		data := map[string]any{"user_id": target}
		if action == "timeout" {
			data["duration"] = r.Length
			data["reason"] = r.Reason
		}
		body = map[string]any{"data": data}
	case "unban":
		path = "/moderation/bans"
		method = "DELETE"
		params.Set("user_id", target)
	case "deleteMessage", "clear":
		path = "/moderation/chat"
		method = "DELETE"
		if action == "deleteMessage" {
			params.Set("message_id", strip(r.MessageID, "twitch"))
		}
	case "raid":
		path = "/raids"
		method = "POST"
		params = url.Values{"from_broadcaster_id": {r.From}, "to_broadcaster_id": {r.To}}
	case "cancelRaid":
		path = "/raids"
		method = "DELETE"
		params = url.Values{"broadcaster_id": {r.ChannelID}}
	}
	status, result, err := s.request(ctx, "twitch", token, method, query(path, params), body)
	if err != nil {
		return nil, err
	}
	if action == "raid" && status >= 200 && status < 300 {
		started, parseErr := time.Parse(time.RFC3339Nano, field(first(result, "data"), "created_at"))
		if parseErr == nil {
			_, users, lookupErr := s.request(ctx, "twitch", token, "GET", query("/users", url.Values{"id": {r.To}}), nil)
			if lookupErr == nil {
				user := first(users, "data")
				target := map[string]any{"id": r.To, "login": field(user, "login"), "displayName": field(user, "display_name")}
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

// Keep the legacy fallback until clients capable of prompting for reauthorization
// have rolled out (#1479). A successful write cannot guarantee IRC acceptance.
func sendIRC(ctx context.Context, token, login, channel, message string) error {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	dialer := tls.Dialer{NetDialer: &net.Dialer{Timeout: 10 * time.Second}}
	conn, err := dialer.DialContext(ctx, "tcp", "irc-ws.chat.twitch.tv:443")
	if err != nil {
		return errors.New("IRC connection failed")
	}
	defer conn.Close()
	if deadline, ok := ctx.Deadline(); ok {
		conn.SetDeadline(deadline)
	}
	config, err := websocket.NewConfig("wss://irc-ws.chat.twitch.tv:443", "https://chat.rtirl.com")
	if err != nil {
		return err
	}
	ws, err := websocket.NewClient(config, conn)
	if err != nil {
		return errors.New("IRC handshake failed")
	}
	defer ws.Close()
	// The fallback must not turn a multiline message into extra IRC commands.
	message = strings.NewReplacer("\r", " ", "\n", " ").Replace(message)
	for _, line := range []string{"CAP REQ :twitch.tv/commands", "PASS oauth:" + token, "NICK " + login, "PRIVMSG #" + channel + " :" + message} {
		if err := websocket.Message.Send(ws, line); err != nil {
			return errors.New("IRC send failed")
		}
	}
	return nil
}
