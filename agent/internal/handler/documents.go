package handler

import (
	"fmt"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/gempir/go-twitch-irc/v3"
)

type chatDocument struct {
	channelID, messageID string
	data                 map[string]interface{}
}

func userNoticeDocument(message twitch.UserNoticeMessage, now time.Time) *chatDocument {
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
				"badges-raw": message.Tags["badges"],
			},
			"type":      "message",
			"expiresAt": now.Add(time.Hour * 24 * 7 * 2),
		}
		return &chatDocument{channelID, fmt.Sprintf("twitch:%s", message.ID), data}
	}

	return nil
}

func clearChatDocument(message twitch.ClearChatMessage, now time.Time) *chatDocument {
	// handle clear chat message
	channelID := fmt.Sprintf("twitch:%s", message.RoomID)
	if message.TargetUserID != "" || message.TargetUsername != "" {
		data := map[string]interface{}{
			"channelId":    channelID,
			"targetUserId": message.TargetUserID,
			"timestamp":    message.Time,
			"type":         "userclear",
			"expiresAt":    now.Add(time.Hour * 24 * 7 * 2),
		}
		return &chatDocument{channelID, fmt.Sprintf("twitch:userclear-%s-%s", message.Time.UTC().Format(time.RFC3339Nano), message.TargetUserID+"-"+message.TargetUsername), data}
	} else {
		data := map[string]interface{}{
			"channelId": channelID,
			"timestamp": message.Time,
			"type":      "clear",
			"expiresAt": now.Add(time.Hour * 24 * 7 * 2),
		}
		return &chatDocument{channelID, fmt.Sprintf("twitch:clear-%s", message.Time.UTC().Format(time.RFC3339Nano)), data}
	}
}

func clearMessageDocument(message twitch.ClearMessage, userID string, now time.Time) *chatDocument {
	channelID := fmt.Sprintf("twitch:%s", userID)
	data := map[string]interface{}{
		"channelId": channelID,
		"timestamp": firestore.ServerTimestamp,
		"type":      "messagedeleted",
		"messageId": fmt.Sprintf("twitch:%s", message.TargetMsgID),
		"expiresAt": now.Add(time.Hour * 24 * 7 * 2),
	}
	return &chatDocument{channelID, fmt.Sprintf("twitch:x-%s", message.TargetMsgID), data}
}

func privateMessageDocument(message twitch.PrivateMessage, now time.Time) *chatDocument {
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
		"expiresAt": now.Add(time.Hour * 24 * 7 * 2),
	}
	return &chatDocument{channelID, fmt.Sprintf("twitch:%s", message.ID), data}

}
