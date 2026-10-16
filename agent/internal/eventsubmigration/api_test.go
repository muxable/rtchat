package eventsubmigration

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestPaginationRateLimitAndLoopDetection(t *testing.T) {
	requests := 0
	pauses := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requests++
		if r.Header.Get("Client-ID") != "client" || r.Header.Get("Authorization") != "Bearer token" {
			t.Error("missing credentials")
		}
		if requests == 1 {
			w.Header().Set("Retry-After", "2")
			w.WriteHeader(429)
			return
		}
		if r.URL.Query().Get("after") == "" {
			fmt.Fprint(w, `{"data":[{"id":"one"}],"pagination":{"cursor":"next"}}`)
		} else {
			fmt.Fprint(w, `{"data":[{"id":"two"}],"pagination":{}}`)
		}
	}))
	defer server.Close()
	api := API{BaseURL: server.URL, Client: server.Client(), ClientID: "client", Token: "token", Pause: func(_ context.Context, delay time.Duration) error {
		pauses++
		if delay != 2*time.Second {
			t.Error(delay)
		}
		return nil
	}}
	result, err := api.List(context.Background(), nil)
	if err != nil || len(result.Data) != 2 || requests != 3 || pauses != 1 {
		t.Fatal(result, requests, pauses, err)
	}
	loop := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, `{"data":[],"pagination":{"cursor":"same"}}`)
	}))
	defer loop.Close()
	api.BaseURL = loop.URL
	if _, err := api.List(context.Background(), nil); err == nil {
		t.Fatal("pagination loop not rejected")
	}
}
func TestRateLimitCancellation(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.Header().Set("Retry-After", "30"); w.WriteHeader(429) }))
	defer server.Close()
	api := API{BaseURL: server.URL, Client: server.Client()}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Millisecond)
	defer cancel()
	if _, err := api.List(ctx, nil); err == nil {
		t.Fatal("ignored cancellation")
	}
}
func TestImmutableSnapshotAndBoundCheckpoint(t *testing.T) {
	snapshot := Snapshot{Schema: 1, ClientID: "client", LegacyCallbacks: [2]string{LegacyCallback, AliasCallback}, TargetCallback: TargetCallback, Subscriptions: []Subscription{source("old", "channel.chat.message", "1", `{"broadcaster_user_id":"123","user_id":"bot"}`)}}
	path := filepath.Join(t.TempDir(), "backup.json")
	if err := WriteSnapshot(path, snapshot); err != nil {
		t.Fatal(err)
	}
	if err := WriteSnapshot(path, snapshot); err == nil {
		t.Fatal("backup overwritten")
	}
	info, _ := os.Stat(path)
	if info.Mode().Perm() != 0600 {
		t.Fatal(info.Mode())
	}
	restored, err := ReadSnapshot(path)
	if err != nil || restored.Validate("client") != nil {
		t.Fatal(err)
	}
	data, _ := os.ReadFile(path)
	if strings.Contains(string(data), "secret") || strings.Contains(string(data), "token") {
		t.Fatal("credential stored in backup")
	}
	checkpoint, err := ReadCheckpoint(path+".state.json", restored)
	if err != nil {
		t.Fatal(err)
	}
	checkpoint.Entries["old"] = Progress{TargetID: "new", Created: true}
	if err := WriteCheckpoint(path+".state.json", checkpoint); err != nil {
		t.Fatal(err)
	}
	loaded, err := ReadCheckpoint(path+".state.json", restored)
	if err != nil || loaded.Entries["old"].TargetID != "new" {
		t.Fatal(loaded, err)
	}
	altered := restored
	altered.ClientID = "other"
	if _, err := ReadCheckpoint(path+".state.json", altered); err == nil {
		t.Fatal("foreign checkpoint accepted")
	}
	altered = restored
	altered.TargetCallback = "https://unrelated.example"
	if altered.Validate("client") == nil {
		t.Fatal("arbitrary target accepted")
	}
	encoded, _ := json.Marshal(loaded)
	if strings.Contains(string(encoded), "dedicated-secret") {
		t.Fatal("secret stored")
	}
}
