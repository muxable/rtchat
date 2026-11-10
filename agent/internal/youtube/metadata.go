package youtube

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/muxable/rtchat/agent/internal/chatmessage"
	"go.uber.org/zap"
)

// streamInfo is the channel metadata found in one InnerTube response. Nil
// fields were absent and leave the stored value unchanged.
type streamInfo struct {
	Live        *bool
	Title       *string
	DisplayName *string
	Login       *string
	Category    *string
	ViewerCount *int64
	StartedAt   *time.Time
	EndedAt     *time.Time
}

// merge overwrites s with the fields that o has.
func (s *streamInfo) merge(o streamInfo) {
	for _, f := range []struct{ dst, src **string }{{&s.Title, &o.Title}, {&s.DisplayName, &o.DisplayName}, {&s.Login, &o.Login}, {&s.Category, &o.Category}} {
		if *f.src != nil {
			*f.dst = *f.src
		}
	}
	if o.Live != nil {
		s.Live = o.Live
	}
	if o.ViewerCount != nil {
		s.ViewerCount = o.ViewerCount
	}
	if o.StartedAt != nil {
		s.StartedAt = o.StartedAt
	}
	if o.EndedAt != nil {
		s.EndedAt = o.EndedAt
	}
}

// YouTube's fixed video categories, keyed by their English names (requests
// send hl=en), so categoryId matches the Data API's snippet.categoryId.
var categoryIDs = map[string]string{
	"Film & Animation": "1", "Autos & Vehicles": "2", "Music": "10", "Pets & Animals": "15",
	"Sports": "17", "Travel & Events": "19", "Gaming": "20", "People & Blogs": "22",
	"Comedy": "23", "Entertainment": "24", "News & Politics": "25", "Howto & Style": "26",
	"Education": "27", "Science & Technology": "28", "Nonprofits & Activism": "29",
}

// channelFields are the channels/youtube:{id} fields, named like the Twitch
// and Kick channel documents. Offline streams have no onlineAt and no viewers.
// Channel search needs a login wherever there is a displayName, so channels
// without a handle use their ID.
func (c *Client) channelFields(info streamInfo, onlineAt *time.Time) map[string]interface{} {
	if info.DisplayName != nil && info.Login == nil {
		info.Login = &c.channel
	}
	data := map[string]interface{}{"onlineAt": nil, "viewerCount": int64(0)}
	if onlineAt != nil {
		data["onlineAt"] = onlineAt.UTC().Truncate(time.Millisecond)
		if info.ViewerCount != nil {
			data["viewerCount"] = *info.ViewerCount
		} else {
			delete(data, "viewerCount")
		}
	}
	if info.Title != nil {
		data["title"] = *info.Title
	}
	if info.DisplayName != nil {
		data["displayName"] = *info.DisplayName
	}
	if info.Login != nil {
		data["login"] = *info.Login
	}
	if info.Category != nil {
		data["categoryName"] = *info.Category
		if id, ok := categoryIDs[*info.Category]; ok {
			data["categoryId"] = id
		} else {
			data["categoryId"] = nil
		}
	}
	return data
}

func nonEmpty(s *string) *string {
	if s == nil || *s == "" {
		return nil
	}
	return s
}

type viewCount struct {
	Renderer *struct {
		IsLive            bool   `json:"isLive"`
		OriginalViewCount string `json:"originalViewCount"`
	} `json:"videoViewCountRenderer"`
}

// info reads the concurrent viewer count, which YouTube shows only while live.
func (v *viewCount) info() streamInfo {
	var info streamInfo
	if v == nil || v.Renderer == nil {
		return info
	}
	live := v.Renderer.IsLive
	info.Live = &live
	if n, err := strconv.ParseInt(v.Renderer.OriginalViewCount, 10, 64); err == nil && live {
		info.ViewerCount = &n
	}
	return info
}

type playerResponse struct {
	VideoDetails *struct {
		Title      *string `json:"title"`
		Author     *string `json:"author"`
		IsLive     bool    `json:"isLive"`
		IsUpcoming bool    `json:"isUpcoming"`
	} `json:"videoDetails"`
	Microformat struct {
		// The /live page only has the short microformatDataRenderer; the
		// player endpoint has the start time and handle.
		Data *struct {
			Category *string `json:"category"`
		} `json:"microformatDataRenderer"`
		Player *struct {
			Category             *string `json:"category"`
			OwnerProfileURL      string  `json:"ownerProfileUrl"`
			OwnerChannelName     *string `json:"ownerChannelName"`
			LiveBroadcastDetails *struct {
				IsLiveNow      bool   `json:"isLiveNow"`
				StartTimestamp string `json:"startTimestamp"`
				EndTimestamp   string `json:"endTimestamp"`
			} `json:"liveBroadcastDetails"`
		} `json:"playerMicroformatRenderer"`
	} `json:"microformat"`
}

