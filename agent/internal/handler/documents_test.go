package handler

import (
	"reflect"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/gempir/go-twitch-irc/v4"
)

func TestClearChatIDsDoNotCollide(t *testing.T) {
	now := time.Unix(1700000000, 1000000)
	a := clearChatDocument(twitch.ClearChatMessage{RoomID: "room", TargetUserID: "a", Time: now}, time.Now())
	b := clearChatDocument(twitch.ClearChatMessage{RoomID: "room", TargetUserID: "b", Time: now}, time.Now())
	c := clearChatDocument(twitch.ClearChatMessage{RoomID: "room", TargetUserID: "a", Time: now.Add(time.Millisecond)}, time.Now())
	if a.messageID == b.messageID || a.messageID == c.messageID {
		t.Fatalf("colliding user clear IDs: %q %q %q", a.messageID, b.messageID, c.messageID)
	}
	a = clearChatDocument(twitch.ClearChatMessage{RoomID: "room", Time: now}, time.Now())
	b = clearChatDocument(twitch.ClearChatMessage{RoomID: "room", Time: now.Add(time.Millisecond)}, time.Now())
	if a.messageID == b.messageID {
		t.Fatal("colliding full clear IDs")
	}
}

func TestAnnouncementPreservesRawBadges(t *testing.T) {
	doc := userNoticeDocument(twitch.UserNoticeMessage{MsgID: "announcement", Tags: map[string]string{"badges": "broadcaster/1"}}, time.Now())
	if doc.data["tags"].(map[string]interface{})["badges-raw"] != "broadcaster/1" {
		t.Fatal("announcement dropped badges")
	}
}

func TestPrivateMessageDocument(t *testing.T) {
	now := time.Unix(1700000000, 0)
	m := twitch.ParseMessage("@badge-info=;badges=moderator/1,vip/1;color=#123456;display-name=User;emotes=25:0-4;first-msg=1;id=msg;room-id=42;tmi-sent-ts=1700000000123;user-id=7;reply-parent-msg-id=parent;reply-parent-display-name=Parent;reply-parent-user-login=parent;reply-parent-user-id=8;reply-parent-msg-body=hello :user!user@user.tmi.twitch.tv PRIVMSG #room :Kappa").(*twitch.PrivateMessage)
	d := privateMessageDocument(*m, now)
	if d.channelID != "twitch:42" || d.messageID != "twitch:msg" || d.data["message"] != "Kappa" || d.data["timestamp"] != m.Time || d.data["type"] != "message" {
		t.Fatal(d)
	}
	tags := d.data["tags"].(map[string]interface{})
	if tags["emotes-raw"] != "25:0-4" || tags["badges-raw"] != "moderator/1,vip/1" || tags["username"] != "user" {
		t.Fatal(tags)
	}
	if !reflect.DeepEqual(tags["badges"], map[string]bool{"vip": true, "moderator": true}) {
		t.Fatal(tags)
	}
	if d.data["reply"].(map[string]interface{})["messageId"] != "twitch:parent" {
		t.Fatal(d.data["reply"])
	}
	if d.data["author"].(map[string]interface{})["userId"] != "7" {
		t.Fatal(d.data["author"])
	}
	if !d.data["annotations"].(map[string]interface{})["isFirstTimeChatter"].(bool) {
		t.Fatal("first message flag")
	}
	expiry := d.data["expiresAt"].(time.Time)
	if !expiry.Equal(now.Add(7 * 24 * time.Hour)) {
		t.Fatal(expiry)
	}
	m.Reply = nil
	m.Action = true
	d = privateMessageDocument(*m, now)
	if d.data["reply"].(map[string]interface{}) != nil || !d.data["annotations"].(map[string]interface{})["isAction"].(bool) {
		t.Fatal(d)
	}
}

func TestClearAndDeletionDocuments(t *testing.T) {
	now := time.Unix(1700000000, 0)
	for _, user := range []string{"", "7"} {
		d := clearChatDocument(twitch.ClearChatMessage{RoomID: "42", Time: now, TargetUserID: user}, time.Now())
		want := "clear"
		if user != "" {
			want = "userclear"
			if d.data["targetUserId"] != user {
				t.Fatal(d)
			}
		}
		if d.channelID != "twitch:42" || d.data["type"] != want || d.data["timestamp"] != now {
			t.Fatal(d)
		}
	}
	d := clearMessageDocument(twitch.ClearMessage{TargetMsgID: "msg"}, "42", time.Now())
	if d.messageID != "twitch:x-msg" || d.data["messageId"] != "twitch:msg" || d.data["type"] != "messagedeleted" || d.data["timestamp"] != firestore.ServerTimestamp {
		t.Fatal(d)
	}
}

func TestUserNoticeDocument(t *testing.T) {
	m := twitch.UserNoticeMessage{MsgID: "announcement", ID: "msg", RoomID: "42", Message: "hello", Time: time.Unix(1, 0), MsgParams: map[string]string{"msg-param-color": "BLUE"}}
	d := userNoticeDocument(m, time.Now())
	if d.messageID != "twitch:msg" || d.channelID != "twitch:42" || d.data["message"] != "hello" || d.data["timestamp"] != m.Time || d.data["annotations"].(map[string]interface{})["announcement"].(map[string]interface{})["color"] != "BLUE" {
		t.Fatal(d)
	}
	m.MsgID = "sub"
	if userNoticeDocument(m, time.Now()) != nil {
		t.Fatal("unexpected notice mapping")
	}
}
