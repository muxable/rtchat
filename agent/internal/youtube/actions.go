package youtube

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"
)

type text struct {
	Simple string `json:"simpleText"`
	Runs   []struct {
		Text  string `json:"text"`
		Emoji *struct {
			ID        string   `json:"emojiId"`
			Shortcuts []string `json:"shortcuts"`
		} `json:"emoji"`
	} `json:"runs"`
}

func (t text) plain() string {
	if t.Simple != "" {
		return t.Simple
	}
	var b strings.Builder
	for _, r := range t.Runs {
		b.WriteString(r.Text)
		if r.Emoji != nil {
			if len(r.Emoji.Shortcuts) > 0 {
				b.WriteString(r.Emoji.Shortcuts[0])
			} else {
				b.WriteString(r.Emoji.ID)
			}
		}
	}
	return b.String()
}

type thumbnails struct {
	Items []struct {
		URL    string `json:"url"`
		Width  int    `json:"width"`
		Height int    `json:"height"`
	} `json:"thumbnails"`
}

func (t thumbnails) largest() string {
	best, area := "", -1
	for _, item := range t.Items {
		if size := item.Width * item.Height; size >= area {
			best, area = item.URL, size
		}
	}
	return best
}

type renderer struct {
	ID        string     `json:"id"`
	Timestamp string     `json:"timestampUsec"`
	Author    text       `json:"authorName"`
	Channel   string     `json:"authorExternalChannelId"`
	Photo     thumbnails `json:"authorPhoto"`
	Badges    []struct {
		Badge struct {
			Icon struct {
				Type string `json:"iconType"`
			} `json:"icon"`
			Custom  json.RawMessage `json:"customThumbnail"`
			Tooltip string          `json:"tooltip"`
		} `json:"liveChatAuthorBadgeRenderer"`
	} `json:"authorBadges"`
	Message       text `json:"message"`
	Amount        text `json:"purchaseAmountText"`
	HeaderSubtext text `json:"headerSubtext"`
	HeaderPrimary text `json:"headerPrimaryText"`
	Header        struct {
		Sponsorship struct {
			Author  text       `json:"authorName"`
			Primary text       `json:"primaryText"`
			Photo   thumbnails `json:"authorPhoto"`
		} `json:"liveChatSponsorshipsHeaderRenderer"`
	} `json:"header"`
	Sticker struct {
		Accessibility struct {
			Data struct {
				Label string `json:"label"`
			} `json:"accessibilityData"`
		} `json:"accessibility"`
	} `json:"sticker"`
}

var monthPattern = regexp.MustCompile(`(?i)member for\s+(\d+)\s+months?`)
var giftPattern = regexp.MustCompile(`\b(\d+)\b`)
var levelPattern = regexp.MustCompile(`(?i)welcome to (.+?)[!.]?$`)
var moneyPattern = regexp.MustCompile(`^(USD|EUR|GBP|JPY|CAD|AUD)\s*(\d+)(?:\.(\d{1,6}))?$`)

