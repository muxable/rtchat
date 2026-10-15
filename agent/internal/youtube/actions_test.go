package youtube

import (
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"
)

// TestActionContract checks the full event mapping for each renderer. Its
// actions are hand-built; TestLiveChat checks real ones.
func TestActionContract(t *testing.T) {
	now := time.Unix(1700000000, 0).UTC()
	common := `"id":"item","timestampUsec":"1700000000123456","authorName":{"simpleText":"@Given"},"authorExternalChannelId":"author","authorPhoto":{"thumbnails":[{"url":"large","width":64,"height":64},{"url":"small","width":32,"height":32}]},"authorBadges":[{"liveChatAuthorBadgeRenderer":{"icon":{"iconType":"OWNER"}}},{"liveChatAuthorBadgeRenderer":{"icon":{"iconType":"MODERATOR"}}},{"liveChatAuthorBadgeRenderer":{"icon":{"iconType":"VERIFIED"}}},{"liveChatAuthorBadgeRenderer":{"customThumbnail":{"thumbnails":[{"url":"member"}]}}}],`
	message := `"message":{"runs":[{"text":"hello "},{"emoji":{"emojiId":"emoji","shortcuts":[":wave:",":hi:"]}},{"emoji":{"emojiId":"🙂"}}]}`
	cases := []struct{ name, renderer, extra, kind, display, details string }{
		{"text", "liveChatTextMessageRenderer", message, "textMessageEvent", "hello :wave:🙂", `"textMessageDetails":{"messageText":"hello :wave:🙂"}`},
		{"paid", "liveChatPaidMessageRenderer", message + `,"purchaseAmountText":{"simpleText":"$5.00"}`, "superChatEvent", "hello :wave:🙂", `"superChatDetails":{"amountDisplayString":"$5.00","userComment":"hello :wave:🙂"}`},
		{"explicit currency", "liveChatPaidMessageRenderer", message + `,"purchaseAmountText":{"simpleText":"USD 5.25"}`, "superChatEvent", "hello :wave:🙂", `"superChatDetails":{"amountDisplayString":"USD 5.25","userComment":"hello :wave:🙂","currency":"USD","amountMicros":"5250000"}`},
		{"sticker", "liveChatPaidStickerRenderer", `"purchaseAmountText":{"simpleText":"€3.00"},"sticker":{"accessibility":{"accessibilityData":{"label":"Happy fox"}}}`, "superStickerEvent", "Happy fox", `"superStickerDetails":{"amountDisplayString":"€3.00","superStickerMetadata":{"altText":"Happy fox"}}`},
		{"member", "liveChatMembershipItemRenderer", `"headerSubtext":{"runs":[{"text":"Welcome to Gold!"}]}`, "newSponsorEvent", "Welcome to Gold!", `"newSponsorDetails":{"memberLevelName":"Gold","isUpgrade":false}`},
		{"upgrade", "liveChatMembershipItemRenderer", `"headerSubtext":{"runs":[{"text":"Upgraded membership to "},{"text":"Gold"},{"text":"!"}]}`, "newSponsorEvent", "Upgraded membership to Gold!", `"newSponsorDetails":{"memberLevelName":"Gold","isUpgrade":true}`},
		{"milestone", "liveChatMembershipItemRenderer", message + `,"headerPrimaryText":{"runs":[{"text":"Member for "},{"text":"12"},{"text":" months"}]},"headerSubtext":{"simpleText":"Gold"}`, "memberMilestoneChatEvent", "hello :wave:🙂", `"memberMilestoneChatDetails":{"memberMonth":12,"userComment":"hello :wave:🙂","memberLevelName":"Gold"}`},
		{"gifting", "liveChatSponsorshipsGiftPurchaseAnnouncementRenderer", `"header":{"liveChatSponsorshipsHeaderRenderer":{"primaryText":{"runs":[{"text":"Gifted "},{"text":"5"},{"text":" memberships"}]}}}`, "membershipGiftingEvent", "Gifted 5 memberships", `"membershipGiftingDetails":{"giftMembershipsCount":5}`},
		{"redemption", "liveChatSponsorshipsGiftRedemptionAnnouncementRenderer", message + `,"headerSubtext":{"simpleText":"Welcome to Gold!"}`, "giftMembershipReceivedEvent", "hello :wave:🙂", `"giftMembershipReceivedDetails":{"memberLevelName":"Gold"}`},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			raw := json.RawMessage(`{"clickTrackingParams":"ignored","addChatItemAction":{"item":{"` + tc.renderer + `":{` + common + tc.extra + `}}}}`)
			data := actionData("channel", "video", raw, now)
			if data == nil {
				t.Fatal("skipped valid action")
			}
			want := `{"id":"item","snippet":{"type":"` + tc.kind + `","liveChatId":"innertube:video","authorChannelId":"author","publishedAt":"2023-11-14T22:13:20.123456Z","hasDisplayContent":true,"displayMessage":"` + tc.display + `",` + tc.details + `},"authorDetails":{"channelId":"author","channelUrl":"https://www.youtube.com/channel/author","displayName":"@Given","profileImageUrl":"large","isVerified":true,"isChatOwner":true,"isChatSponsor":true,"isChatModerator":true}}`
			assertJSON(t, data["event"], want)
			if data["type"] != "youtube."+tc.kind || data["channelId"] != "youtube:channel" || data["timestamp"] != time.Unix(1700000000, 123456000).UTC() || data["expiresAt"] != now.Add(14*24*time.Hour) {
				t.Fatalf("incorrect envelope: %#v", data)
			}
		})
	}
}

