package catalog

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"sync"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/clients/twitch"
	"github.com/muxable/rtchat/agent/internal/provider"
	"golang.org/x/sync/errgroup"
)

type Emote struct {
	Provider string `json:"provider"`
	Category any    `json:"category"`
	ID       any    `json:"id"`
	Code     string `json:"code"`
	ImageURL string `json:"imageUrl"`
}

func (s *Server) Emotes(ctx context.Context, data json.RawMessage) (any, error) {
	p, channel, err := parseChannel(data, true)
	if err != nil {
		return nil, err
	}
	if p != "twitch" {
		return []Emote{}, nil
	}
	if !numericID.MatchString(channel) {
		return nil, bad("invalid channelId")
	}
	token, err := s.userToken(ctx, callable.UID(ctx))
	if err != nil && !errors.Is(err, provider.ErrNoToken) {
		return nil, err
	}
	sources := []func(context.Context, string) []Emote{s.bttv, s.ffz, s.sevenTV}
	parts := make([][]Emote, len(sources))
	var wg sync.WaitGroup
	for i, load := range sources {
		wg.Add(1)
		go func(i int, load func(context.Context, string) []Emote) {
			defer wg.Done()
			parts[i] = load(ctx, channel)
		}(i, load)
	}
	result := []Emote{}
	err = nil
	if token != "" {
		result, err = s.twitchEmotes(ctx, token, channel)
	}
	wg.Wait()
	if err != nil {
		return nil, err
	}
	for _, part := range parts {
		result = append(result, part...)
	}
	return result, nil
}

// both runs the global and channel requests of one source concurrently.
func both(global, local func()) {
	var wg sync.WaitGroup
	wg.Add(1)
	go func() { defer wg.Done(); global() }()
	local()
	wg.Wait()
}
func (s *Server) bttv(ctx context.Context, channel string) []Emote {
	result := []Emote{}
	var global []map[string]any
	var globalErr, err error
	var local map[string]any
	both(func() { globalErr = s.fetch(ctx, "https://api.betterttv.net/3/cached/emotes/global", &global) },
		func() { local, err = s.request(ctx, "https://api.betterttv.net/3/cached/users/twitch/"+channel) })
	if globalErr == nil {
		for _, e := range global {
			result = append(result, Emote{"bttv", nil, e["id"], text(e["code"]), "https://cdn.betterttv.net/emote/" + text(e["id"]) + "/3x"})
		}
	}
	if err == nil {
		for _, source := range []struct{ key, category string }{{"channelEmotes", "Channel Emotes"}, {"sharedEmotes", "Shared Emotes"}} {
			for _, e := range array(local[source.key]) {
				result = append(result, Emote{"bttv", source.category, e["id"], text(e["code"]), "https://cdn.betterttv.net/emote/" + text(e["id"]) + "/3x"})
			}
		}
	}
	return result
}
func ffzSet(set map[string]any) []Emote {
	result := []Emote{}
	for _, e := range array(set["emoticons"]) {
		urls := object(e["urls"])
		image := text(urls["4"])
		if image == "" {
			image = text(urls["2"])
		}
		if image == "" {
			image = text(urls["1"])
		}
		result = append(result, Emote{"ffz", set["title"], e["id"], text(e["name"]), image})
	}
	return result
}
func (s *Server) ffz(ctx context.Context, channel string) []Emote {
	result := []Emote{}
	var global, local map[string]any
	var globalErr, err error
	both(func() { global, globalErr = s.request(ctx, "https://api.frankerfacez.com/v1/set/global") },
		func() { local, err = s.request(ctx, "https://api.frankerfacez.com/v1/room/id/"+channel) })
	if globalErr == nil {
		sets := object(global["sets"])
		ids, _ := global["default_sets"].([]any)
		for _, id := range ids {
			result = append(result, ffzSet(object(sets[identifier(id)]))...)
		}
	}
	if err == nil {
		key := identifier(object(local["room"])["set"])
		result = append(result, ffzSet(object(object(local["sets"])[key]))...)
	}
	return result
}
func sevenEmotes(items any) []Emote {
	result := []Emote{}
	for _, e := range array(items) {
		result = append(result, Emote{"7tv", nil, e["id"], text(e["name"]), "https://cdn.7tv.app/emote/" + text(e["id"]) + "/4x.webp"})
	}
	return result
}
func (s *Server) sevenTV(ctx context.Context, channel string) []Emote {
	result := []Emote{}
	var global, local map[string]any
	var globalErr, err error
	both(func() { global, globalErr = s.request(ctx, "https://7tv.io/v3/emote-sets/global") },
		func() { local, err = s.request(ctx, "https://7tv.io/v3/users/twitch/"+channel) })
	if globalErr == nil {
		result = append(result, sevenEmotes(global["emotes"])...)
	}
	if err == nil {
		result = append(result, sevenEmotes(object(local["emote_set"])["emotes"])...)
	}
	return result
}

type twitchEmote struct {
	emote Emote
	owner string
}

