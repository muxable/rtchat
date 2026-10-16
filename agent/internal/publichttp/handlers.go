// Package publichttp serves preview redirects and authorized third-party metadata.
package publichttp

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"time"
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
func str(v any) string {
	if v == nil {
		return ""
	}
	return fmt.Sprint(v)
}
func first(result map[string]any, key string) map[string]any {
	items, _ := result[key].([]any)
	if len(items) == 0 {
		return nil
	}
	v, _ := items[0].(map[string]any)
	return v
}
func (s *Server) json(req *http.Request, out any) error {
	client := s.HTTP
	if client == nil {
		client = &http.Client{Timeout: 15 * time.Second}
	}
	resp, err := client.Do(req)
	if err != nil {
		return errors.New("provider request failed")
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return errors.New("provider rejected request")
	}
	return json.NewDecoder(io.LimitReader(resp.Body, 2<<20)).Decode(out)
}
func (s *Server) get(ctx context.Context, endpoint, token, id string) (map[string]any, error) {
	req, _ := http.NewRequestWithContext(ctx, "GET", endpoint, nil)
	req.Header.Set("Authorization", "Bearer "+token)
	if id != "" {
		req.Header.Set("Client-Id", id)
	}
	var result map[string]any
	err := s.json(req, &result)
	return result, err
}

var channelPattern = regexp.MustCompile(`^[0-9]{1,30}$`)

func (s *Server) embed(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	ctx, cancel := context.WithTimeout(r.Context(), 20*time.Second)
	defer cancel()
	r = r.WithContext(ctx)
	if r.Method != "GET" {
		http.Error(w, "method not allowed", 405)
		return
	}
	provider := r.URL.Query().Get("provider")
	channel := r.URL.Query().Get("channelId")
	if !channelPattern.MatchString(channel) || (provider != "twitch" && provider != "kick") {
		http.Error(w, "invalid provider or channelId", 400)
		return
	}
	if s.AppToken == nil {
		http.Error(w, "provider unavailable", 503)
		return
	}
	token, err := s.AppToken(r.Context(), provider)
	if err != nil {
		http.Error(w, "provider unavailable", 503)
		return
	}
	switch provider {
	case "twitch":
		data, err := s.get(r.Context(), "https://api.twitch.tv/helix/users?id="+channel, token, s.TwitchClientID)
		if err != nil {
			http.Error(w, "provider unavailable", 502)
			return
		}
		login := str(first(data, "data")["login"])
		if login == "" {
			http.NotFound(w, r)
			return
		}
		// Parent is the page embedding the player, not this redirect's API hostname.
		q := url.Values{"channel": {login}, "controls": {"false"}, "parent": {"chat.rtirl.com"}, "muted": {"true"}}
		http.Redirect(w, r, "https://player.twitch.tv/?"+q.Encode(), 302)
	case "kick":
		data, err := s.get(r.Context(), "https://api.kick.com/public/v1/channels?broadcaster_user_id="+channel, token, "")
		if err != nil {
			http.Error(w, "provider unavailable", 502)
			return
		}
		slug := str(first(data, "data")["slug"])
		if slug == "" {
			http.NotFound(w, r)
			return
		}
		http.Redirect(w, r, "https://player.kick.com/"+url.PathEscape(slug)+"?muted=true", 302)
	}
}
func (s *Server) metadata(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 20*time.Second)
	defer cancel()
	r = r.WithContext(ctx)
	w.Header().Set("Cache-Control", "no-store")
	if r.Method != "POST" {
		http.Error(w, "method not allowed", 405)
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
	req, _ := http.NewRequestWithContext(r.Context(), "GET", "https://id.twitch.tv/oauth2/validate", nil)
	req.Header.Set("Authorization", "OAuth "+body.Token)
	var validation struct {
		ClientID string `json:"client_id"`
		UserID   string `json:"user_id"`
	}
	if err := s.json(req, &validation); err != nil || !channelPattern.MatchString(validation.UserID) {
		http.Error(w, "invalid token", 401)
		return
	}
	name := s.MetadataClients[validation.ClientID]
	if name == "" {
		http.Error(w, "client id not registered, contact kevin@muxable.com", 403)
		return
	}
	if err := s.Store.Metadata(r.Context(), "twitch:"+validation.UserID, map[string]any{"key": body.Key, "value": body.Value, "clientId": validation.ClientID, "name": name}); err != nil {
		http.Error(w, "temporarily unavailable", 503)
		return
	}
	w.WriteHeader(204)
}