func (p *playerResponse) info() streamInfo {
	var info streamInfo
	if d := p.VideoDetails; d != nil {
		live := d.IsLive && !d.IsUpcoming
		info.Live = &live
		info.Title = nonEmpty(d.Title)
		info.DisplayName = nonEmpty(d.Author)
	}
	if m := p.Microformat.Data; m != nil {
		info.Category = nonEmpty(m.Category)
	}
	if m := p.Microformat.Player; m != nil {
		if c := nonEmpty(m.Category); c != nil {
			info.Category = c
		}
		if name := nonEmpty(m.OwnerChannelName); name != nil {
			info.DisplayName = name
		}
		info.Login = handle(m.OwnerProfileURL)
		if b := m.LiveBroadcastDetails; b != nil {
			if t, err := time.Parse(time.RFC3339, b.StartTimestamp); err == nil && b.IsLiveNow {
				info.StartedAt = &t
			}
			if t, err := time.Parse(time.RFC3339, b.EndTimestamp); err == nil && !b.IsLiveNow {
				info.EndedAt = &t
			}
		}
	}
	return info
}

var playerPattern = regexp.MustCompile(`(?:window\s*\[\s*["']ytInitialPlayerResponse["']\s*\]|var\s+ytInitialPlayerResponse)\s*=\s*`)

// handle returns the @handle of a channel URL such as
// http://www.youtube.com/@LofiGirl.
func handle(profile string) *string {
	u, err := url.Parse(profile)
	if err != nil || !strings.HasPrefix(u.Path, "/@") || len(u.Path) == 2 || strings.Contains(u.Path[2:], "/") {
		return nil
	}
	login := u.Path[2:]
	return &login
}

// pageInfo reads the metadata embedded in the /channel/{id}/live page that
// discovery already fetched: a watch page while live, else the channel page.
func pageInfo(html []byte) (streamInfo, error) {
	var info streamInfo
	if loc := playerPattern.FindIndex(html); loc != nil {
		var player playerResponse
		if err := json.NewDecoder(bytes.NewReader(html[loc[1]:])).Decode(&player); err != nil {
			return info, err
		}
		info = player.info()
	}
	loc := initialPattern.FindIndex(html)
	if loc == nil {
		return info, fmt.Errorf("missing ytInitialData")
	}
	var data struct {
		Contents struct {
			Watch struct {
				Results struct {
					Results struct {
						Contents []struct {
							Primary *struct {
								Title     *text      `json:"title"`
								ViewCount *viewCount `json:"viewCount"`
							} `json:"videoPrimaryInfoRenderer"`
						} `json:"contents"`
					} `json:"results"`
				} `json:"results"`
			} `json:"twoColumnWatchNextResults"`
		} `json:"contents"`
		Metadata struct {
			Channel *struct {
				Title     *string `json:"title"`
				VanityURL string  `json:"vanityChannelUrl"`
			} `json:"channelMetadataRenderer"`
		} `json:"metadata"`
	}
	if err := json.NewDecoder(bytes.NewReader(html[loc[1]:])).Decode(&data); err != nil {
		return info, err
	}
	for _, content := range data.Contents.Watch.Results.Results.Contents {
		if content.Primary != nil {
			viewers := content.Primary.ViewCount.info()
			viewers.Live = nil // videoDetails decides whether the stream is live.
			info.merge(viewers)
			// A bot-checked page has no videoDetails, but still renders the title.
			if info.Title == nil && content.Primary.Title != nil {
				title := content.Primary.Title.plain()
				info.Title = nonEmpty(&title)
			}
		}
	}
	if channel := data.Metadata.Channel; channel != nil {
		info.DisplayName = nonEmpty(channel.Title)
		info.Login = handle(channel.VanityURL)
	}
	return info, nil
}

func updatedMetadataInfo(body []byte) (streamInfo, error) {
	var response struct {
		Actions []struct {
			Viewership *struct {
				ViewCount *viewCount `json:"viewCount"`
			} `json:"updateViewershipAction"`
			Title *struct {
				Title *text `json:"title"`
			} `json:"updateTitleAction"`
		} `json:"actions"`
	}
	var info streamInfo
	if err := json.Unmarshal(body, &response); err != nil {
		return info, err
	}
	for _, action := range response.Actions {
		if action.Viewership != nil {
			info.merge(action.Viewership.ViewCount.info())
		}
		if action.Title != nil {
			if action.Title.Title != nil {
				title := action.Title.Title.plain()
				info.Title = nonEmpty(&title)
			}
		}
	}
	return info, nil
}

func playerInfo(body []byte) (streamInfo, error) {
	var player playerResponse
	if err := json.Unmarshal(body, &player); err != nil {
		return streamInfo{}, err
	}
	return player.info(), nil
}