// actionData returns nil for unsupported or malformed actions. No renderer data
// is trusted to contain its required fields.
func actionData(channel, video string, raw json.RawMessage, now time.Time) map[string]interface{} {
	var action map[string]json.RawMessage
	if json.Unmarshal(raw, &action) != nil {
		return nil
	}
	kind, id, authorID, display := "", "", "", ""
	timestamp := now
	author := map[string]interface{}{"channelId": "", "channelUrl": "", "displayName": "", "profileImageUrl": "", "isVerified": false, "isChatOwner": false, "isChatSponsor": false, "isChatModerator": false}
	details := map[string]interface{}{}
	for _, key := range []string{"removeChatItemAction", "markChatItemAsDeletedAction", "removeChatItemByAuthorAction"} {
		if payload, ok := action[key]; ok {
			var deletion struct {
				Target  string `json:"targetItemId"`
				Channel string `json:"externalChannelId"`
			}
			if json.Unmarshal(payload, &deletion) != nil {
				return nil
			}
			if key == "removeChatItemByAuthorAction" {
				if deletion.Channel == "" {
					return nil
				}
				kind = "userBannedEvent"
				id = fmt.Sprintf("ban-%x", sha256.Sum256([]byte(video+string(raw)+now.Format(time.RFC3339Nano))))
				details["userBannedDetails"] = map[string]interface{}{"bannedUserDetails": map[string]interface{}{"channelId": deletion.Channel}}
			} else {
				kind, id = "tombstone", deletion.Target
				if id == "" {
					return nil
				}
			}
			break
		}
	}
	if kind == "" {
		var add struct {
			Item map[string]json.RawMessage `json:"item"`
		}
		if json.Unmarshal(action["addChatItemAction"], &add) != nil {
			return nil
		}
		var r renderer
		for _, name := range []string{"liveChatTextMessageRenderer", "liveChatPaidMessageRenderer", "liveChatPaidStickerRenderer", "liveChatMembershipItemRenderer", "liveChatSponsorshipsGiftPurchaseAnnouncementRenderer", "liveChatSponsorshipsGiftRedemptionAnnouncementRenderer"} {
			payload, ok := add.Item[name]
			if !ok {
				continue
			}
			if json.Unmarshal(payload, &r) != nil {
				return nil
			}
			id, authorID, display = r.ID, r.Channel, r.Message.plain()
			micros, err := strconv.ParseInt(r.Timestamp, 10, 64)
			if err != nil || micros <= 0 || id == "" || strings.Contains(id, "/") {
				return nil
			}
			timestamp = time.Unix(micros/1000000, (micros%1000000)*1000).UTC()
			if r.Author.plain() == "" {
				r.Author = r.Header.Sponsorship.Author
			}
			if len(r.Photo.Items) == 0 {
				r.Photo = r.Header.Sponsorship.Photo
			}
			author["channelId"], author["displayName"], author["profileImageUrl"] = authorID, r.Author.plain(), r.Photo.largest()
			if authorID != "" {
				author["channelUrl"] = "https://www.youtube.com/channel/" + authorID
			}
			for _, badge := range r.Badges {
				switch badge.Badge.Icon.Type {
				case "OWNER":
					author["isChatOwner"] = true
				case "MODERATOR":
					author["isChatModerator"] = true
				case "VERIFIED":
					author["isVerified"] = true
				}
				if len(badge.Badge.Custom) > 0 && string(badge.Badge.Custom) != "null" {
					author["isChatSponsor"] = true
				}
			}
			level := ""
			if m := levelPattern.FindStringSubmatch(r.HeaderSubtext.plain()); len(m) > 1 {
				level = m[1]
			}
			switch name {
			case "liveChatTextMessageRenderer":
				kind = "textMessageEvent"
				details["textMessageDetails"] = map[string]interface{}{"messageText": display}
			case "liveChatPaidMessageRenderer":
				kind = "superChatEvent"
				d := map[string]interface{}{"amountDisplayString": r.Amount.plain(), "userComment": display}
				// Currency symbols are ambiguous (e.g. "$"), so only explicit ISO codes
				// with unambiguous decimal notation are converted to micros.
				if m := moneyPattern.FindStringSubmatch(r.Amount.plain()); len(m) > 0 {
					whole, err := strconv.ParseInt(m[2], 10, 64)
					fraction, _ := strconv.ParseInt(m[3]+strings.Repeat("0", 6-len(m[3])), 10, 64)
					if err == nil && whole <= (int64(1<<63-1)-fraction)/1000000 {
						d["currency"], d["amountMicros"] = m[1], strconv.FormatInt(whole*1000000+fraction, 10)
					}
				}
				details["superChatDetails"] = d
			case "liveChatPaidStickerRenderer":
				kind = "superStickerEvent"
				display = r.Sticker.Accessibility.Data.Label
				details["superStickerDetails"] = map[string]interface{}{"amountDisplayString": r.Amount.plain(), "superStickerMetadata": map[string]interface{}{"altText": display}}
			case "liveChatMembershipItemRenderer":
				subtext := r.HeaderSubtext.plain()
				if m := monthPattern.FindStringSubmatch(subtext); len(m) > 1 {
					months, err := strconv.Atoi(m[1])
					if err != nil {
						return nil
					}
					kind = "memberMilestoneChatEvent"
					details["memberMilestoneChatDetails"] = map[string]interface{}{"memberMonth": months, "userComment": display, "memberLevelName": r.HeaderPrimary.plain()}
				} else {
					kind = "newSponsorEvent"
					details["newSponsorDetails"] = map[string]interface{}{"memberLevelName": level}
				}
				if display == "" {
					display = subtext
				}
			case "liveChatSponsorshipsGiftPurchaseAnnouncementRenderer":
				kind = "membershipGiftingEvent"
				display = r.Header.Sponsorship.Primary.plain()
				m := giftPattern.FindStringSubmatch(display)
				if len(m) < 2 {
					return nil
				}
				count, err := strconv.Atoi(m[1])
				if err != nil || count <= 0 {
					return nil
				}
				details["membershipGiftingDetails"] = map[string]interface{}{"giftMembershipsCount": count}
			case "liveChatSponsorshipsGiftRedemptionAnnouncementRenderer":
				kind = "giftMembershipReceivedEvent"
				details["giftMembershipReceivedDetails"] = map[string]interface{}{"memberLevelName": level}
			}
			break
		}
	}
	if kind == "" || strings.Contains(id, "/") {
		return nil
	}
	snippet := map[string]interface{}{"type": kind, "liveChatId": "innertube:" + video, "authorChannelId": authorID, "publishedAt": timestamp.UTC().Format(time.RFC3339Nano), "hasDisplayContent": true, "displayMessage": display}
	for key, value := range details {
		snippet[key] = value
	}
	return map[string]interface{}{"type": "youtube." + kind, "channelId": "youtube:" + channel, "timestamp": timestamp, "expiresAt": now.Add(14 * 24 * time.Hour), "event": map[string]interface{}{"id": id, "snippet": snippet, "authorDetails": author}}
}
