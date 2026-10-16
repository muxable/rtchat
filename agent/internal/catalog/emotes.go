package catalog

import (
	"bufio"
	"context"
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/url"
	"strings"
	"sync"
	"time"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/provider"
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
	parts := make([][]Emote, 4)
	var twitchErr error
	var wg sync.WaitGroup
	for i := range parts {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			switch i {
			case 0:
				if token != "" {
					parts[i], twitchErr = s.twitchEmotes(ctx, token)
				}
			case 1:
				parts[i] = s.bttv(ctx, channel)
			case 2:
				parts[i] = s.ffz(ctx, channel)
			case 3:
				parts[i] = s.sevenTV(ctx, channel)
			}
		}(i)
	}
	wg.Wait()
	if twitchErr != nil {
		return nil, twitchErr
	}
	result := []Emote{}
	for _, p := range parts {
		result = append(result, p...)
	}
	return result, nil
}
func (s *Server) bttv(ctx context.Context, channel string) []Emote {
	result := []Emote{}
	var global []map[string]any
	if s.fetch(ctx, "https://api.betterttv.net/3/cached/emotes/global", "", &global) == nil {
		for _, e := range global {
			result = append(result, Emote{"bttv", nil, e["id"], text(e["code"]), "https://cdn.betterttv.net/emote/" + text(e["id"]) + "/3x"})
		}
	}
	local, err := s.request(ctx, "https://api.betterttv.net/3/cached/users/twitch/"+channel, "")
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
	global, err := s.request(ctx, "https://api.frankerfacez.com/v1/set/global", "")
	if err == nil {
		sets := object(global["sets"])
		ids, _ := global["default_sets"].([]any)
		for _, id := range ids {
			result = append(result, ffzSet(object(sets[fmt.Sprint(id)]))...)
		}
	}
	local, err := s.request(ctx, "https://api.frankerfacez.com/v1/room/id/"+channel, "")
	if err == nil {
		key := fmt.Sprint(object(local["room"])["set"])
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
	global, err := s.request(ctx, "https://7tv.io/v3/emote-sets/global", "")
	if err == nil {
		result = append(result, sevenEmotes(global["emotes"])...)
	}
	local, err := s.request(ctx, "https://7tv.io/v3/users/twitch/"+channel, "")
	if err == nil {
		result = append(result, sevenEmotes(object(local["emote_set"])["emotes"])...)
	}
	return result
}
func (s *Server) twitchEmotes(ctx context.Context, token string) ([]Emote, error) {
	user, err := s.twitch(ctx, "users", token, url.Values{})
	if err != nil {
		return nil, err
	}
	login := text(first(user["data"])["login"])
	if login == "" {
		return nil, unavailable()
	}
	setsFn := s.EmoteSets
	if setsFn == nil {
		setsFn = ircEmoteSets
	}
	sets, err := setsFn(ctx, token, login)
	if err != nil {
		return []Emote{}, nil
	}
	unresolved := []struct {
		emote Emote
		owner string
	}{}
	owners := []string{}
	seen := map[string]bool{}
	if len(sets) > 5000 {
		return nil, unavailable()
	}
	for i := 0; i < len(sets); i += 25 {
		q := url.Values{}
		end := i + 25
		if end > len(sets) {
			end = len(sets)
		}
		for _, id := range sets[i:end] {
			q.Add("emote_set_id", id)
		}
		data, err := s.twitch(ctx, "chat/emotes/set", token, q)
		if err != nil {
			continue
		}
		for _, e := range array(data["data"]) {
			owner := text(e["owner_id"])
			if owner == "twitch" || owner == "0" {
				owner = ""
			}
			if owner != "" && !seen[owner] {
				seen[owner] = true
				owners = append(owners, owner)
			}
			scale := "1.0"
			scales, _ := e["scale"].([]any)
			if len(scales) > 0 {
				scale = fmt.Sprint(scales[len(scales)-1])
			}
			image := strings.NewReplacer("{{id}}", text(e["id"]), "{{format}}", "default", "{{theme_mode}}", "dark", "{{scale}}", scale).Replace(text(data["template"]))
			unresolved = append(unresolved, struct {
				emote Emote
				owner string
			}{Emote{"twitch", nil, e["id"], text(e["name"]), image}, owner})
		}
	}
	categories := map[string]string{}
	for i := 0; i < len(owners); i += 100 {
		q := url.Values{}
		end := i + 100
		if end > len(owners) {
			end = len(owners)
		}
		for _, id := range owners[i:end] {
			q.Add("id", id)
		}
		data, err := s.twitch(ctx, "users", token, q)
		if err != nil {
			return nil, err
		}
		for _, u := range array(data["data"]) {
			categories[text(u["id"])] = text(u["display_name"])
		}
	}
	result := []Emote{}
	for _, item := range unresolved {
		e := item.emote
		if name := categories[item.owner]; name != "" {
			e.Category = name
		}
		result = append(result, e)
	}
	return result, nil
}

// ircEmoteSets opens one short-lived TLS connection and always closes it. No
// channels are joined, and cancellation interrupts reads without leaking a client.
func ircEmoteSets(ctx context.Context, token, login string) ([]string, error) {
	ctx, cancel := context.WithTimeout(ctx, 8*time.Second)
	defer cancel()
	dialer := tls.Dialer{NetDialer: &net.Dialer{Timeout: 5 * time.Second}, Config: &tls.Config{MinVersion: tls.VersionTLS12}}
	conn, err := dialer.DialContext(ctx, "tcp", "irc.chat.twitch.tv:6697")
	if err != nil {
		return nil, err
	}
	defer conn.Close()
	return readEmoteSets(ctx, conn, token, login)
}
func readEmoteSets(ctx context.Context, conn net.Conn, token, login string) ([]string, error) {
	if strings.ContainsAny(token+login, "\r\n") {
		return nil, errors.New("invalid IRC credentials")
	}
	deadline, ok := ctx.Deadline()
	if !ok {
		deadline = time.Now().Add(8 * time.Second)
	}
	conn.SetDeadline(deadline)
	done := make(chan struct{})
	defer close(done)
	go func() {
		select {
		case <-ctx.Done():
			conn.Close()
		case <-done:
		}
	}()
	if _, err := fmt.Fprintf(conn, "CAP REQ :twitch.tv/tags twitch.tv/commands\r\nPASS oauth:%s\r\nNICK %s\r\n", token, login); err != nil {
		return nil, err
	}
	scanner := bufio.NewScanner(conn)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "PING ") {
			fmt.Fprintf(conn, "PONG %s\r\n", strings.TrimPrefix(line, "PING "))
			continue
		}
		if !strings.Contains(line, " GLOBALUSERSTATE") || !strings.HasPrefix(line, "@") {
			continue
		}
		tagPart := strings.SplitN(line[1:], " ", 2)[0]
		for _, tag := range strings.Split(tagPart, ";") {
			if strings.HasPrefix(tag, "emote-sets=") {
				value := strings.TrimPrefix(tag, "emote-sets=")
				if value == "" {
					return []string{}, nil
				}
				return strings.Split(value, ","), nil
			}
		}
		return []string{}, nil
	}
	return nil, errors.New("IRC emote state unavailable")
}