// testdata/actions holds InnerTube actions with the LiveChatMessage the app
// parser expects for each. Each file's "source" says whether it is an
// anonymized real capture or was constructed by hand; the constructed ones
// pin down shapes we have not captured, so they assert behavior, not that
// YouTube sends them. TestLiveChat checks real traffic.
func TestActionTestdata(t *testing.T) {
	now := time.Unix(1700000000, 0).UTC()
	files, err := filepath.Glob("testdata/actions/*.json")
	if err != nil || len(files) == 0 {
		t.Fatal("missing testdata", err)
	}
	for _, file := range files {
		t.Run(filepath.Base(file), func(t *testing.T) {
			b, err := os.ReadFile(file)
			if err != nil {
				t.Fatal(err)
			}
			var tc struct {
				Source string          `json:"source"`
				Action json.RawMessage `json:"action"`
				Event  json.RawMessage `json:"event"`
			}
			if err := json.Unmarshal(b, &tc); err != nil {
				t.Fatal(err)
			}
			switch {
			case strings.HasPrefix(tc.Source, "constructed"):
				t.Logf("hand-built: %s", tc.Source)
			case !strings.HasPrefix(tc.Source, "anonymized real capture"):
				t.Fatalf("source %q must start with \"anonymized real capture\" or \"constructed\"", tc.Source)
			}
			data := actionData("channel", "video", tc.Action, now)
			if data == nil {
				t.Fatal("skipped valid action")
			}
			assertJSON(t, data["event"], string(tc.Event))
		})
	}
}

func TestMembershipLevel(t *testing.T) {
	for _, tc := range []struct {
		header, level string
		upgrade       bool
	}{
		{`{"runs":[{"text":"Welcome to "},{"text":"Gold"},{"text":"!"}]}`, "Gold", false},
		{`{"runs":[{"text":"Welcome to "},{"text":"Rat Boss!"},{"text":"!"}]}`, "Rat Boss!", false},
		{`{"simpleText":"Welcome to Rat Boss!!"}`, "Rat Boss!", false},
		{`{"simpleText":"Upgraded membership to Platinum!"}`, "Platinum", true},
		{`{"runs":[{"text":"Upgraded membership to "},{"text":"Platinum"},{"text":"!"}]}`, "Platinum", true},
		{`{"simpleText":"New member"}`, "", false},
		{`{}`, "", false},
	} {
		var header text
		if err := json.Unmarshal([]byte(tc.header), &header); err != nil {
			t.Fatal(err)
		}
		if level, upgrade := membershipLevel(header); level != tc.level || upgrade != tc.upgrade {
			t.Errorf("%s: got %q %v, want %q %v", tc.header, level, upgrade, tc.level, tc.upgrade)
		}
	}
}

func assertJSON(t *testing.T, got interface{}, want string) {
	t.Helper()
	b, err := json.Marshal(got)
	if err != nil {
		t.Fatal(err)
	}
	var actual, expected interface{}
	if err := json.Unmarshal(b, &actual); err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal([]byte(want), &expected); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(actual, expected) {
		t.Fatalf("event mismatch\ngot  %s\nwant %s", b, want)
	}
}
func TestDeletionAndBanContract(t *testing.T) {
	now := time.Unix(1700000000, 0).UTC()
	for _, key := range []string{"removeChatItemAction", "markChatItemAsDeletedAction", "removeChatItemByAuthorAction"} {
		t.Run(key, func(t *testing.T) {
			payload := `{"targetItemId":"item"}`
			kind, id, details := "tombstone", "item", ""
			if key == "removeChatItemByAuthorAction" {
				payload = `{"externalChannelId":"banned"}`
				kind = "userBannedEvent"
				details = `,"userBannedDetails":{"bannedUserDetails":{"channelId":"banned"}}`
			}
			data := actionData("channel", "video", json.RawMessage(`{"`+key+`":`+payload+`}`), now)
			if data == nil {
				t.Fatal("skipped deletion")
			}
			if kind == "userBannedEvent" {
				id = data["event"].(map[string]interface{})["id"].(string)
				if !strings.HasPrefix(id, "ban-") {
					t.Fatal(id)
				}
			}
			assertJSON(t, data["event"], `{"id":"`+id+`","snippet":{"type":"`+kind+`","liveChatId":"innertube:video","authorChannelId":"","publishedAt":"2023-11-14T22:13:20Z","hasDisplayContent":true,"displayMessage":""`+details+`},"authorDetails":{"channelId":"","channelUrl":"","displayName":"","profileImageUrl":"","isVerified":false,"isChatOwner":false,"isChatSponsor":false,"isChatModerator":false}}`)
		})
	}
}
func TestMalformedAndUnsupportedActions(t *testing.T) {
	for _, raw := range []string{`null`, `[]`, `{}`, `{"unknown":{}}`, `{"addBannerToLiveChatCommand":{}}`, `{"replaceChatItemAction":{}}`, `{"removeChatItemAction":{}}`, `{"removeChatItemByAuthorAction":{}}`, `{"addChatItemAction":{"item":{"liveChatPlaceholderItemRenderer":{}}}}`, `{"addChatItemAction":{"item":{"liveChatViewerEngagementMessageRenderer":{}}}}`, `{"addChatItemAction":{"item":{"liveChatTextMessageRenderer":{"id":"item","timestampUsec":"bad"}}}}`, `{"addChatItemAction":{"item":{"liveChatTextMessageRenderer":{"id":"bad/id","timestampUsec":"1234"}}}}`} {
		if got := actionData("channel", "video", json.RawMessage(raw), time.Now()); got != nil {
			t.Fatalf("did not skip %s", raw)
		}
	}
}
