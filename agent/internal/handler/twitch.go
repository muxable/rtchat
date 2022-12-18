package handler

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"strings"
	"sync"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/gempir/go-twitch-irc/v3"
	"github.com/gorilla/websocket"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/auth"
	"github.com/muxable/rtchat/agent/internal/cancel"
	"go.uber.org/zap"
	"google.golang.org/api/iterator"
)

type TwitchHandler struct {
	firestore              *firestore.Client
	clientID, clientSecret string
	sendClients            map[string]*twitch.Client
}

func (h *TwitchHandler) bindOutboundClient(ctx context.Context) error {
	// listen on firestore for new messages
	snapshots := h.firestore.Collection("actions").OrderBy("createdAt", firestore.Desc).Limit(1).Snapshots(ctx)
	for {
		snapshot, err := snapshots.Next()
		if err == iterator.Done {
			return nil
		}
		if err != nil {
			return err
		}
		for _, change := range snapshot.Changes {
			if change.Kind == firestore.DocumentAdded {
				var action struct {
					ChannelId string
					Message        string
					TargetChannel  string
					ReplyMessageId string
				}
				zap.L().Info("new action", zap.Any("action", change.Doc.Data()))
				if err := change.Doc.DataTo(&action); err != nil {
					zap.L().Error("failed to unmarshal action", zap.Error(err))
					continue
				}
				client, ok := h.sendClients[action.ChannelId]
				if !ok {
					zap.L().Warn("no client found for channel", zap.String("channelId", action.ChannelId))
					continue
				}
				if err := h.firestore.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
					doc, err := tx.Get(change.Doc.Ref)
					if err != nil {
						return err
					}
					if doc.Data()["isComplete"] == true {
						return fmt.Errorf("action already complete")
					}
					return tx.Update(change.Doc.Ref, []firestore.Update{
						{Path: "sentAt", Value: firestore.ServerTimestamp},
						{Path: "isComplete", Value: true},
					})
				}); err != nil {
					zap.L().Warn("failed to lock action, probably another agent took it.", zap.Error(err))
					continue
				}

				zap.L().Info("sending message", zap.String("channelId", action.ChannelId), zap.Any("message", change.Doc.Data()))
				if action.ReplyMessageId != "" {
					client.Reply(action.TargetChannel, action.ReplyMessageId, action.Message)
				} else {
					client.Say(action.TargetChannel, action.Message)
				}
			}
		}
	}
}

var (
	errReconnect = errors.New("reconnect")
)

