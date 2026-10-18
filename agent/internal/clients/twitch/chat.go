package twitch

import (
	"context"
	"net/url"
)

type User struct {
	ID          string `json:"id"`
	Login       string `json:"login"`
	DisplayName string `json:"display_name"`
}

func (c *Client) User(ctx context.Context, key, value string) (User, error) {
	var response struct{ Data []User }
	if err := c.Get(ctx, "/users?"+url.Values{key: {value}}.Encode(), &response); err != nil {
		return User{}, err
	}
	if len(response.Data) == 0 {
		return User{}, nil
	}
	return response.Data[0], nil
}

// SendMessage returns an empty message when accepted, or the provider's drop
// reason when rejected. HTTP errors remain available for IRC fallback policy.
func (c *Client) SendMessage(ctx context.Context, channel, sender, message, reply string) (string, error) {
	body := map[string]any{"broadcaster_id": channel, "sender_id": sender, "message": message}
	if reply != "" {
		body["reply_parent_message_id"] = reply
	}
	response, err := c.Do(ctx, "POST", "/chat/messages", body)
	if err != nil {
		return "", err
	}
	var result struct {
		Message string
		Data    []struct {
			IsSent     bool                     `json:"is_sent"`
			DropReason struct{ Message string } `json:"drop_reason"`
		}
	}
	if response.StatusCode == 401 || response.StatusCode == 403 {
		return "", response.Err()
	}
	if err := response.Decode(&result); err != nil {
		return "", err
	}
	if len(result.Data) > 0 {
		if result.Data[0].IsSent {
			return "", nil
		}
		if result.Data[0].DropReason.Message != "" {
			return result.Data[0].DropReason.Message, nil
		}
	}
	if result.Message != "" {
		return result.Message, nil
	}
	return "failed to send", nil
}

func (c *Client) Ban(ctx context.Context, channel, moderator, user string, duration float64, reason string) (int, map[string]any, error) {
	data := map[string]any{"user_id": user}
	if duration != 0 {
		data["duration"], data["reason"] = duration, reason
	}
	return c.DoJSON(ctx, "POST", moderationPath("/moderation/bans", channel, moderator, nil), map[string]any{"data": data})
}

func (c *Client) Unban(ctx context.Context, channel, moderator, user string) (int, map[string]any, error) {
	return c.DoJSON(ctx, "DELETE", moderationPath("/moderation/bans", channel, moderator, url.Values{"user_id": {user}}), nil)
}

func (c *Client) DeleteMessages(ctx context.Context, channel, moderator, message string) (int, map[string]any, error) {
	params := url.Values{}
	if message != "" {
		params.Set("message_id", message)
	}
	return c.DoJSON(ctx, "DELETE", moderationPath("/moderation/chat", channel, moderator, params), nil)
}

func moderationPath(path, channel, moderator string, params url.Values) string {
	if params == nil {
		params = url.Values{}
	}
	params.Set("broadcaster_id", channel)
	params.Set("moderator_id", moderator)
	return path + "?" + params.Encode()
}

func (c *Client) StartRaid(ctx context.Context, from, to string) (int, map[string]any, error) {
	return c.DoJSON(ctx, "POST", "/raids?"+url.Values{"from_broadcaster_id": {from}, "to_broadcaster_id": {to}}.Encode(), nil)
}

func (c *Client) CancelRaid(ctx context.Context, channel string) (int, map[string]any, error) {
	return c.DoJSON(ctx, "DELETE", "/raids?"+url.Values{"broadcaster_id": {channel}}.Encode(), nil)
}
