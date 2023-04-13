package handler

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strings"
	"sync"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/gempir/go-twitch-irc/v3"
	"github.com/gorilla/websocket"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/auth"
	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type TwitchAgent struct {
	Firestore              *firestore.Client
	ClientID, ClientSecret string
}

var (
	errReconnect = errors.New("reconnect")
)

func (h *TwitchAgent) bindRaidClient(ctx context.Context, channelID, userID string) error {
	ws, _, err := websocket.DefaultDialer.Dial("wss://pubsub-edge.twitch.tv", nil)
	if err != nil {
		return err
	}
	defer ws.Close()

	// start a ping loop
	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			case <-time.After(30 * time.Second):
				if err := ws.WriteJSON(map[string]interface{}{"type": "PING"}); err != nil {
					zap.L().Error("failed to send ping", zap.Error(err))
					return
				}
			}
		}
	}()

	authProvider, err := auth.NewFirestoreTwitchTokenSource(h.Firestore, h.ClientID, h.ClientSecret, userID)
	if err != nil {
		return err
	}

	token, err := authProvider.Token()
	if err != nil {
		return err
	}

	// listen on raid events
	if err := ws.WriteJSON(map[string]interface{}{
		"type": "LISTEN",
		"data": map[string]interface{}{
			"topics":     []string{fmt.Sprintf("raid.%s", channelID)},
			"auth_token": fmt.Sprintf("oauth:%s", token.AccessToken),
		},
	}); err != nil {
		return err
	}
	zap.L().Info("subscribed to raid events", zap.String("channelId", channelID))
	go func() {
		<-ctx.Done()
		if err := ws.Close(); err != nil {
			zap.L().Error("failed to close websocket", zap.Error(err))
		}
	}()

	// listen for messages
	for {
		var message map[string]interface{}
		if err := ws.ReadJSON(&message); err != nil {
			return err
		}
		if message["type"] == "RESPONSE" && message["error"] != "" {
			return errors.New(message["error"].(string))
		}
		if message["type"] == "MESSAGE" {
			data := message["data"].(map[string]interface{})
			if data["topic"] == fmt.Sprintf("raid.%s", channelID) {
				// parse the message
				var raid struct {
					Type string                 `json:"type"`
					Raid map[string]interface{} `json:"raid"`
				}
				if err := json.Unmarshal([]byte(data["message"].(string)), &raid); err != nil {
					zap.L().Error("failed to unmarshal raid message", zap.Error(err))
					continue
				}
				if !strings.HasPrefix(raid.Type, "raid") {
					zap.L().Warn("unknown raid type", zap.String("type", raid.Type))
					continue
				}

				id := fmt.Sprintf("%s-%s", raid.Type, raid.Raid["id"].(string))
				zap.L().Info("received raid", zap.String("id", id), zap.Any("raid", raid.Raid))
				// write this event to firestore
				go h.write(fmt.Sprintf("twitch:%s", channelID), id, map[string]interface{}{
					"raid":      raid.Raid,
					"type":      raid.Type,
					"timestamp": firestore.ServerTimestamp,
					"expiresAt": time.Now().Add(time.Hour * 24 * 7 * 2),
				})
			}
		}
		if message["type"] == "RECONNECT" {
			return errReconnect
		}
	}
}

func joinWithTimeout(client *twitch.Client, channel string, timeout time.Duration) error {
	// connect to the chat
	success := make(chan bool, 1)
	once := &sync.Once{}
	client.OnConnect(func() {
		// apparently this can be called multiple times
		once.Do(func() {
			close(success)
		})
	})
	client.Join(channel)

	go func() {
		if err := client.Connect(); err != nil {
			if !errors.Is(err, twitch.ErrClientDisconnected) {
				zap.L().Error("failed to connect to chat", zap.Error(err))
			}
		}
	}()

	// wait for success signal or timeout
	select {
	case <-success:
		return nil
	case <-time.After(5 * time.Second):
		if err := client.Disconnect(); err != nil {
			if !errors.Is(err, twitch.ErrConnectionIsNotOpen) {
				zap.L().Error("failed to disconnect from chat", zap.Error(err))
			}
		}
		return errors.New("timeout")
	}
}

