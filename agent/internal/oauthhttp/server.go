// Package oauthhttp serves OAuth and companion login on every agent replica.
package oauthhttp

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"
)

type Session struct {
	State, Provider, Verifier, Companion, UID, LinkedProvider string
	Expires                                                   time.Time
}
type Store interface {
	SaveSession(context.Context, string, Session) error
	ConsumeSession(context.Context, string, string, string) (Session, error)
	Allow(context.Context, string) (bool, error)
	SignIn(context.Context, string, map[string]any, map[string]any, string) (string, error)
	Verify(context.Context, string) (string, error)
	Link(context.Context, string, string, string, map[string]any) error
}
type Provider struct {
	ClientID, ClientSecret, AuthorizeURL, TokenURL, Scopes string
	JSONBody                                               bool
}
type Server struct {
	Store          Store
	Providers      map[string]Provider
	SessionKey     []byte
	CallbackOrigin string
	HTTP           *http.Client
	TrustedProxies []*net.IPNet
}

func random() string {
	var b [32]byte
	if _, err := rand.Read(b[:]); err != nil {
		panic(err)
	}
	return base64.RawURLEncoding.EncodeToString(b[:])
}
func (s *Server) client() *http.Client {
	if s.HTTP != nil {
		return s.HTTP
	}
	return &http.Client{Timeout: 15 * time.Second}
}
func (s *Server) signature(id string) string {
	h := hmac.New(sha256.New, s.SessionKey)
	h.Write([]byte(id))
	return hex.EncodeToString(h.Sum(nil))
}
func (s *Server) cookie(r *http.Request) string {
	c, e := r.Cookie("__session")
	if e != nil {
		return ""
	}
	p := strings.Split(c.Value, ".")
	if len(p) != 2 || !hmac.Equal([]byte(s.signature(p[0])), []byte(p[1])) {
		return ""
	}
	return p[0]
}
func (s *Server) callback(p string) string {
	return strings.TrimSuffix(s.CallbackOrigin, "/") + "/auth/" + p + "/callback"
}
func (s *Server) Register(mux *http.ServeMux) { mux.Handle("/auth/", s) }
func (s *Server) peer(r *http.Request) string {
	host, _, _ := net.SplitHostPort(r.RemoteAddr)
	ip := net.ParseIP(host)
	for _, network := range s.TrustedProxies {
		if network.Contains(ip) {
			parts := strings.Split(r.Header.Get("X-Forwarded-For"), ",") // GFE appends client and LB IP; discard the configured LB entry.
			if len(parts) >= 2 {
				candidate := strings.TrimSpace(parts[len(parts)-2])
				if net.ParseIP(candidate) != nil {
					return candidate
				}
			}
		}
	}
	return host
}
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("Referrer-Policy", "no-referrer")
	if r.Method != "GET" {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	if len(s.SessionKey) < 32 {
		http.Error(w, "OAuth unavailable", http.StatusServiceUnavailable)
		return
	}
	allowed, err := s.Store.Allow(r.Context(), s.peer(r))
	if err != nil {
		http.Error(w, "temporarily unavailable", http.StatusServiceUnavailable)
		return
	}
	if !allowed {
		http.Error(w, "too many requests", http.StatusTooManyRequests)
		return
	}
	parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(parts) != 3 || parts[0] != "auth" {
		http.NotFound(w, r)
		return
	}
	name := parts[1]
	p, ok := s.Providers[name]
	if !ok || p.ClientID == "" || p.ClientSecret == "" {
		http.Error(w, "provider unavailable", http.StatusServiceUnavailable)
		return
	}
	switch parts[2] {
	case "redirect":
		s.redirect(w, r, name, p)
	case "callback":
		s.complete(w, r, name, p)
	default:
		http.NotFound(w, r)
	}
}
func (s *Server) redirect(w http.ResponseWriter, r *http.Request, name string, p Provider) {
	// The cookie must be issued on the callback host. Canonicalize before saving state.
	origin, err := url.Parse(s.CallbackOrigin)
	if err != nil || origin.Scheme != "https" || origin.Host == "" {
		http.Error(w, "OAuth unavailable", http.StatusServiceUnavailable)
		return
	}
	if r.Host != origin.Host {
		http.Redirect(w, r, s.CallbackOrigin+r.URL.RequestURI(), http.StatusFound)
		return
	}

	session := Session{State: random(), Provider: name, Companion: r.URL.Query().Get("companion"), Expires: time.Now().Add(time.Minute)}
	if len(session.Companion) > 128 || strings.ContainsAny(session.Companion, "/\\") {
		http.Error(w, "invalid companion", 400)
		return
	}
	if name == "streamlabs" || name == "streamelements" {
		uid, e := s.Store.Verify(r.Context(), r.URL.Query().Get("token"))
		if e != nil || uid == "" {
			http.Error(w, "invalid token", http.StatusUnauthorized)
			return
		}
		session.UID = uid
		session.LinkedProvider = r.URL.Query().Get("provider")
		if session.LinkedProvider != "twitch" && session.LinkedProvider != "kick" && session.LinkedProvider != "youtube" {
			http.Error(w, "invalid provider", 400)
			return
		}
	}
	q := url.Values{"client_id": {p.ClientID}, "redirect_uri": {s.callback(name)}, "response_type": {"code"}, "scope": {p.Scopes}, "state": {session.State}}
	if name == "kick" {
		session.Verifier = random()
		challenge := sha256.Sum256([]byte(session.Verifier))
		q.Set("code_challenge", base64.RawURLEncoding.EncodeToString(challenge[:]))
		q.Set("code_challenge_method", "S256")
	}
	if name == "twitch" {
		q.Set("force_verify", "true")
	}
	if name == "youtube" {
		q.Set("access_type", "offline")
		q.Set("prompt", "consent select_account")
		q.Set("include_granted_scopes", "true")
	}
	id := random()
	if err := s.Store.SaveSession(r.Context(), id, session); err != nil {
		http.Error(w, "temporarily unavailable", http.StatusServiceUnavailable)
		return
	}
	http.SetCookie(w, &http.Cookie{Name: "__session", Value: id + "." + s.signature(id), Path: "/", Secure: true, HttpOnly: true, SameSite: http.SameSiteLaxMode, MaxAge: 60})
	http.Redirect(w, r, p.AuthorizeURL+"?"+q.Encode(), http.StatusFound)
}
func (s *Server) fail(w http.ResponseWriter, r *http.Request, session Session, code string) {
	if session.Companion != "" {
		http.Error(w, code, 400)
	} else {
		http.Redirect(w, r, "com.rtirl.chat://error?message="+code, http.StatusFound)
	}
}
func (s *Server) complete(w http.ResponseWriter, r *http.Request, name string, p Provider) {
	// Consume in a transaction before exchanging the code: replay fails across replicas.
	session, err := s.Store.ConsumeSession(r.Context(), s.cookie(r), name, r.URL.Query().Get("state"))
	if err != nil {
		http.Error(w, "invalid or expired OAuth state", 400)
		return
	}
	if r.URL.Query().Get("error") != "" || r.URL.Query().Get("code") == "" {
		s.fail(w, r, session, "access_denied")
		return
	}
	values := url.Values{"grant_type": {"authorization_code"}, "code": {r.URL.Query().Get("code")}, "client_id": {p.ClientID}, "client_secret": {p.ClientSecret}, "redirect_uri": {s.callback(name)}}
	if name == "kick" {
		if session.Verifier == "" {
			s.fail(w, r, session, "sign_in_failed")
			return
		}
		values.Set("code_verifier", session.Verifier)
	}
	token, err := s.exchange(r.Context(), p, values)
	if err != nil {
		s.fail(w, r, session, "sign_in_failed")
		return
	}
	if session.UID != "" {
		if err := s.Store.Link(r.Context(), session.UID, name, session.LinkedProvider, token); err != nil {
			s.fail(w, r, session, "sign_in_failed")
			return
		}
		http.Redirect(w, r, "com.rtirl.chat://success?token=1", http.StatusFound)
		return
	}
	profile, err := s.profile(r.Context(), name, p.ClientID, fmt.Sprint(token["access_token"]))
	if err != nil {
		code := "sign_in_failed"
		if errors.Is(err, errNoChannel) {
			code = "no_youtube_channel"
		}
		s.fail(w, r, session, code)
		return
	}
	custom, err := s.Store.SignIn(r.Context(), name, profile, token, session.Companion)
	if err != nil {
		s.fail(w, r, session, "sign_in_failed")
		return
	}
	if session.Companion != "" {
		w.Header().Set("Content-Type", "text/plain")
		io.WriteString(w, "Logged in successfully.")
		return
	}
	http.Redirect(w, r, "com.rtirl.chat://success?token="+url.QueryEscape(custom), http.StatusFound)
}
func (s *Server) exchange(ctx context.Context, p Provider, values url.Values) (map[string]any, error) {
	var body io.Reader = strings.NewReader(values.Encode())
	content := "application/x-www-form-urlencoded"
	if p.JSONBody {
		fields := map[string]string{}
		for k := range values {
			fields[k] = values.Get(k)
		}
		data, _ := json.Marshal(fields)
		body = strings.NewReader(string(data))
		content = "application/json"
	}
	req, _ := http.NewRequestWithContext(ctx, "POST", p.TokenURL, body)
	req.Header.Set("Content-Type", content)
	var token map[string]any
	if err := s.json(req, &token); err != nil {
		return nil, err
	}
	if token["access_token"] == nil {
		return nil, errors.New("missing access token")
	}
	if n, ok := token["expires_in"].(float64); ok {
		token["expires_at"] = time.Now().Add(time.Duration(n) * time.Second).UTC().Format(time.RFC3339Nano)
	}
	return token, nil
}
func (s *Server) json(req *http.Request, out any) error {
	resp, err := s.client().Do(req)
	if err != nil {
		return errors.New("provider request failed")
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return errors.New("provider rejected request")
	}
	return json.NewDecoder(io.LimitReader(resp.Body, 2<<20)).Decode(out)
}
