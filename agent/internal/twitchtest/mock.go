// Package twitchtest starts the pinned Twitch CLI's generated mock API for tests.
package twitchtest

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

type User struct {
	ID          string `json:"id"`
	Login       string `json:"login"`
	DisplayName string `json:"display_name"`
}
type Mock struct {
	URL, ClientID, ClientSecret, AppToken string
	Users                                 []User
	Client                                *http.Client
}

func Start(t *testing.T) *Mock {
	t.Helper()
	binary := os.Getenv("TWITCH_CLI")
	if binary == "" {
		binary = "twitch"
	}
	path, err := exec.LookPath(binary)
	if err != nil {
		if os.Getenv("CI") != "" {
			t.Fatalf("Twitch CLI required in CI: %v", err)
		}
		t.Skip("install Twitch CLI or set TWITCH_CLI")
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	port := listener.Addr().(*net.TCPAddr).Port
	listener.Close()
	dir := t.TempDir()
	log, err := os.Create(filepath.Join(dir, "mock.log"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { log.Close() })
	cmd := exec.Command(path, "mock-api", "start", "--port", fmt.Sprint(port))
	cmd.Env = append(os.Environ(), "XDG_CONFIG_HOME="+dir, "TWITCH_DISABLE_UPDATE_CHECKS=true")
	cmd.Stdout = log
	cmd.Stderr = log
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { cmd.Process.Kill(); cmd.Wait() })
	mock := &Mock{URL: fmt.Sprintf("http://127.0.0.1:%d", port), Client: &http.Client{Timeout: 5 * time.Second}}
	deadline := time.Now().Add(25 * time.Second)
	for {
		var clients struct{ Data []struct{ ID, Secret string } }
		status, err := mock.Request("GET", "/units/clients", nil, "", &clients)
		if err == nil && status == 200 && len(clients.Data) > 0 {
			mock.ClientID = clients.Data[0].ID
			mock.ClientSecret = clients.Data[0].Secret
			break
		}
		if time.Now().After(deadline) {
			data, _ := os.ReadFile(log.Name())
			t.Fatalf("CLI mock startup failed: %s", data)
		}
		time.Sleep(50 * time.Millisecond)
	}
	var users struct{ Data []User }
	if status, err := mock.Request("GET", "/units/users", nil, "", &users); err != nil || status != 200 || len(users.Data) == 0 {
		t.Fatalf("mock users: status=%d err=%v", status, err)
	}
	mock.Users = users.Data
	mock.AppToken = mock.token(t, "/auth/token", url.Values{"grant_type": {"client_credentials"}})
	return mock
}
func (m *Mock) token(t *testing.T, path string, q url.Values) string {
	t.Helper()
	q.Set("client_id", m.ClientID)
	q.Set("client_secret", m.ClientSecret)
	var body struct {
		AccessToken string `json:"access_token"`
	}
	if status, err := m.Request("POST", path, q, "", &body); err != nil || status != 200 || body.AccessToken == "" {
		t.Fatalf("mock token: status=%d err=%v", status, err)
	}
	return body.AccessToken
}
func (m *Mock) UserToken(t *testing.T, user string, scopes ...string) string {
	return m.token(t, "/auth/authorize", url.Values{"grant_type": {"user_token"}, "user_id": {user}, "scope": {strings.Join(scopes, " ")}})
}
func (m *Mock) Request(method, path string, q url.Values, token string, out any) (int, error) {
	req, err := http.NewRequest(method, m.URL+path+"?"+q.Encode(), nil)
	if err != nil {
		return 0, err
	}
	req.Header.Set("Client-Id", m.ClientID)
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := m.Client.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return resp.StatusCode, nil
	}
	if out == nil {
		return resp.StatusCode, nil
	}
	return resp.StatusCode, json.NewDecoder(resp.Body).Decode(out)
}

type Capture func(*http.Request, []byte)
type redirect struct {
	mock    *Mock
	capture Capture
}

func (r redirect) RoundTrip(req *http.Request) (*http.Response, error) {
	if req.URL.Host != "api.twitch.tv" || !strings.HasPrefix(req.URL.Path, "/helix/") {
		return nil, fmt.Errorf("provider outside Twitch CLI mock")
	}
	clone := req.Clone(req.Context())
	target, _ := url.Parse(r.mock.URL)
	clone.URL.Scheme = target.Scheme
	clone.URL.Host = target.Host
	clone.URL.Path = "/mock/" + strings.TrimPrefix(req.URL.Path, "/helix/")
	clone.Host = ""
	resp, err := http.DefaultTransport.RoundTrip(clone)
	if err != nil {
		return nil, err
	}
	if r.capture != nil {
		data, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			return nil, err
		}
		r.capture(req, data)
		resp.Body = io.NopCloser(bytes.NewReader(data))
	}
	return resp, nil
}

// HTTPClient sends only Helix calls to the CLI. Other providers fail normally so
// tests exercise independent fallbacks without calling third-party services.
func (m *Mock) HTTPClient(capture Capture) *http.Client {
	return &http.Client{Transport: redirect{m, capture}, Timeout: 10 * time.Second}
}
