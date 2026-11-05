package youtube

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/muxable/rtchat/agent/internal/chatmessage"
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

type thumbnail struct {
	URL    string `json:"url"`
	Width  int    `json:"width"`
	Height int    `json:"height"`
}

type thumbnails struct {
	Items []thumbnail `json:"thumbnails"`
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

// Gifts use view-model images and attributed text, unlike classic renderers.
// Captured gifts have no author channel ID, timestamp, jewel value or combo.
type giftRenderer struct {
	ID   string `json:"id"`
	Text struct {
		Content string `json:"content"`
	} `json:"text"`
	Author struct {
		Content string `json:"content"`
	} `json:"authorName"`
	Avatar struct {
		ViewModel struct {
			Image struct {
				Sources []thumbnail `json:"sources"`
			} `json:"image"`
		} `json:"avatarViewModel"`
	} `json:"authorAvatar"`
	Image struct {
		Sources []thumbnail `json:"sources"`
	} `json:"giftImage"`
	Alt string `json:"giftImageA11yLabel"`
}

type badges []struct {
	Badge struct {
		Icon struct {
			Type string `json:"iconType"`
		} `json:"icon"`
		Custom  json.RawMessage `json:"customThumbnail"`
		Tooltip string          `json:"tooltip"`
	} `json:"liveChatAuthorBadgeRenderer"`
}

type renderer struct {
	ID            string     `json:"id"`
	Timestamp     string     `json:"timestampUsec"`
	Author        text       `json:"authorName"`
	Channel       string     `json:"authorExternalChannelId"`
	Photo         thumbnails `json:"authorPhoto"`
	Badges        badges     `json:"authorBadges"`
	Message       text       `json:"message"`
	Amount        text       `json:"purchaseAmountText"`
	HeaderSubtext text       `json:"headerSubtext"`
	HeaderPrimary text       `json:"headerPrimaryText"`
	Header        struct {
		Sponsorship struct {
			Author  text       `json:"authorName"`
			Primary text       `json:"primaryText"`
			Photo   thumbnails `json:"authorPhoto"`
			Badges  badges     `json:"authorBadges"`
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

var numberPattern = regexp.MustCompile(`\b(\d+)\b`)
var levelPattern = regexp.MustCompile(`(?i)^(welcome to|upgraded membership to)\s+(.+?)\s*[!.！]?$`)

// membershipLevel reads the level name from a "Welcome to {level}!" or
// "Upgraded membership to {level}!" header. YouTube sends these as three runs
// with the level in the middle, which keeps level names ending in "!" intact.
// A header without a level, e.g. "New member", returns "".
func membershipLevel(t text) (level string, upgrade bool) {
	plain := strings.TrimSpace(t.plain())
	m := levelPattern.FindStringSubmatch(plain)
	if len(m) < 3 {
		return "", false
	}
	upgrade = strings.EqualFold(m[1], "upgraded membership to")
	if len(t.Runs) == 3 && t.Runs[0].Emoji == nil && t.Runs[1].Emoji == nil {
		if last := strings.TrimSpace(t.Runs[2].Text); last == "!" || last == "！" {
			if level := strings.TrimSpace(t.Runs[1].Text); level != "" {
				return level, upgrade
			}
		}
	}
	return m[2], upgrade
}

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
		if payload, ok := add.Item["giftMessageViewModel"]; ok {
			var gift giftRenderer
			if json.Unmarshal(payload, &gift) != nil || strings.TrimSpace(gift.ID) == "" || strings.Contains(gift.ID, "/") || strings.TrimSpace(gift.Author.Content) == "" || strings.TrimSpace(gift.Text.Content) == "" {
				return nil
			}
			kind, id, display = "giftEvent", gift.ID, strings.TrimSpace(gift.Text.Content)
			name := strings.TrimSpace(gift.Author.Content)
			author["displayName"] = name
			author["profileImageUrl"] = thumbnails{Items: gift.Avatar.ViewModel.Image.Sources}.largest()
			image := thumbnails{Items: gift.Image.Sources}.largest()
			if strings.HasPrefix(image, "//") {
				image = "https:" + image
			}
			giftName := strings.TrimSpace(strings.TrimPrefix(display, "sent "))
			if giftName == "" {
				giftName = display
			}
			d := map[string]interface{}{"altText": gift.Alt, "giftName": giftName}
			if image != "" {
				d["giftUrl"] = image
			}
			// Keep the display text if a localized or changed label cannot be read.
			if prefix := name + " sent a gift, "; strings.HasPrefix(gift.Alt, prefix) {
				if label := strings.TrimSpace(strings.TrimPrefix(gift.Alt, prefix)); label != "" {
					d["giftName"] = label
				}
			}
			details["giftDetails"] = d
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
			if len(r.Badges) == 0 {
				r.Badges = r.Header.Sponsorship.Badges
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
				// InnerTube has no sticker id, only the image and its label, so
				// stickerId is left out.
				details["superStickerDetails"] = map[string]interface{}{"amountDisplayString": r.Amount.plain(), "superStickerMetadata": map[string]interface{}{"altText": display}}
			case "liveChatMembershipItemRenderer":
				// A milestone has "Member for N months" in headerPrimaryText and
				// the level name in headerSubtext. New members and upgrades only
				// have headerSubtext: "Welcome to {level}!" or "Upgraded
				// membership to {level}!".
				if primary := r.HeaderPrimary.plain(); primary != "" {
					kind = "memberMilestoneChatEvent"
					d := map[string]interface{}{"memberLevelName": strings.TrimSpace(r.HeaderSubtext.plain()), "userComment": display}
					if m := numberPattern.FindStringSubmatch(primary); len(m) > 1 {
						if months, err := strconv.Atoi(m[1]); err == nil {
							d["memberMonth"] = months
						}
					}
					details["memberMilestoneChatDetails"] = d
					if display == "" {
						display = primary
					}
				} else {
					kind = "newSponsorEvent"
					level, upgrade := membershipLevel(r.HeaderSubtext)
					details["newSponsorDetails"] = map[string]interface{}{"memberLevelName": level, "isUpgrade": upgrade}
					if display == "" {
						display = r.HeaderSubtext.plain()
					}
				}
			case "liveChatSponsorshipsGiftPurchaseAnnouncementRenderer":
				kind = "membershipGiftingEvent"
				display = r.Header.Sponsorship.Primary.plain()
				m := numberPattern.FindStringSubmatch(display)
				if len(m) < 2 {
					return nil
				}
				count, err := strconv.Atoi(m[1])
				if err != nil || count <= 0 {
					return nil
				}
				// The header names the channel ("Gifted 5 {channel} memberships"),
				// not the level, so giftMembershipsLevelName is left out.
				details["membershipGiftingDetails"] = map[string]interface{}{"giftMembershipsCount": count}
			case "liveChatSponsorshipsGiftRedemptionAnnouncementRenderer":
				kind = "giftMembershipReceivedEvent"
				level, _ := membershipLevel(r.HeaderSubtext)
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
	return map[string]interface{}{"type": "youtube." + kind, "channelId": "youtube:" + channel, "timestamp": timestamp, "expiresAt": now.Add(chatmessage.TTL), "event": map[string]interface{}{"id": id, "snippet": snippet, "authorDetails": author}}
}
