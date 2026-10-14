package webhook

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// twitchStats ports the single-channel call to runUpdateFollowerAndViewerCount.
// Keep its input unchanged: eventsub.ts passes the prefixed Firestore channel ID
// to Helix (and prefixes it again when writing returned follower counts).
type twitchStats struct {
	store        twitchStore
	client       *http.Client
	clientID     string
	clientSecret string
}

func (s twitchStats) get(ctx context.Context, token, path string, query url.Values, result interface{}) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://api.twitch.tv/helix/"+path+"?"+query.Encode(), nil)
	if err != nil {
		return err
	}
	req.Header.Set("Client-ID", s.clientID)
	req.Header.Set("Authorization", "Bearer "+token)
	response, err := s.client.Do(req)
	if err != nil {
		return err
	}
	defer response.Body.Close()
	// The TS reads JSON even for unsuccessful Helix responses; missing data or
	// total produces no writes.
	return json.NewDecoder(response.Body).Decode(result)
}

func (s twitchStats) refresh(ctx context.Context, channelID string) error {
	form := url.Values{"client_id": {s.clientID}, "client_secret": {s.clientSecret}, "grant_type": {"client_credentials"}, "scope": {}}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://id.twitch.tv/oauth2/token", strings.NewReader(form.Encode()))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	response, err := s.client.Do(req)
	if err != nil {
		return err
	}
	var token struct {
		AccessToken string `json:"access_token"`
	}
	err = json.NewDecoder(response.Body).Decode(&token)
	response.Body.Close()
	if err != nil {
		return err
	}
	if response.StatusCode != http.StatusOK || token.AccessToken == "" {
		return fmt.Errorf("twitch app token request failed: %d", response.StatusCode)
	}
	var streams struct {
		Data []struct {
			UserID      string `json:"user_id"`
			ViewerCount int64  `json:"viewer_count"`
			Language    string `json:"language"`
			Login       string `json:"user_login"`
			DisplayName string `json:"user_name"`
			StartedAt   string `json:"started_at"`
		} `json:"data"`
	}
	if err := s.get(ctx, token.AccessToken, "streams", url.Values{"first": {"100"}, "user_id": {channelID}}, &streams); err != nil {
		return err
	}
	writes := []twitchDocument{}
	found := false
	if streams.Data != nil {
		for _, stream := range streams.Data {
			onlineAt, err := time.Parse(time.RFC3339Nano, stream.StartedAt)
			if err != nil {
				return err
			}
			writes = append(writes, twitchDocument{Path: "channels/twitch:" + stream.UserID, Merge: true, Data: map[string]interface{}{
				"viewerCount": stream.ViewerCount, "language": stream.Language, "login": stream.Login, "displayName": stream.DisplayName, "onlineAt": onlineAt.Truncate(time.Millisecond),
			}})
			found = found || stream.UserID == channelID
		}
		if !found {
			var channels struct {
				Data []struct {
					ID          string `json:"broadcaster_id"`
					Language    string `json:"broadcaster_language"`
					Login       string `json:"broadcaster_login"`
					DisplayName string `json:"broadcaster_name"`
				} `json:"data"`
			}
			if err := s.get(ctx, token.AccessToken, "channels", url.Values{"broadcaster_id": {channelID}}, &channels); err != nil {
				return err
			}
			for _, channel := range channels.Data {
				writes = append(writes, twitchDocument{Path: "channels/twitch:" + channel.ID, Merge: true, Data: map[string]interface{}{
					"viewerCount": int64(0), "language": channel.Language, "login": channel.Login, "displayName": channel.DisplayName, "onlineAt": nil,
				}})
			}
		}
	}
	var followers struct {
		Total int64 `json:"total"`
	}
	if err := s.get(ctx, token.AccessToken, "channels/followers", url.Values{"broadcaster_id": {channelID}, "first": {"1"}}, &followers); err != nil {
		return err
	}
	if followers.Total != 0 {
		writes = append(writes, twitchDocument{Path: "channels/twitch:" + channelID, Merge: true, Data: map[string]interface{}{"followerCount": followers.Total}})
	}
	// TS commits these statistics together after all requests succeed.
	return s.store.mergeBatch(ctx, writes)
}