// twitchEmote converts one Helix emote, resolving its image from the template.
func newTwitchEmote(e map[string]any, template string) twitchEmote {
	owner := text(e["owner_id"])
	if owner == "twitch" || owner == "0" {
		owner = ""
	}
	scale := "1.0"
	scales, _ := e["scale"].([]any)
	if len(scales) > 0 {
		scale = fmt.Sprint(scales[len(scales)-1])
	}
	image := strings.NewReplacer("{{id}}", text(e["id"]), "{{format}}", "default", "{{theme_mode}}", "dark", "{{scale}}", scale).Replace(template)
	return twitchEmote{Emote{"twitch", nil, e["id"], text(e["name"]), image}, owner}
}

func (s *Server) twitchEmotes(ctx context.Context, token, channel string) ([]Emote, error) {
	user, err := s.twitch(ctx, "users", token, url.Values{})
	if err != nil {
		return nil, err
	}
	login := text(first(user["data"])["login"])
	if login == "" {
		return nil, upstreamError("twitch users", errors.New("provider response missing user login"))
	}
	// One Helix call lists everything the user can use, including the
	// channel's follower emotes. Tokens from before user:read:emotes was
	// requested fall back to the emote sets IRC reports.
	emotes, err := s.userEmotes(ctx, token, text(first(user["data"])["id"]), channel)
	if err != nil {
		emotes, err = s.setEmotes(ctx, token, login)
		if err != nil {
			return nil, err
		}
	}
	owners := []string{}
	seen := map[string]bool{}
	for _, e := range emotes {
		if e.owner != "" && !seen[e.owner] {
			seen[e.owner] = true
			owners = append(owners, e.owner)
		}
	}
	categories, err := s.ownerNames(ctx, token, owners)
	if err != nil {
		return nil, err
	}
	result := []Emote{}
	for _, item := range emotes {
		e := item.emote
		if name := categories[item.owner]; name != "" {
			e.Category = name
		}
		result = append(result, e)
	}
	return result, nil
}

func (s *Server) userEmotes(ctx context.Context, token, userID, channel string) ([]twitchEmote, error) {
	if userID == "" {
		return nil, upstreamError("twitch user emotes", errors.New("provider response missing user ID"))
	}
	result := []twitchEmote{}
	after := ""
	for pages := 0; pages < 50; pages++ {
		q := url.Values{"user_id": {userID}, "broadcaster_id": {channel}}
		if after != "" {
			q.Set("after", after)
		}
		data, err := s.twitch(ctx, "chat/emotes/user", token, q)
		if err != nil {
			return nil, err
		}
		template := text(data["template"])
		for _, e := range array(data["data"]) {
			result = append(result, newTwitchEmote(e, template))
		}
		after = text(object(data["pagination"])["cursor"])
		if after == "" {
			return result, nil
		}
	}
	return nil, upstreamError("twitch user emotes", errors.New("provider response exceeded 50 pages"))
}

// setEmotes resolves the emote sets IRC reports, 25 sets per Helix request,
// with the requests running concurrently.
func (s *Server) setEmotes(ctx context.Context, token, login string) ([]twitchEmote, error) {
	setsFn := s.EmoteSets
	if setsFn == nil {
		setsFn = twitch.EmoteSets
	}
	sets, err := setsFn(ctx, token, login)
	if err != nil {
		return []twitchEmote{}, nil
	}
	if len(sets) > 5000 {
		return nil, upstreamError("twitch emote sets", errors.New("provider response exceeded 5000 emote sets"))
	}
	batches := make([][]twitchEmote, (len(sets)+24)/25)
	var group errgroup.Group
	group.SetLimit(8)
	for i := range batches {
		i := i
		group.Go(func() error {
			q := url.Values{}
			for _, id := range sets[i*25 : min(i*25+25, len(sets))] {
				q.Add("emote_set_id", id)
			}
			data, err := s.twitch(ctx, "chat/emotes/set", token, q)
			if err != nil {
				// one unavailable set batch doesn't drop the others.
				return nil
			}
			template := text(data["template"])
			for _, e := range array(data["data"]) {
				batches[i] = append(batches[i], newTwitchEmote(e, template))
			}
			return nil
		})
	}
	group.Wait()
	result := []twitchEmote{}
	for _, batch := range batches {
		result = append(result, batch...)
	}
	return result, nil
}

// ownerNames looks up display names for emote owners, 100 per request, with
// the requests running concurrently.
func (s *Server) ownerNames(ctx context.Context, token string, owners []string) (map[string]string, error) {
	names := make([]map[string]string, (len(owners)+99)/100)
	var group errgroup.Group
	group.SetLimit(8)
	for i := range names {
		i := i
		group.Go(func() error {
			q := url.Values{}
			for _, id := range owners[i*100 : min(i*100+100, len(owners))] {
				q.Add("id", id)
			}
			data, err := s.twitch(ctx, "users", token, q)
			if err != nil {
				return err
			}
			names[i] = map[string]string{}
			for _, u := range array(data["data"]) {
				names[i][text(u["id"])] = text(u["display_name"])
			}
			return nil
		})
	}
	if err := group.Wait(); err != nil {
		return nil, err
	}
	categories := map[string]string{}
	for _, batch := range names {
		for id, name := range batch {
			categories[id] = name
		}
	}
	return categories, nil
}
