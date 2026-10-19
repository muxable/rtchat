package youtube

import (
	"encoding/json"
	"os"
	"testing"
	"time"
)

func giftFixture(t *testing.T) map[string]interface{} {
	t.Helper()
	raw, err := os.ReadFile("testdata/actions/gift.json")
	if err != nil {
		t.Fatal(err)
	}
	var fixture struct{ Action map[string]interface{} }
	if err := json.Unmarshal(raw, &fixture); err != nil {
		t.Fatal(err)
	}
	return fixture.Action
}
func fixtureGift(action map[string]interface{}) map[string]interface{} {
	return action["addChatItemAction"].(map[string]interface{})["item"].(map[string]interface{})["giftMessageViewModel"].(map[string]interface{})
}
func TestGiftRejectsMalformedIdentityAndContent(t *testing.T) {
	for _, tc := range []struct {
		field string
		value interface{}
	}{
		{"id", nil}, {"id", ""}, {"id", " "}, {"id", "bad/id"}, {"id", 123},
		{"authorName", nil}, {"authorName", map[string]interface{}{"content": " "}},
		{"text", nil}, {"text", map[string]interface{}{"content": " "}},
		{"giftImage", "invalid"},
	} {
		t.Run(tc.field+"="+string(mustJSON(t, tc.value)), func(t *testing.T) {
			action := giftFixture(t)
			fixtureGift(action)[tc.field] = tc.value
			if got := actionData("channel", "video", mustJSON(t, action), time.Now()); got != nil {
				t.Fatalf("accepted malformed gift: %#v", got)
			}
		})
	}
}
func TestGiftMissingOptionalFieldsDoesNotInventValues(t *testing.T) {
	action := giftFixture(t)
	gift := fixtureGift(action)
	delete(gift, "authorAvatar")
	delete(gift, "giftImage")
	delete(gift, "giftImageA11yLabel")
	now := time.Unix(1700000000, 0).UTC()
	got := actionData("channel", "video", mustJSON(t, action), now)
	if got == nil {
		t.Fatal("gift without optional image/label was dropped")
	}
	event := got["event"].(map[string]interface{})
	author := event["authorDetails"].(map[string]interface{})
	snippet := event["snippet"].(map[string]interface{})
	details := snippet["giftDetails"].(map[string]interface{})
	if got["timestamp"] != now || snippet["publishedAt"] != now.Format(time.RFC3339Nano) || author["channelId"] != "" || author["channelUrl"] != "" || author["profileImageUrl"] != "" {
		t.Fatalf("invented unavailable metadata: %#v", got)
	}
	if details["giftName"] != "Party hat" {
		t.Fatalf("lost gift text without label: %#v", details)
	}
	for _, key := range []string{"jewelsAmount", "comboCount", "giftUrl"} {
		if _, ok := details[key]; ok {
			t.Fatalf("invented %s: %#v", key, details)
		}
	}
}
func TestGiftEmptyLabelKeepsName(t *testing.T) {
	action := giftFixture(t)
	fixtureGift(action)["giftImageA11yLabel"] = "@Viewer sent a gift, "
	got := actionData("channel", "video", mustJSON(t, action), time.Now())
	details := got["event"].(map[string]interface{})["snippet"].(map[string]interface{})["giftDetails"].(map[string]interface{})
	if details["giftName"] != "Party hat" {
		t.Fatal("empty accessibility label lost gift name", details)
	}
}
func TestGiftLocalizedLabelIsPreserved(t *testing.T) {
	action := giftFixture(t)
	gift := fixtureGift(action)
	gift["text"] = map[string]interface{}{"content": "envió Sombrero"}
	gift["giftImageA11yLabel"] = "@Viewer envió un regalo, Sombrero"
	got := actionData("channel", "video", mustJSON(t, action), time.Now())
	snippet := got["event"].(map[string]interface{})["snippet"].(map[string]interface{})
	details := snippet["giftDetails"].(map[string]interface{})
	if snippet["displayMessage"] != "envió Sombrero" || details["altText"] != "@Viewer envió un regalo, Sombrero" {
		t.Fatal(snippet)
	}
	if details["giftName"] != "envió Sombrero" {
		t.Fatal("lost gift text for unknown label format")
	}
}
func mustJSON(t *testing.T, v interface{}) json.RawMessage {
	t.Helper()
	raw, err := json.Marshal(v)
	if err != nil {
		t.Fatal(err)
	}
	return raw
}