func (h *TwitchHandler) bindRaidClient(ctx context.Context, channelID, userID string) error {
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

	authProvider, err := auth.NewFirestoreTwitchTokenSource(h.firestore, h.clientID, h.clientSecret, userID)
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
			if data["topic"] == fmt.Sprintf("raid.%s", userID) {
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

				id := fmt.Sprintf("twitch:%s-%s", raid.Type, raid.Raid["id"].(string))
				zap.L().Info("received raid", zap.String("id", id), zap.Any("raid", raid.Raid))
				// write this event to firestore
				if _, err := h.firestore.Collection("channels").Doc(userID).Collection("messages").Doc(id).Set(ctx, map[string]interface{}{
					"raid":      raid.Raid,
					"type":      raid.Type,
					"timestamp": firestore.ServerTimestamp,
				}); err != nil {
					zap.L().Error("failed to write raid message to firestore", zap.Error(err))
					continue
				}
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
			zap.L().Info("connected to chat", zap.String("channel", channel))
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

func (h *TwitchHandler) metadata(channelID string, data interface{}) {
	go func() {
		for i := 0; i < 3; i++ {
			if _, err := h.firestore.Collection("channels").Doc(channelID).Set(context.Background(), data, firestore.MergeAll); err != nil {
				zap.L().Error("failed to update channel metadata", zap.Error(err), zap.String("channelId", channelID), zap.Any("data", data))
				time.Sleep(1 * time.Second)
				continue
			}
			break
		}
	}()
}

func (h *TwitchHandler) write(channelID, messageID string, data interface{}) {
	if _, err := h.firestore.Collection("channels").Doc(channelID).Collection("messages").Doc(messageID).Set(context.Background(), data); err != nil {
		zap.L().Error("failed to write message to firestore", zap.Error(err), zap.String("channelId", channelID), zap.String("messageId", messageID), zap.Any("data", data))
	}
}

func (h *TwitchHandler) bindEvents(client *twitch.Client) {
	client.OnNoticeMessage(func(message twitch.NoticeMessage) {
		if message.Channel == "*" {
			return
		}
		userID, err := auth.TwitchUserIDFromUsername(h.firestore, h.clientID, h.clientSecret, message.Channel)
		if err != nil {
			return
		}
		channelID := fmt.Sprintf("twitch:%s", userID)
		switch message.MsgID {
		case "r9k_on", "already_r9k_on":
			h.metadata(channelID, map[string]interface{}{
				"isR9k": true,
			})
		case "r9k_off", "already_r9k_off":
			h.metadata(channelID, map[string]interface{}{
				"isR9k": false,
			})
		case "slow_on", "already_slow_on":
			h.metadata(channelID, map[string]interface{}{
				"isSlowMode": true,
			})
		case "slow_off", "already_slow_off":
			h.metadata(channelID, map[string]interface{}{
				"isSlowMode": false,
			})
		case "subs_on", "already_subs_on":
			h.metadata(channelID, map[string]interface{}{
				"isSubsOnly": true,
			})
		case "subs_off", "already_subs_off":
			h.metadata(channelID, map[string]interface{}{
				"isSubsOnly": false,
			})
		case "followers_on", "already_followers_on":
			h.metadata(channelID, map[string]interface{}{
				"isFollowersOnly": true,
			})
		case "followers_off", "already_followers_off":
			h.metadata(channelID, map[string]interface{}{
				"isFollowersOnly": false,
			})
		case "emote_only_on", "already_emote_only_on":
			h.metadata(channelID, map[string]interface{}{
				"isEmoteOnly": true,
			})
		case "emote_only_off", "already_emote_only_off":
			h.metadata(channelID, map[string]interface{}{
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
				"type": "message",
			}
			go h.write(channelID, fmt.Sprintf("twitch:%s", message.ID), data)
		}
	})

	// configure handlers
	client.OnClearChatMessage(func(message twitch.ClearChatMessage) {
		if message.TargetUserID != "" || message.TargetUsername != "" {
			return
		}
		// handle clear chat message
		channelID := fmt.Sprintf("twitch:%s", message.RoomID)
		data := map[string]interface{}{
			"channelId": channelID,
			"timestamp": message.Time,
			"type":      "clear",
		}
		go h.write(channelID, fmt.Sprintf("twitch:clear-%s", message.Time.Format(time.RFC3339)), data)
	})

	client.OnClearMessage(func(message twitch.ClearMessage) {
		// handle deleted message
		userID, err := auth.TwitchUserIDFromUsername(h.firestore, h.clientID, h.clientSecret, message.Channel)
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
			"type": "message",
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

func (h *TwitchHandler) JoinAsUser(r *agent.Request, asUserID string) error {
	zap.L().Info("joining as user", zap.String("asUserID", asUserID), zap.String("request", r.String()))
	profile, err := h.firestore.Collection("profiles").Doc(asUserID).Get(context.Background())
	if err != nil {
		return err
	}
	if !profile.Exists() {
		return errors.New("profile not found")
	}
	profileData := profile.Data()["twitch"].(map[string]interface{})

	authProvider, err := auth.NewFirestoreTwitchTokenSource(h.firestore, h.clientID, h.clientSecret, asUserID)
	if err != nil {
		return err
	}

	token, err := authProvider.Token()
	if err != nil {
		return err
	}

	// create a new chat client and attempt to connect
	client := twitch.NewClient(profileData["login"].(string), fmt.Sprintf("oauth:%s", token.AccessToken))

	// join the channel
	if err := joinWithTimeout(client, r.Channel(), 5*time.Second); err != nil {
		return err
	}

	zap.L().Info("joined channel", zap.String("channel", r.Channel()))

	h.bindEvents(client)

	if profileData["login"].(string) != "realtimechat" {
		sendClient := twitch.NewClient(profileData["login"].(string), fmt.Sprintf("oauth:%s", token.AccessToken))

		if err := joinWithTimeout(sendClient, r.Channel(), 5*time.Second); err != nil {
			return err
		}

		sendClient.OnReconnectMessage(func(message twitch.ReconnectMessage) {
			if err := sendClient.Connect(); err != nil {
				zap.L().Error("failed to reconnect", zap.Error(err))
			}
		})

		h.sendClients[fmt.Sprintf("twitch:%s", profileData["id"].(string))] = sendClient

		go func() {
			for {
				if err := h.bindRaidClient(context.Background(), profileData["id"].(string), asUserID); err != nil {
					if !cancel.IsCanceled(err) && !errors.Is(err, net.ErrClosed) {
						zap.L().Error("failed to bind raid client", zap.Error(err))
					}
					if errors.Is(err, errReconnect) {
						continue
					}
					return
				}
			}
		}()
	}
	return nil
}

func (h *TwitchHandler) JoinAnonymously(r *agent.Request) error {
	// create a new chat client and attempt to connect
	client := twitch.NewAnonymousClient()

	// join the channel
	return joinWithTimeout(client, r.Channel(), 5*time.Second)
}
