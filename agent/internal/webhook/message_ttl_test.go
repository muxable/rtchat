package webhook

import (
	"encoding/json"
	"testing"
	"time"
)

// wantMessageTTL spells out the expected lifetimes instead of reusing the
// production constants, so the tests catch an accidental change to either.
func wantMessageTTL(messageType string) time.Duration {
	if messageType == "stream.online" || messageType == "stream.offline" {
		return 90 * 24 * time.Hour
	}
	return 7 * 24 * time.Hour
}

func TestTwitchMessageTTL(t *testing.T) {
	for _, eventType := range []string{"stream.online", "stream.offline", "channel.follow", "channel.cheer", "channel.raid"} {
		t.Run(eventType, func(t *testing.T) {
			var payload twitchPayload
			payload.Subscription.Type = eventType
			payload.Subscription.Version = "2"
			payload.Subscription.Status = "enabled"
			payload.Event = map[string]interface{}{"broadcaster_user_id": "1337", "to_broadcaster_user_id": "1337", "user_id": "42"}
			got, err := mapTwitchNotification(payload, "id", twitchTestNow, twitchTestNow)
			if err != nil {
				t.Fatal(err)
			}
			if len(got.Documents) == 0 {
				t.Fatal("no message document")
			}
			want := twitchTestNow.Truncate(time.Millisecond).Add(wantMessageTTL(eventType))
			if expiresAt := got.Documents[0].Data["expiresAt"]; expiresAt != want {
				t.Fatalf("expiresAt = %v, want %v", expiresAt, want)
			}
		})
	}
}

func TestKickMessageTTL(t *testing.T) {
	now := time.Date(2026, 10, 12, 1, 0, 0, 0, time.UTC)
	for _, tc := range []struct{ eventType, body, messageType string }{
		{"livestream.status.updated", `{"is_live":true,"started_at":"2026-10-12T00:00:00Z"}`, "stream.online"},
		{"livestream.status.updated", `{"is_live":false,"ended_at":"2026-10-12T00:30:00Z"}`, "stream.offline"},
		{"chat.message.sent", `{"message_id":"m","created_at":"2026-10-12T00:59:59Z"}`, "kick.chat.message.sent"},
		{"channel.followed", `{"follower":{"user_id":9}}`, "kick.channel.followed"},
	} {
		t.Run(tc.messageType, func(t *testing.T) {
			event := map[string]interface{}{"broadcaster": map[string]interface{}{"user_id": float64(123)}}
			if err := json.Unmarshal([]byte(tc.body), &event); err != nil {
				t.Fatal(err)
			}
			docs, err := KickToDocuments(KickDelivery{MessageID: "delivery-1", Timestamp: now.Format(time.RFC3339), Type: tc.eventType, Version: "1", Event: event}, now)
			if err != nil {
				t.Fatal(err)
			}
			if len(docs.Messages) != 1 || docs.Messages[0].Data["type"] != tc.messageType {
				t.Fatalf("messages %#v", docs.Messages)
			}
			if expiresAt, want := docs.Messages[0].Data["expiresAt"], now.Add(wantMessageTTL(tc.messageType)); expiresAt != want {
				t.Fatalf("expiresAt = %v, want %v", expiresAt, want)
			}
		})
	}
}
