package twitch

import (
	"context"
	"net/url"
	"regexp"
	"strings"
	"time"
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

func (c *Client) Ban(ctx context.Context, channel, moderator, user string, duration float64, reason string) error {
	data := map[string]any{"user_id": user}
	if duration != 0 {
		data["duration"], data["reason"] = duration, reason
	}
	action := "ban"
	if duration != 0 {
		action = "timeout"
	}
	return c.writeBan(ctx, action, "POST", moderationPath("/moderation/bans", channel, moderator, nil), map[string]any{"data": data})
}

func (c *Client) Unban(ctx context.Context, channel, moderator, user string) error {
	return c.writeBan(ctx, "unban", "DELETE", moderationPath("/moderation/bans", channel, moderator, url.Values{"user_id": {user}}), nil)
}

// ModerationRejected is a refusal of a moderation action by Twitch.
// Other provider failures retain their redacted HTTP error for reporting.
type ModerationRejected struct{ Message string }

func (e *ModerationRejected) Error() string { return e.Message }

// Helix describes a malformed request in terms of its parameters, while a
// refusal describes the target user. Malformed requests are agent bugs.
var malformedRequest = regexp.MustCompile(`parameter|required|malformed|valid`)

func (c *Client) writeBan(ctx context.Context, action, method, path string, body any) error {
	response, err := c.Do(ctx, method, path, body)
	if err != nil {
		return err
	}
	if response.StatusCode == 400 {
		var result struct{ Message string }
		if response.Decode(&result) == nil {
			// Prefer stable, specific messages for recognized ban-state rejections.
			switch strings.TrimSuffix(strings.ToLower(strings.TrimSpace(result.Message)), ".") {
			case "user is already banned", "the user specified in the user_id field is already banned":
				return &ModerationRejected{Message: "This user is already banned."}
			case "user is not banned", "the user specified in the user_id query parameter is not banned":
				return &ModerationRejected{Message: "This user is not banned."}
			case "user may not be banned", "the user specified in the user_id field may not be banned":
				return &ModerationRejected{Message: "Twitch does not allow banning this user."}
			case "user may not be put in a timeout", "the user specified in the user_id field may not be put in a timeout":
				return &ModerationRejected{Message: "Twitch does not allow timing out this user."}
			}
			// The request carries only resolved IDs and locally validated timeout
			// fields, so any other rejection is Twitch refusing the action, even
			// when it changes its wording. Never expose raw text.
			message := strings.ToLower(strings.TrimSpace(result.Message))
			if message != "" && !malformedRequest.MatchString(message) {
				return &ModerationRejected{Message: "Twitch rejected this " + action + " request."}
			}
		}
	}
	return response.Err()
}

func (c *Client) DeleteMessages(ctx context.Context, channel, moderator, message string) error {
	params := url.Values{}
	if message != "" {
		params.Set("message_id", message)
	}
	return c.write(ctx, "DELETE", moderationPath("/moderation/chat", channel, moderator, params), nil)
}

func moderationPath(path, channel, moderator string, params url.Values) string {
	if params == nil {
		params = url.Values{}
	}
	params.Set("broadcaster_id", channel)
	params.Set("moderator_id", moderator)
	return path + "?" + params.Encode()
}

// RaidRejected is Twitch's reason for refusing to start or cancel a raid, e.g.
// because the target doesn't accept raids or there is no raid to cancel.
type RaidRejected struct{ Message string }

func (e *RaidRejected) Error() string { return e.Message }

func (c *Client) StartRaid(ctx context.Context, from, to string) (time.Time, error) {
	response, err := c.Do(ctx, "POST", "/raids?"+url.Values{"from_broadcaster_id": {from}, "to_broadcaster_id": {to}}.Encode(), nil)
	if err != nil {
		return time.Time{}, err
	}
	if response.StatusCode == 400 {
		var result struct{ Message string }
		if response.Decode(&result) == nil && result.Message != "" {
			return time.Time{}, &RaidRejected{Message: result.Message}
		}
	}
	if err := response.Err(); err != nil {
		return time.Time{}, err
	}
	var result struct {
		Data []struct {
			CreatedAt string `json:"created_at"`
		}
	}
	if err := response.Decode(&result); err != nil {
		return time.Time{}, err
	}
	if len(result.Data) == 0 {
		return time.Time{}, nil
	}
	started, _ := time.Parse(time.RFC3339Nano, result.Data[0].CreatedAt)
	return started, nil
}

// CancelRaid returns a RaidRejected with Twitch's message when there is no
// pending raid to cancel, e.g. because it already went through.
func (c *Client) CancelRaid(ctx context.Context, channel string) error {
	response, err := c.Do(ctx, "DELETE", "/raids?"+url.Values{"broadcaster_id": {channel}}.Encode(), nil)
	if err != nil {
		return err
	}
	if response.StatusCode == 404 {
		var result struct{ Message string }
		if response.Decode(&result) == nil && result.Message != "" {
			return &RaidRejected{Message: result.Message}
		}
		return &RaidRejected{Message: "no pending raid"}
	}
	return response.Err()
}

// Shoutout returns an empty reason when accepted, or Twitch's message when
// rejected, e.g. because the channel is offline or on cooldown.
func (c *Client) Shoutout(ctx context.Context, from, to, moderator string) (string, error) {
	response, err := c.Do(ctx, "POST", "/chat/shoutouts?"+url.Values{"from_broadcaster_id": {from}, "to_broadcaster_id": {to}, "moderator_id": {moderator}}.Encode(), nil)
	if err != nil {
		return "", err
	}
	if response.StatusCode == 400 || response.StatusCode == 429 {
		var result struct{ Message string }
		if response.Decode(&result) == nil && result.Message != "" {
			return result.Message, nil
		}
	}
	return "", response.Err()
}

func (c *Client) write(ctx context.Context, method, path string, body any) error {
	response, err := c.Do(ctx, method, path, body)
	if err != nil {
		return err
	}
	return response.Err()
}
