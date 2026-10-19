package catalog

import (
	"context"
	"encoding/json"
	"errors"
	"net/url"
	"regexp"
	"sort"
	"strings"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/provider"
	"golang.org/x/sync/errgroup"

	"github.com/muxable/rtchat/agent/internal/clients/kick"
	"github.com/muxable/rtchat/agent/internal/clients/youtube"
)

var kickSlug = regexp.MustCompile(`^[a-z0-9_-]{2,25}$`)
var youtubeID = regexp.MustCompile(`^UC[A-Za-z0-9_-]{22}$`)
var youtubeHandle = regexp.MustCompile(`^@?([A-Za-z0-9_.-]+)$`)
var youtubeURL = regexp.MustCompile(`(?i)^(https?://)?(www\.|m\.)?youtube\.com/`)

type lookup struct{ ID, Handle string }

func parseYouTube(query string) (lookup, bool) {
	value := strings.TrimSpace(query)
	if youtubeURL.MatchString(value) {
		raw := value
		if !strings.HasPrefix(strings.ToLower(raw), "http") {
			raw = "https://" + raw
		}
		u, err := url.Parse(raw)
		if err != nil {
			return lookup{}, false
		}
		path := strings.TrimSuffix(u.Path, "/")
		if strings.HasPrefix(path, "/channel/") {
			id := strings.TrimPrefix(path, "/channel/")
			return lookup{ID: id}, youtubeID.MatchString(id)
		}
		if !strings.HasPrefix(path, "/@") {
			return lookup{}, false
		}
		value = path[1:]
	}
	if youtubeID.MatchString(value) {
		return lookup{ID: value}, true
	}
	match := youtubeHandle.FindStringSubmatch(value)
	if match == nil {
		return lookup{}, false
	}
	return lookup{Handle: strings.ToLower(match[1])}, true
}
func parseSearch(data json.RawMessage) (string, []string, error) {
	var query string
	if json.Unmarshal(data, &query) == nil && strings.HasPrefix(strings.TrimSpace(string(data)), "\"") {
		if len(query) > 2048 {
			return "", nil, bad("query too long")
		}
		return query, []string{"twitch", "kick"}, nil
	}
	var input struct {
		Query    json.RawMessage `json:"query"`
		Provider string          `json:"provider"`
	}
	if json.Unmarshal(data, &input) != nil || (input.Provider != "twitch" && input.Provider != "kick" && input.Provider != "youtube") {
		return "", nil, bad("unsupported provider")
	}
	_ = json.Unmarshal(input.Query, &query)
	if len(query) > 2048 {
		return "", nil, bad("query too long")
	}
	return query, []string{input.Provider}, nil
}
func (s *Server) Search(ctx context.Context, data json.RawMessage) (any, error) {
	query, providers, err := parseSearch(data)
	if err != nil {
		return nil, err
	}
	uid := callable.UID(ctx)
	if uid != "" && query == "" && providers[0] == "twitch" {
		token, err := s.userToken(ctx, uid)
		if err == nil {
			profile, err := s.Store.Profile(ctx, uid, "twitch")
			if err != nil {
				return nil, unavailable()
			}
			if text(profile["id"]) == "" {
				return nil, unavailable()
			}
			data, err := s.twitch(ctx, "streams/followed", token, url.Values{"user_id": {text(profile["id"])}})
			if err != nil {
				return nil, err
			}
			results := []map[string]any{}
			for _, c := range array(data["data"]) {
				results = append(results, map[string]any{
					"provider":     "twitch",
					"channelId":    c["user_id"],
					"login":        c["user_login"],
					"displayName":  c["user_name"],
					"isOnline":     c["type"] == "live",
					"imageUrl":     "https://rtirl.com/pfp.png?provider=twitch&channelId=" + text(c["user_id"]),
					"categoryName": c["game_name"],
					"title":        c["title"],
					"viewerCount":  c["viewer_count"],
					"language":     c["language"],
				})
			}
			return results, nil
		}
		if !errors.Is(err, provider.ErrNoToken) {
			return nil, err
		}
	}
	batches := make([][]map[string]any, len(providers))
	var group errgroup.Group
	for i, p := range providers {
		i, p := i, p
		group.Go(func() error {
			switch p {
			case "twitch":
				var err error
				batches[i], err = s.searchTwitch(ctx, query)
				return err
			case "kick":
				batches[i] = s.searchKick(ctx, query)
			case "youtube":
				batches[i] = s.searchYouTube(ctx, query)
			}
			return nil
		})
	}
	if err := group.Wait(); err != nil {
		return nil, err
	}
	results := []map[string]any{}
	for _, batch := range batches {
		results = append(results, batch...)
	}
	wanted := strings.ToLower(strings.TrimSpace(query))
	if l, ok := parseYouTube(query); ok && l.Handle != "" {
		wanted = l.Handle
	}
	sort.SliceStable(results, func(i, j int) bool {
		return strings.ToLower(text(results[i]["login"])) == wanted && strings.ToLower(text(results[j]["login"])) != wanted
	})
	return results, nil
}
func (s *Server) searchTwitch(ctx context.Context, query string) ([]map[string]any, error) {
	token, err := s.Tokens.AppAccessToken(ctx, "twitch")
	if err != nil {
		return nil, unavailable()
	}
	data, err := s.twitch(ctx, "search/channels", token, url.Values{"query": {query}})
	if err != nil {
		return nil, err
	}
	results := []map[string]any{}
	for _, c := range array(data["data"]) {
		results = append(results, map[string]any{
			"provider":     "twitch",
			"channelId":    c["id"],
			"login":        c["broadcaster_login"],
			"displayName":  c["display_name"],
			"isOnline":     c["is_live"],
			"imageUrl":     c["thumbnail_url"],
			"categoryName": c["game_name"],
			"title":        c["title"],
			"language":     c["broadcaster_language"],
		})
	}
	return results, nil
}
func (s *Server) searchKick(ctx context.Context, query string) []map[string]any {
	empty := []map[string]any{}
	slug := strings.ToLower(strings.TrimSpace(query))
	if !kickSlug.MatchString(slug) {
		return empty
	}
	token, err := s.Tokens.AppAccessToken(ctx, "kick")
	if err != nil {
		return empty
	}
	var data map[string]any
	err = kick.New(s.HTTP, token).Get(ctx, "/channels?slug="+url.QueryEscape(slug), &data)
	if err != nil {
		return empty
	}
	c := first(data["data"])
	if c == nil {
		return empty
	}
	id := identifier(c["broadcaster_user_id"])
	var users map[string]any
	_ = kick.New(s.HTTP, token).Get(ctx, "/users?id="+url.QueryEscape(id), &users)
	user := first(users["data"])
	stream := object(c["stream"])
	return []map[string]any{
		{
			"provider":    "kick",
			"channelId":   id,
			"login":       c["slug"],
			"displayName": or(user["name"], c["slug"]),
			"isOnline":    or(stream["is_live"], false),
			"imageUrl": or(user["profile_picture"],
				"https://rtirl.com/pfp.png?provider=kick&channelId="+id),
			"categoryName": object(c["category"])["name"],
			"title":        c["stream_title"],
			"viewerCount":  or(stream["viewer_count"], 0),
			"language":     stream["language"],
		},
	}
}
func (s *Server) searchYouTube(ctx context.Context, query string) []map[string]any {
	empty := []map[string]any{}
	l, ok := parseYouTube(query)
	if !ok || s.YouTubeAPIKey == nil {
		return empty
	}
	apiKey, err := s.YouTubeAPIKey(ctx)
	if err != nil || apiKey == "" {
		return empty
	}
	key := l.ID
	if key == "" {
		key = "@" + l.Handle
	}
	if cached, hit, err := s.Store.CachedYouTube(ctx, key); err == nil && hit {
		return cached
	}
	params := url.Values{"part": {"snippet"}, "key": {apiKey}}
	if l.ID != "" {
		params.Set("id", l.ID)
	} else {
		params.Set("forHandle", "@"+l.Handle)
	}
	var data map[string]any
	err = youtube.New(s.HTTP, "").Get(ctx, "/channels?"+params.Encode(), &data)
	results := empty
	if err == nil {
		c := first(data["items"])
		snippet := object(c["snippet"])
		if youtubeID.MatchString(text(c["id"])) && snippet != nil {
			login := text(snippet["customUrl"])
			if login == "" {
				login = l.Handle
			}
			if login == "" {
				login = text(c["id"])
			}
			thumbs := object(snippet["thumbnails"])
			results = []map[string]any{
				{
					"provider":  "youtube",
					"channelId": c["id"],
					"login": strings.ToLower(strings.TrimPrefix(login,
						"@")),
					"displayName": snippet["title"],
					"imageUrl": or(object(thumbs["default"])["url"], or(object(thumbs["medium"])["url"],
						"")),
					"isOnline": false}}
		}
	}
	_ = s.Store.CacheYouTube(ctx, key, results)
	return results
}
