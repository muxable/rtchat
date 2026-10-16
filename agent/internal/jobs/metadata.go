package jobs

import (
	"context"
	"errors"
	"fmt"
	"go.uber.org/zap"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type ChannelUpdate struct {
	ID   string
	Data map[string]interface{}
}
type TwitchUser struct {
	ID string `json:"id"`
}
type TwitchStream struct {
	ID        string    `json:"user_id"`
	Login     string    `json:"user_login"`
	Name      string    `json:"user_name"`
	Language  string    `json:"language"`
	Viewers   int64     `json:"viewer_count"`
	StartedAt time.Time `json:"started_at"`
}
type TwitchChannel struct {
	ID       string `json:"broadcaster_id"`
	Login    string `json:"broadcaster_login"`
	Name     string `json:"broadcaster_name"`
	Language string `json:"broadcaster_language"`
}
type KickChannel struct {
	ID       int64       `json:"broadcaster_user_id"`
	Slug     string      `json:"slug"`
	Title    interface{} `json:"stream_title"`
	Category struct {
		ID   interface{} `json:"id"`
		Name interface{} `json:"name"`
	} `json:"category"`
	Stream struct {
		Language interface{} `json:"language"`
		Live     bool        `json:"is_live"`
		Viewers  int64       `json:"viewer_count"`
		Start    string      `json:"start_time"`
	} `json:"stream"`
}

func (c KickChannel) Metadata() (map[string]interface{}, error) {
	var online interface{}
	var viewers int64
	if c.Stream.Live {
		viewers = c.Stream.Viewers
		if c.Stream.Start != "" {
			at, err := time.Parse(time.RFC3339Nano, c.Stream.Start)
			if err != nil {
				return nil, err
			}
			online = at.UTC().Truncate(time.Millisecond)
		}
	}
	return map[string]interface{}{"login": c.Slug, "title": c.Title, "language": c.Stream.Language, "categoryId": c.Category.ID, "categoryName": c.Category.Name, "viewerCount": viewers, "onlineAt": online}, nil
}

// FetchTwitch preserves stream/offline metadata fields and samples at most
// 200 followers, using an app token exactly as the previous function did.
func (a *API) FetchTwitch(ctx context.Context, logins []string, write func([]ChannelUpdate) error) error {
	var ids []string
	for start := 0; start < len(logins); start += 100 {
		end := min(start+100, len(logins))
		var result struct {
			Data []TwitchUser `json:"data"`
		}
		if err := a.request(ctx, "twitch", http.MethodGet, "/users", params("login", logins[start:end]), &result); err != nil {
			return err
		}
		if result.Data == nil {
			return fmt.Errorf("Twitch users response missing data")
		}
		for _, u := range result.Data {
			ids = append(ids, u.ID)
		}
	}
	for start := 0; start < len(ids); start += 100 {
		batch := ids[start:min(start+100, len(ids))]
		q := params("user_id", batch)
		q.Set("first", "100")
		var streams struct {
			Data []TwitchStream `json:"data"`
		}
		if err := a.request(ctx, "twitch", http.MethodGet, "/streams", q, &streams); err != nil {
			return err
		}
		if streams.Data == nil {
			return fmt.Errorf("Twitch streams response missing data")
		}
		seen := map[string]bool{}
		var updates []ChannelUpdate
		for _, s := range streams.Data {
			seen[s.ID] = true
			updates = append(updates, ChannelUpdate{"twitch:" + s.ID, map[string]interface{}{"viewerCount": s.Viewers, "language": s.Language, "login": s.Login, "displayName": s.Name, "onlineAt": s.StartedAt.UTC().Truncate(time.Millisecond)}})
		}
		var missing []string
		for _, id := range batch {
			if !seen[id] {
				missing = append(missing, id)
			}
		}
		if len(missing) > 0 {
			var channels struct {
				Data []TwitchChannel `json:"data"`
			}
			if err := a.request(ctx, "twitch", http.MethodGet, "/channels", params("broadcaster_id", missing), &channels); err != nil {
				return err
			}
			if channels.Data == nil {
				return fmt.Errorf("Twitch channels response missing data")
			}
			for _, c := range channels.Data {
				updates = append(updates, ChannelUpdate{"twitch:" + c.ID, map[string]interface{}{"viewerCount": int64(0), "language": c.Language, "login": c.Login, "displayName": c.Name, "onlineAt": nil}})
			}
		}
		if err := write(updates); err != nil {
			return err
		}
	}
	rand.Shuffle(len(ids), func(i, j int) { ids[i], ids[j] = ids[j], ids[i] })
	for _, id := range ids[:min(200, len(ids))] {
		q := params("broadcaster_id", []string{id})
		q.Set("first", "1")
		var result struct {
			Total *int64 `json:"total"`
		}
		if err := a.request(ctx, "twitch", http.MethodGet, "/channels/followers", q, &result); err != nil {
			var apiErr *HTTPError
			// App tokens can read totals only where Twitch grants access. Do not
			// invent a broadcaster scope or stop refreshing the other channels.
			if errors.As(err, &apiErr) && (apiErr.Status == 401 || apiErr.Status == 403) {
				zap.L().Warn("follower count unavailable with app token", zap.String("channel", id), zap.Int("status", apiErr.Status))
				continue
			}
			return err
		}
		if result.Total != nil && *result.Total > 0 {
			if err := write([]ChannelUpdate{{"twitch:" + id, map[string]interface{}{"followerCount": *result.Total}}}); err != nil {
				return err
			}
		}
	}
	return nil
}
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

type Service struct {
	Client *firestore.Client
	API    *API
}

func (s *Service) Twitch(ctx context.Context) error {
	docs, err := s.Client.Collection("assignments").Documents(ctx).GetAll()
	if err != nil {
		return err
	}
	var logins []string
	for _, doc := range docs {
		if strings.HasPrefix(doc.Ref.ID, "twitch:") {
			logins = append(logins, strings.TrimPrefix(doc.Ref.ID, "twitch:"))
		}
	}
	started := time.Now()
	return s.API.FetchTwitch(ctx, logins, func(updates []ChannelUpdate) error { return s.write(ctx, started, updates) })
}
func (s *Service) Kick(ctx context.Context) error {
	started := time.Now()
	docs, err := s.Client.Collection("webhooks").Where("lastActiveAt", ">", started.Add(-24*time.Hour)).Documents(ctx).GetAll()
	if err != nil {
		return err
	}
	var ids []string
	for _, doc := range docs {
		if strings.HasPrefix(doc.Ref.ID, "kick:") {
			ids = append(ids, strings.TrimPrefix(doc.Ref.ID, "kick:"))
		}
	}
	for start := 0; start < len(ids); start += 50 {
		var result struct {
			Data []KickChannel `json:"data"`
		}
		if err := s.API.request(ctx, "kick", http.MethodGet, "/channels", params("broadcaster_user_id", ids[start:min(start+50, len(ids))]), &result); err != nil {
			return err
		}
		if result.Data == nil {
			return fmt.Errorf("Kick channels response missing data")
		}
		var updates []ChannelUpdate
		for _, c := range result.Data {
			data, err := c.Metadata()
			if err != nil {
				return fmt.Errorf("kick metadata %d: %w", c.ID, err)
			}
			updates = append(updates, ChannelUpdate{"kick:" + strconv.FormatInt(c.ID, 10), data})
		}
		if err := s.write(ctx, started, updates); err != nil {
			return err
		}
	}
	return nil
}
func (s *Service) write(ctx context.Context, started time.Time, updates []ChannelUpdate) error {
	for _, update := range updates {
		ref := s.Client.Collection("channels").Doc(update.ID)
		err := s.Client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
			doc, err := tx.Get(ref)
			if err != nil && status.Code(err) != codes.NotFound {
				return err
			}
			// A newer webhook wins over a poll that started before it. Follower-only
			// writes do not touch stream metadata and may proceed independently.
			if err == nil && doc.UpdateTime.After(started) && len(update.Data) > 1 {
				return nil
			}
			return tx.Set(ref, update.Data, firestore.MergeAll)
		})
		if err != nil {
			return err
		}
	}
	return nil
}