func (c *Client) innertube(ctx context.Context, endpoint, key, version, video string, parse func([]byte) (streamInfo, error)) (streamInfo, error) {
	body, err := json.Marshal(map[string]interface{}{"context": map[string]interface{}{"client": map[string]string{"clientName": "WEB", "clientVersion": version, "hl": "en"}}, "videoId": video})
	if err != nil {
		return streamInfo{}, err
	}
	response, err := c.request(ctx, http.MethodPost, "/youtubei/v1/"+endpoint+"?key="+url.QueryEscape(key)+"&prettyPrint=false", body)
	if err != nil {
		return streamInfo{}, err
	}
	info, err := parse(response)
	if err != nil {
		c.counts.parseFailures.Add(1)
	}
	return info, err
}

// player returns the stream's start time, English category and handle. The
// stream itself is unplayable without a PO token, but the metadata is there.
func (c *Client) player(ctx context.Context, key, version, video string) (streamInfo, error) {
	return c.innertube(ctx, "player", key, version, video, playerInfo)
}

// updatedMetadata is what the watch page polls for its live viewer count and title.
func (c *Client) updatedMetadata(ctx context.Context, key, version, video string) (streamInfo, error) {
	return c.innertube(ctx, "updated_metadata", key, version, video, updatedMetadataInfo)
}

func onlineAt(info streamInfo) *time.Time {
	if info.StartedAt != nil {
		return info.StartedAt
	}
	now := time.Now()
	return &now
}

// streamMessage writes the stream.online or stream.offline message that
// Twitch and Kick also write; the app derives live state and uptime from
// them. IDs are per video so a reader taking over does not repeat them.
func (c *Client) streamMessage(ctx context.Context, video, kind string, at time.Time) bool {
	data := map[string]interface{}{
		"channelId": "youtube:" + c.channel, "type": "stream." + kind,
		"timestamp": at.UTC().Truncate(time.Millisecond),
		"expiresAt": time.Now().UTC().Truncate(time.Millisecond).Add(chatmessage.StreamStateTTL),
		"event":     map[string]interface{}{"videoId": video},
	}
	return c.retryWrite(ctx, func() error { return c.store.Create(ctx, "youtube:"+c.channel, "youtube:"+video+":"+kind, data) })
}

// session reads one video's chat while keeping channels/youtube:{id} current.
// It reports whether the stream is still live after its chat ended; otherwise
// the caller marks the channel offline.
func (c *Client) session(ctx context.Context, video, key, version string, page chatPage, watch []byte) bool {
	info, err := pageInfo(watch)
	if err != nil {
		zap.L().Debug("YouTube watch page metadata unavailable", zap.String("channel", c.channel), zap.Error(err))
	}
	if player, err := c.player(ctx, key, version, video); err == nil {
		info.merge(player)
	} else {
		zap.L().Warn("YouTube player metadata failed", zap.String("channel", c.channel), zap.Error(err))
	}
	var online *time.Time
	write := func(ctx context.Context, info streamInfo) bool {
		data := c.channelFields(info, online)
		return c.retryWrite(ctx, func() error { return c.store.Merge(ctx, "youtube:"+c.channel, data) })
	}
	goLive := func(ctx context.Context, info streamInfo) bool {
		online = onlineAt(info)
		return c.streamMessage(ctx, video, "online", *online)
	}
	// Without metadata, assume a video with an open chat is live.
	if (info.Live == nil || *info.Live) && !goLive(ctx, info) {
		return false
	}
	if !write(ctx, info) {
		return false
	}
	metaCtx, cancel := context.WithCancel(ctx)
	done := make(chan struct{})
	go func() {
		defer close(done)
		for wait(metaCtx, c.metadataInterval) {
			update, err := c.updatedMetadata(metaCtx, key, version, video)
			if err != nil {
				zap.L().Warn("YouTube metadata update failed", zap.String("channel", c.channel), zap.Error(err))
				continue
			}
			if update.Live != nil && *update.Live != (online != nil) {
				if online != nil {
					// The stream ends with its chat; ignore a stale count until then.
					update.ViewerCount = nil
				} else {
					// An upcoming stream went live.
					if player, err := c.player(metaCtx, key, version, video); err == nil {
						player.merge(update)
						update = player
					} else {
						zap.L().Warn("YouTube player metadata failed", zap.String("channel", c.channel), zap.Error(err))
					}
					if !goLive(metaCtx, update) {
						return
					}
				}
			}
			if !write(metaCtx, update) {
				return
			}
		}
	}()
	c.stream(ctx, video, key, version, page)
	cancel()
	<-done
	if online == nil || ctx.Err() != nil {
		return false
	}
	// Chat can stop without the stream ending, so confirm before going offline.
	ended := time.Now()
	if player, err := c.player(ctx, key, version, video); err == nil {
		if player.Live != nil && *player.Live {
			return true
		}
		if player.EndedAt != nil {
			ended = *player.EndedAt
		}
	} else {
		zap.L().Warn("YouTube player metadata failed", zap.String("channel", c.channel), zap.Error(err))
	}
	c.streamMessage(ctx, video, "offline", ended)
	return false
}
