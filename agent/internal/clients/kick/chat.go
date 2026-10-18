package kick

import (
	"context"
	"math"
	"net/url"
	"strconv"
	"unicode/utf16"
)

// JavaScript slice counts UTF-16 code units, including surrogate pairs.
func truncateReason(reason string) string {
	units := utf16.Encode([]rune(reason))
	if len(units) > 100 {
		units = units[:100]
	}
	return string(utf16.Decode(units))
}

func (c *Client) ChannelUser(ctx context.Context, slug string) (string, error) {
	var response struct {
		Data []struct {
			UserID any `json:"broadcaster_user_id"`
		}
	}
	if err := c.Get(ctx, "/channels?"+url.Values{"slug": {slug}}.Encode(), &response); err != nil {
		return "", err
	}
	if len(response.Data) == 0 {
		return "", nil
	}
	switch id := response.Data[0].UserID.(type) {
	case string:
		return id, nil
	case float64:
		return strconv.FormatFloat(id, 'f', 0, 64), nil
	}
	return "", nil
}

func (c *Client) SendMessage(ctx context.Context, channel int64, message, reply string) error {
	body := map[string]any{"content": message, "type": "user", "broadcaster_user_id": channel}
	if reply != "" {
		body["reply_to_message_id"] = reply
	}
	_, _, err := c.DoJSON(ctx, "POST", "/chat", body)
	return err
}

func (c *Client) DeleteMessage(ctx context.Context, message string) error {
	_, _, err := c.DoJSON(ctx, "DELETE", "/chat/"+url.PathEscape(message), nil)
	return err
}

func (c *Client) Ban(ctx context.Context, channel, user int64, seconds float64, reason string) error {
	body := map[string]any{"broadcaster_user_id": channel, "user_id": user}
	if seconds != 0 {
		body["duration"] = math.Min(10080, math.Max(1, math.Ceil(seconds/60)))
		if reason != "" {
			body["reason"] = truncateReason(reason)
		}
	}
	_, _, err := c.DoJSON(ctx, "POST", "/moderation/bans", body)
	return err
}

func (c *Client) Unban(ctx context.Context, channel, user int64) error {
	_, _, err := c.DoJSON(ctx, "DELETE", "/moderation/bans", map[string]any{"broadcaster_user_id": channel, "user_id": user})
	return err
}
