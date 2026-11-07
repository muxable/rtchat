package jobs

import (
	"context"
	"errors"
	"fmt"
	"maps"
	"math"
	"math/rand"
	"net/http"
	"reflect"
	"strconv"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"go.uber.org/zap"
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
	var followers []ChannelUpdate
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
			followers = append(followers, ChannelUpdate{"twitch:" + id, map[string]interface{}{"followerCount": *result.Total}})
		}
	}
	return write(followers)
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
	var written int
	err = s.API.FetchTwitch(ctx, logins, func(updates []ChannelUpdate) error {
		n, err := s.write(ctx, started, updates)
		written += n
		return err
	})
	logRefresh("twitch", len(logins), written)
	return err
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
		n, err := s.write(ctx, started, updates)
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

// write returns the number of channel documents it updated. It reads every
// document in one call and writes the changed ones together, each on the
// condition that it is still the version read.
func (s *Service) write(ctx context.Context, started time.Time, updates []ChannelUpdate) (int, error) {
	merged := map[string]map[string]interface{}{}
	var refs []*firestore.DocumentRef
	for _, update := range updates {
		if merged[update.ID] == nil {
			merged[update.ID] = map[string]interface{}{}
			refs = append(refs, s.Client.Collection("channels").Doc(update.ID))
		}
		maps.Copy(merged[update.ID], update.Data)
	}
	docs, err := s.Client.GetAll(ctx, refs)
	if err != nil {
		return 0, err
	}
	writer := s.Client.BulkWriter(ctx)
	var jobs []*firestore.BulkWriterJob
	for _, doc := range docs {
		data := merged[doc.Ref.ID]
		var job *firestore.BulkWriterJob
		if !doc.Exists() {
			job, err = writer.Create(doc.Ref, data)
		} else if (doc.UpdateTime.After(started) && len(data) > 1) || unchanged(doc.Data(), data) {
			// A newer webhook wins over a poll that started before it; follower-only
			// writes don't touch stream metadata. Unchanged data still costs a write.
			continue
		} else {
			var fields []firestore.Update
			for field, value := range data {
				fields = append(fields, firestore.Update{FieldPath: firestore.FieldPath{field}, Value: value})
			}
			job, err = writer.Update(doc.Ref, fields, firestore.LastUpdateTime(doc.UpdateTime))
		}
		if err != nil {
			writer.End()
			return 0, err
		}
		jobs = append(jobs, job)
	}
	writer.End()
	written := 0
	for _, job := range jobs {
		_, err := job.Results()
		switch status.Code(err) {
		case codes.OK:
			written++
		case codes.FailedPrecondition, codes.AlreadyExists:
			// A webhook wrote the channel since it was read; it wins.
		default:
			return written, err
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
