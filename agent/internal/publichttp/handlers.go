// Package publichttp serves preview redirects and authorized third-party metadata.
package publichttp

import (
	"context"
	"encoding/json"
	"net/http"
	"net/url"
	"regexp"
	"time"

	"github.com/muxable/rtchat/agent/internal/clients/kick"
	"github.com/muxable/rtchat/agent/internal/clients/twitch"
)

type Store interface {
	Metadata(context.Context, string, map[string]any) error
}
type Server struct {
	Store           Store
	HTTP            *http.Client
	TwitchClientID  string
	AppToken        func(context.Context, string) (string, error)
	MetadataClients map[string]string
}

func (s *Server) Register(mux *http.ServeMux) {
	mux.HandleFunc("/embed", s.embed)
	mux.HandleFunc("/embedRedirect", s.embed)
	mux.HandleFunc("/metadata", s.metadata)
	mux.HandleFunc("/api/metadata", s.metadata)
}

var channelPattern = regexp.MustCompile(`^[0-9]{1,30}$`)
var youtubeChannelPattern = regexp.MustCompile(`^UC[A-Za-z0-9_-]{22}$`)

func (s *Server) embed(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	ctx, cancel := context.WithTimeout(r.Context(), 20*time.Second)
	defer cancel()
	r = r.WithContext(ctx)
	if r.Method != "GET" {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	provider := r.URL.Query().Get("provider")
	channel := r.URL.Query().Get("channelId")
	if provider == "youtube" {
		if !youtubeChannelPattern.MatchString(channel) {
			http.NotFound(w, r)
			return
		}
		http.Redirect(w, r, "https://www.youtube.com/embed/live_stream?channel="+channel+"&autoplay=1&mute=1", http.StatusFound)
		return
	}
	if !channelPattern.MatchString(channel) || (provider != "twitch" && provider != "kick") {
		http.Error(w, "invalid provider or channelId", 400)
		return
	}
	if s.AppToken == nil {
		http.Error(w, "provider unavailable", http.StatusServiceUnavailable)
		return
	}
	token, err := s.AppToken(r.Context(), provider)
	if err != nil {
		http.Error(w, "provider unavailable", http.StatusServiceUnavailable)
		return
	}
	switch provider {
	case "twitch":
		user, err := twitch.New(s.HTTP, s.TwitchClientID, token).User(r.Context(), "id", channel)
		if err != nil {
			http.Error(w, "provider unavailable", http.StatusBadGateway)
			return
		}
		login := user.Login
		if login == "" {
			http.NotFound(w, r)
			return
		}
		// Parent is the page embedding the player, not this redirect's API hostname.
		q := url.Values{"channel": {login}, "controls": {"false"}, "parent": {"chat.rtirl.com"}, "muted": {"true"}}
		http.Redirect(w, r, "https://player.twitch.tv/?"+q.Encode(), http.StatusFound)
	case "kick":
		var data struct{ Data []struct{ Slug string } }
		err := kick.New(s.HTTP, token).Get(r.Context(), "/channels?broadcaster_user_id="+channel, &data)
		if err != nil {
			http.Error(w, "provider unavailable", http.StatusBadGateway)
			return
		}
		slug := ""
		if len(data.Data) > 0 {
			slug = data.Data[0].Slug
		}
		if slug == "" {
			http.NotFound(w, r)
			return
		}
		http.Redirect(w, r, "https://player.kick.com/"+url.PathEscape(slug)+"?muted=true", http.StatusFound)
	}
}
func (s *Server) metadata(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 20*time.Second)
	defer cancel()
	r = r.WithContext(ctx)
	w.Header().Set("Cache-Control", "no-store")
	if r.Method != "POST" {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var body struct {
		Key      string `json:"key"`
		Value    any    `json:"value"`
		Token    string `json:"token"`
		Provider string `json:"provider"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 64<<10)).Decode(&body); err != nil || body.Key == "" || body.Value == nil || body.Token == "" || body.Provider != "twitch" || len(body.Key) > 256 {
		http.Error(w, "invalid metadata", 400)
		return
	}
	var validation struct {
		ClientID string `json:"client_id"`
		UserID   string `json:"user_id"`
	}
	if err := twitch.New(s.HTTP, s.TwitchClientID, "").Validate(r.Context(), body.Token, &validation); err != nil || !channelPattern.MatchString(validation.UserID) {
		http.Error(w, "invalid token", http.StatusUnauthorized)
		return
	}
	name := s.MetadataClients[validation.ClientID]
	if name == "" {
		http.Error(w, "client id not registered, contact kevin@muxable.com", http.StatusForbidden)
		return
	}
	if err := s.Store.Metadata(r.Context(), "twitch:"+validation.UserID, map[string]any{"key": body.Key, "value": body.Value, "clientId": validation.ClientID, "name": name}); err != nil {
		http.Error(w, "temporarily unavailable", http.StatusServiceUnavailable)
		return
	}
	w.WriteHeader(204)
}