func (h *TwitchAgent) metadata(channelID string, data interface{}) {
	if _, err := h.Firestore.Collection("channels").Doc(channelID).Set(context.Background(), data, firestore.MergeAll); err != nil {
		zap.L().Error("failed to update channel metadata", zap.Error(err), zap.String("channelId", channelID), zap.Any("data", data))
	}
}

func (h *TwitchAgent) write(channelID, messageID string, data interface{}) {
	if _, err := h.Firestore.Collection("channels").Doc(channelID).Collection("messages").Doc(messageID).Create(context.Background(), data); err != nil && status.Code(err) != codes.AlreadyExists {
		zap.L().Error("failed to write message to firestore", zap.Error(err), zap.String("channelId", channelID), zap.String("messageId", messageID), zap.Any("data", data))
	}
}

func (h *TwitchAgent) bindEvents(client *twitch.Client) {
	client.OnNoticeMessage(func(message twitch.NoticeMessage) {
		if message.Channel == "*" {
			return
		}
		userID, err := auth.TwitchUserIDFromUsername(h.Firestore, h.ClientID, h.ClientSecret, message.Channel)
		if err != nil {
			return
		}
		channelID := fmt.Sprintf("twitch:%s", userID)
		switch message.MsgID {
		case "r9k_on", "already_r9k_on":
			go h.metadata(channelID, map[string]interface{}{
				"isR9k": true,
			})
		case "r9k_off", "already_r9k_off":
			go h.metadata(channelID, map[string]interface{}{
				"isR9k": false,
			})
		case "slow_on", "already_slow_on":
			go h.metadata(channelID, map[string]interface{}{
				"isSlowMode": true,
			})
		case "slow_off", "already_slow_off":
			go h.metadata(channelID, map[string]interface{}{
				"isSlowMode": false,
			})
		case "subs_on", "already_subs_on":
			go h.metadata(channelID, map[string]interface{}{
				"isSubsOnly": true,
			})
		case "subs_off", "already_subs_off":
			go h.metadata(channelID, map[string]interface{}{
				"isSubsOnly": false,
			})
		case "followers_on", "already_followers_on":
			go h.metadata(channelID, map[string]interface{}{
				"isFollowersOnly": true,
			})
		case "followers_off", "already_followers_off":
			go h.metadata(channelID, map[string]interface{}{
				"isFollowersOnly": false,
			})
		case "emote_only_on", "already_emote_only_on":
			go h.metadata(channelID, map[string]interface{}{
				"isEmoteOnly": true,
			})
		case "emote_only_off", "already_emote_only_off":
			go h.metadata(channelID, map[string]interface{}{
				"isEmoteOnly": false,
			})
		}
	})

	client.OnUserNoticeMessage(func(message twitch.UserNoticeMessage) {
		zap.L().Info("user notice", zap.String("message", message.Raw))
		switch message.MsgID {
		case "announcement":
			channelID := fmt.Sprintf("twitch:%s", message.RoomID)
			data := map[string]interface{}{
				"channelId": channelID,
				"annotations": map[string]interface{}{
					"isAction":           false,
					"isFirstTimeChatter": false,
					"announcement": map[string]interface{}{
						"color": message.MsgParams["msg-param-color"],
					},
				},
				"author": map[string]interface{}{
					"displayName": message.User.DisplayName,
					"userId":      message.User.ID,
					"color":       message.User.Color,
				},
				"message":   message.Message,
				"timestamp": message.Time,
				"tags": map[string]interface{}{
					"user-id":      message.User.ID,
					"room-id":      message.RoomID,
					"display-name": message.User.DisplayName,
					"color":        message.User.Color,
					"username":     message.User.Name,
					"badges": map[string]bool{
						"vip":       message.User.Badges["vip"] > 0,
						"moderator": message.User.Badges["moderator"] > 0,
					},
					"emotes-raw": message.Tags["emotes"],
				},
				"type":      "message",
				"expiresAt": time.Now().Add(time.Hour * 24 * 7 * 2),
			}
			go h.write(channelID, fmt.Sprintf("twitch:%s", message.ID), data)
		}
	})

	// configure handlers
	client.OnClearChatMessage(func(message twitch.ClearChatMessage) {
		// handle clear chat message
		channelID := fmt.Sprintf("twitch:%s", message.RoomID)
		if message.TargetUserID != "" || message.TargetUsername != "" {
			data := map[string]interface{}{
				"channelId":    channelID,
				"targetUserId": message.TargetUserID,
				"timestamp":    message.Time,
				"type":         "userclear",
				"expiresAt":    time.Now().Add(time.Hour * 24 * 7 * 2),
			}
			go h.write(channelID, fmt.Sprintf("twitch:userclear-%s", message.Time.Format(time.RFC3339)), data)
		} else {
			data := map[string]interface{}{
				"channelId": channelID,
				"timestamp": message.Time,
				"type":      "clear",
				"expiresAt": time.Now().Add(time.Hour * 24 * 7 * 2),
			}
			go h.write(channelID, fmt.Sprintf("twitch:clear-%s", message.Time.Format(time.RFC3339)), data)
		}
	})

	client.OnClearMessage(func(message twitch.ClearMessage) {
		// handle deleted message
		userID, err := auth.TwitchUserIDFromUsername(h.Firestore, h.ClientID, h.ClientSecret, message.Channel)
		if err != nil {
			zap.L().Error("failed to get twitch user id", zap.Error(err), zap.String("channel", message.Channel))
			return
		}
		channelID := fmt.Sprintf("twitch:%s", userID)
		data := map[string]interface{}{
			"channelId": channelID,
			"timestamp": firestore.ServerTimestamp,
			"type":      "messagedeleted",
			"messageId": fmt.Sprintf("twitch:%s", message.TargetMsgID),
			"expiresAt": time.Now().Add(time.Hour * 24 * 7 * 2),
		}
		go h.write(channelID, fmt.Sprintf("twitch:x-%s", message.TargetMsgID), data)
	})

	client.OnPrivateMessage(func(message twitch.PrivateMessage) {
		// handle private message
		channelID := fmt.Sprintf("twitch:%s", message.RoomID)
		var reply map[string]interface{}
		if message.Reply != nil {
			reply = map[string]interface{}{
				"messageId":   fmt.Sprintf("twitch:%s", message.Reply.ParentMsgID),
				"displayName": message.Reply.ParentDisplayName,
				"userLogin":   message.Reply.ParentUserLogin,
				"userId":      message.Reply.ParentUserID,
				"message":     message.Reply.ParentMsgBody,
			}
		}
		data := map[string]interface{}{
			"channelId": channelID,
			"annotations": map[string]interface{}{
				"isAction":           message.Action,
				"isFirstTimeChatter": message.FirstMessage,
			},
			"author": map[string]interface{}{
				"displayName": message.User.DisplayName,
				"userId":      message.User.ID,
				"color":       message.User.Color,
			},
			"message":   message.Message,
			"reply":     reply,
			"timestamp": message.Time,
			"tags": map[string]interface{}{
				"user-id":      message.User.ID,
				"room-id":      message.RoomID,
				"display-name": message.User.DisplayName,
				"color":        message.User.Color,
				"username":     message.User.Name,
				"badges": map[string]bool{
					"vip":       message.User.Badges["vip"] > 0,
					"moderator": message.User.Badges["moderator"] > 0,
				},
				"emotes-raw": message.Tags["emotes"],
				"badges-raw": message.Tags["badges"],
			},
			"type":      "message",
			"expiresAt": time.Now().Add(time.Hour * 24 * 7 * 2),
		}
		zap.L().Info("adding message", zap.String("content", message.Message), zap.String("channelId", channelID), zap.String("channel", message.Channel))
		go h.write(channelID, fmt.Sprintf("twitch:%s", message.ID), data)
	})

	client.OnReconnectMessage(func(message twitch.ReconnectMessage) {
		if err := client.Connect(); err != nil {
			zap.L().Error("failed to reconnect", zap.Error(err))
		}
	})
}

