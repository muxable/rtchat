package youtube

import (
	"context"
	"math"
	"net/http"
	"net/url"
	"regexp"

	"github.com/muxable/rtchat/agent/internal/clients"
)

// APIError exposes only the status and provider reason needed for error mapping.
// Provider messages and response bodies may contain private data.
type APIError struct {
	Status int
	Reason string
}

func (e *APIError) Error() string { return (&clients.HTTPError{Status: e.Status}).Error() }

func (c *Client) request(ctx context.Context, method, path string, body, out any) error {
	response, err := c.Do(ctx, method, path, body)
	if err != nil {
		return err
	}
	if response.StatusCode >= 400 {
		var payload struct {
			Error struct {
				Errors []struct{ Reason string }
				Status string
			}
		}
		_ = response.Decode(&payload)
		reason := payload.Error.Status
		if len(payload.Error.Errors) > 0 && payload.Error.Errors[0].Reason != "" {
			reason = payload.Error.Errors[0].Reason
		}
		return &APIError{Status: response.StatusCode, Reason: reason}
	}
	if err := response.Err(); err != nil {
		return err
	}
	if len(response.Body) == 0 {
		return nil
	}
	var result any
	if out == nil {
		out = &result
	}
	return response.Decode(out)
}

func (c *Client) DeleteMessage(ctx context.Context, id string) error {
	return c.request(ctx, "DELETE", "/liveChat/messages?"+url.Values{"id": {id}}.Encode(), nil, nil)
}

func (c *Client) SendMessage(ctx context.Context, chat, message string) error {
	snippet := map[string]any{"liveChatId": chat, "type": "textMessageEvent", "textMessageDetails": map[string]any{"messageText": message}}
	return c.request(ctx, "POST", "/liveChat/messages?part=snippet", map[string]any{"snippet": snippet}, nil)
}

func (c *Client) Ban(ctx context.Context, chat, user string, seconds float64) error {
	snippet := map[string]any{"liveChatId": chat, "type": "permanent", "bannedUserDetails": map[string]any{"channelId": user}}
	if seconds != 0 {
		snippet["type"], snippet["banDurationSeconds"] = "temporary", math.Max(1, math.Ceil(seconds))
	}
	return c.request(ctx, "POST", "/liveChat/bans?part=snippet", map[string]any{"snippet": snippet}, nil)
}

var canonicalPattern = regexp.MustCompile(`<link[^>]+rel="canonical"[^>]+href="https://www\.youtube\.com/watch\?v=([A-Za-z0-9_-]{11})"`)

// LiveChat discovers an active chat, optionally for an explicit video. Owned
// channels first use liveBroadcasts, which also supports unlisted broadcasts.
func (c *Client) LiveChat(ctx context.Context, channel string, video *string, owned bool) (string, error) {
	if video == nil && owned {
		var broadcasts struct {
			Items []struct {
				Snippet struct{ LiveChatID, ChannelID string }
			}
		}
		if err := c.request(ctx, "GET", "/liveBroadcasts?part=snippet&broadcastStatus=active&broadcastType=all&maxResults=50", nil, &broadcasts); err != nil {
			return "", err
		}
		for _, b := range broadcasts.Items {
			if b.Snippet.LiveChatID != "" && (b.Snippet.ChannelID == "" || b.Snippet.ChannelID == channel) {
				return b.Snippet.LiveChatID, nil
			}
		}
	}
	var id string
	if video != nil {
		id = *video
	} else {
		discovery := clients.Client{HTTP: c.HTTP, BaseURL: "https://www.youtube.com", Headers: http.Header{"Accept-Language": {"en"}}}
		response, err := discovery.Do(ctx, "GET", "/channel/"+url.PathEscape(channel)+"/live", nil)
		if err != nil {
			return "", err
		}
		if response.Err() != nil {
			return "", nil
		}
		match := canonicalPattern.FindSubmatch(response.Body)
		if len(match) < 2 {
			return "", nil
		}
		id = string(match[1])
	}
	if id == "" {
		return "", nil
	}
	var videos struct {
		Items []struct {
			Snippet              struct{ ChannelID string }
			LiveStreamingDetails struct{ ActiveLiveChatID string }
		}
	}
	if err := c.request(ctx, "GET", "/videos?"+url.Values{"part": {"liveStreamingDetails,snippet"}, "id": {id}}.Encode(), nil, &videos); err != nil {
		return "", err
	}
	if len(videos.Items) == 0 {
		return "", nil
	}
	v := videos.Items[0]
	if v.Snippet.ChannelID != "" && v.Snippet.ChannelID != channel {
		return "", nil
	}
	return v.LiveStreamingDetails.ActiveLiveChatID, nil
}
