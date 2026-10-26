package jobs

import (
	"context"
	"errors"
	"fmt"
	"go.uber.org/zap"
	"math"
	"math/rand"
	"net/http"
	"reflect"
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
	return map[string]interface{}{"login": c.Slug, "title": kickValue(c.Title), "language": kickValue(c.Stream.Language), "categoryId": kickValue(c.Category.ID), "categoryName": kickValue(c.Category.Name), "viewerCount": viewers, "onlineAt": online}, nil
}

// kickValue stores integral JSON numbers as int64, matching the Kick
// webhook's kickFirestoreValue, so a poll after a webhook is not a type change.
func kickValue(value interface{}) interface{} {
	if v, ok := value.(float64); ok && math.Abs(v) <= 9007199254740991 && math.Trunc(v) == v && !(v == 0 && math.Signbit(v)) {
		return int64(v)
	}
	return value
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
		if err := a.twitch(ctx, http.MethodGet, "/users", params("login", logins[start:end]), &result); err != nil {
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
		if err := a.twitch(ctx, http.MethodGet, "/streams", q, &streams); err != nil {
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
			if err := a.twitch(ctx, http.MethodGet, "/channels", params("broadcaster_id", missing), &channels); err != nil {
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
		if err := a.twitch(ctx, http.MethodGet, "/channels/followers", q, &result); err != nil {
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
	// Assignments, when set, replaces reading the assignments collection.
	Assignments *Assignments

	twitchCache, kickCache channelCache
}

func (s *Service) twitchLogins(ctx context.Context) ([]string, error) {
	if logins, ok := s.Assignments.Logins("twitch:"); ok {
		return logins, nil
	}
	docs, err := s.Client.Collection("assignments").Documents(ctx).GetAll()
	if err != nil {
		return nil, err
	}
	var logins []string
	for _, doc := range docs {
		if strings.HasPrefix(doc.Ref.ID, "twitch:") {
			logins = append(logins, strings.TrimPrefix(doc.Ref.ID, "twitch:"))
		}
	}
	return logins, nil
}

// TwitchFinished and KickFinished take the runner's result for each slot,
// which decides whether the next slot may reuse this replica's cache.
func (s *Service) TwitchFinished(slot string, success bool) { s.twitchCache.end(slot, success) }
func (s *Service) KickFinished(slot string, success bool)   { s.kickCache.end(slot, success) }

func (s *Service) Twitch(ctx context.Context) error {
	started := time.Now()
	s.twitchCache.begin(RunSlot(ctx))
	logins, err := s.twitchLogins(ctx)
	if err != nil {
		return err
	}
	var written int
	err = s.API.FetchTwitch(ctx, logins, func(updates []ChannelUpdate) error {
		n, err := s.write(ctx, &s.twitchCache, started, updates)
		written += n
		return err
	})
	logRefresh("twitch", len(logins), written)
	return err
}
func (s *Service) Kick(ctx context.Context) error {
	started := time.Now()
	s.kickCache.begin(RunSlot(ctx))
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
	var written int
	defer func() { logRefresh("kick", len(ids), written) }()
	for start := 0; start < len(ids); start += 50 {
		var result struct {
			Data []KickChannel `json:"data"`
		}
		if err := s.API.kick(ctx, http.MethodGet, "/channels", params("broadcaster_user_id", ids[start:min(start+50, len(ids))]), &result); err != nil {
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
		n, err := s.write(ctx, &s.kickCache, started, updates)
		written += n
		if err != nil {
			return err
		}
	}
	return nil
}

// logRefresh records how many channels a metadata job polled and wrote, so a
// job that completes without writing anything is visible.
func logRefresh(provider string, channels, written int) {
	zap.L().Info("channel metadata refreshed", zap.String("provider", provider), zap.Int("channels", channels), zap.Int("written", written))
}

// write returns the number of channel documents it updated. A nil cache
// checks every update in a transaction.
func (s *Service) write(ctx context.Context, cache *channelCache, started time.Time, updates []ChannelUpdate) (int, error) {
	var written int
	for _, update := range updates {
		checked := time.Now()
		// The doc matched these values at this replica's last transaction.
		if cache.fresh(update.ID, update.Data, checked) {
			continue
		}
		skipped := false
		var after map[string]interface{}
		ref := s.Client.Collection("channels").Doc(update.ID)
		err := s.Client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
			after = nil
			doc, err := tx.Get(ref)
			if err != nil && status.Code(err) != codes.NotFound {
				return err
			}
			// A newer webhook wins over a poll that started before it. Follower-only
			// writes do not touch stream metadata and may proceed independently.
			skipped = err == nil && doc.UpdateTime.After(started) && len(update.Data) > 1
			if skipped {
				return nil
			}
			after = map[string]interface{}{}
			if err == nil {
				after = doc.Data()
			}
			// Unchanged data still costs a billed write, so leave the doc alone.
			if err == nil && unchanged(after, update.Data) {
				skipped = true
				return nil
			}
			for field, value := range update.Data {
				after[field] = value
			}
			return tx.Set(ref, update.Data, firestore.MergeAll)
		})
		if err != nil {
			cache.store(update.ID, nil, checked)
			return written, err
		}
		cache.store(update.ID, after, checked)
		if !skipped {
			written++
		}
	}
	return written, nil
}

// unchanged reports whether merging update into current would leave every
// field as it is. Types must match: Firestore stores int64 and float64 as
// distinct types, so a type change is a real write.
func unchanged(current, update map[string]interface{}) bool {
	for field, value := range update {
		existing, ok := current[field]
		if !ok || !sameValue(existing, value) {
			return false
		}
	}
	return true
}

func sameValue(a, b interface{}) bool {
	if at, ok := a.(time.Time); ok {
		bt, ok := b.(time.Time)
		return ok && at.Equal(bt)
	}
	return reflect.DeepEqual(a, b)
}