type AuthenticatedTwitchClient struct {
	client *twitch.Client

	sendClient *twitch.Client
	raidCancel context.CancelFunc
}

func (c *AuthenticatedTwitchClient) Say(channel string, message string) {
	c.sendClient.Say(channel, message)
}

func (c *AuthenticatedTwitchClient) Reply(channel string, parentMessageId string, message string) {
	c.sendClient.Reply(channel, parentMessageId, message)
}

func (c *AuthenticatedTwitchClient) Close() error {
	if err := c.client.Disconnect(); err != nil {
		return err
	}
	if err := c.sendClient.Disconnect(); err != nil {
		return err
	}
	if c.raidCancel != nil {
		c.raidCancel()
	}
	return nil
}

type AnonymousTwitchClient struct {
	client *twitch.Client
}

func (c *AnonymousTwitchClient) Close() error {
	return c.client.Disconnect()
}

func (h *TwitchAgent) JoinAsUser(r *agent.Request, asUserID string) (io.Closer, error) {
	zap.L().Info("joining as user", zap.String("asUserID", asUserID), zap.String("request", r.String()))
	profile, err := h.Firestore.Collection("profiles").Doc(asUserID).Get(context.Background())
	if err != nil {
		return nil, err
	}
	if !profile.Exists() {
		return nil, errors.New("profile not found")
	}
	profileData := profile.Data()["twitch"].(map[string]interface{})

	authProvider, err := auth.NewFirestoreTwitchTokenSource(h.Firestore, h.ClientID, h.ClientSecret, asUserID)
	if err != nil {
		return nil, err
	}

	token, err := authProvider.Token()
	if err != nil {
		return nil, err
	}

	// create a new chat client and attempt to connect
	client := twitch.NewClient(profileData["login"].(string), fmt.Sprintf("oauth:%s", token.AccessToken))

	// join the channel
	if err := joinWithTimeout(client, r.Channel(), 5*time.Second); err != nil {
		return nil, err
	}

	h.bindEvents(client)

	if profileData["login"].(string) != "realtimechat" {
		sendClient := twitch.NewClient(profileData["login"].(string), fmt.Sprintf("oauth:%s", token.AccessToken))

		if err := joinWithTimeout(sendClient, r.Channel(), 5*time.Second); err != nil {
			return nil, err
		}

		sendClient.OnReconnectMessage(func(message twitch.ReconnectMessage) {
			if err := sendClient.Connect(); err != nil {
				zap.L().Error("failed to reconnect", zap.Error(err))
			}
		})

		raidCtx, raidCancel := context.WithCancel(context.Background())

		go func() {
			for {
				if err := h.bindRaidClient(raidCtx, profileData["id"].(string), asUserID); err != nil {
					if errors.Is(err, errReconnect) {
						zap.L().Info("reconnecting raid client due to error", zap.Error(err), zap.String("channel", r.Channel()), zap.String("asUserID", asUserID))
						continue
					}
					zap.L().Error("failed to bind raid client", zap.Error(err), zap.String("channel", r.Channel()), zap.String("asUserID", asUserID))
					return
				}
			}
		}()

		return &AuthenticatedTwitchClient{client: client, sendClient: sendClient, raidCancel: raidCancel}, nil
	}
	return &AnonymousTwitchClient{client: client}, nil
}

func (h *TwitchAgent) JoinAnonymously(r *agent.Request) (*AnonymousTwitchClient, error) {
	// create a new chat client and attempt to connect
	client := twitch.NewAnonymousClient()

	// join the channel
	return &AnonymousTwitchClient{client: client}, joinWithTimeout(client, r.Channel(), 5*time.Second)
}
