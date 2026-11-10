package main

import (
	"bytes"
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

	"github.com/muxable/rtchat/agent/internal/eventsubmigration"
)

func TestDefaultDryRunThenApplyResumeWithActualHelper(t *testing.T) {
	old := eventsubmigration.Subscription{ID: "old", Type: "channel.raid", Version: "1", Status: "enabled", Condition: json.RawMessage(`{"from_broadcaster_user_id":"123"}`), Transport: eventsubmigration.Transport{Method: "webhook", Callback: eventsubmigration.LegacyCallback}}
	state := map[string]eventsubmigration.Subscription{"old": old}
	posts, deletes := 0, 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			data := []eventsubmigration.Subscription{}
			for id, sub := range state {
				if wanted := r.URL.Query().Get("subscription_id"); wanted != "" && wanted != id {
					continue
				}
				data = append(data, sub)
			}
			json.NewEncoder(w).Encode(eventsubmigration.Listing{Data: data, MaxTotalCost: 100})
		case http.MethodPost:
			posts++
			var body struct {
				Type, Version string
				Condition     json.RawMessage
				Transport     struct{ Method, Callback, Secret string }
			}
			json.NewDecoder(r.Body).Decode(&body)
			if body.Transport.Secret != "dedicated-signing-secret" || body.Transport.Callback != eventsubmigration.TargetCallback {
				t.Error(body.Transport)
			}
			next := old
			next.ID = "new"
			next.Transport.Callback = body.Transport.Callback
			state["new"] = next
			w.WriteHeader(202)
			json.NewEncoder(w).Encode(eventsubmigration.Listing{Data: []eventsubmigration.Subscription{next}})
		case http.MethodDelete:
			deletes++
			delete(state, r.URL.Query().Get("id"))
			w.WriteHeader(204)
		}
	}))
	defer server.Close()
	secrets, locks := 0, 0
	deps := runtime{
		LoadAPI: func(context.Context) (*eventsubmigration.API, string, error) {
			return &eventsubmigration.API{Client: server.Client(), BaseURL: server.URL, ClientID: "client", Token: "private-token", Pacer: fastPacer()}, "legacy-client-secret", nil
		},
		Activity: func(_ context.Context, ids []string) (map[string]time.Time, error) {
			if fmt.Sprint(ids) != "[123]" {
				t.Error(ids)
			}
			return nil, nil
		},
		SigningSecret: func(context.Context) (string, error) { secrets++; return "dedicated-signing-secret", nil },
		Lock: func(context.Context) (eventsubmigration.Locker, func(), error) {
			locks++
			return func(ctx context.Context, key string, fn func(context.Context) error) error {
				if key != "twitch:123" {
					t.Error(key)
				}
				return fn(ctx)
			}, func() {}, nil
		},
	}
	path := filepath.Join(t.TempDir(), "backup.json")
	var output bytes.Buffer
	if err := runWith(context.Background(), []string{"--backup", path}, &output, deps); err != nil {
		t.Fatal(err)
	}
	if posts != 0 || deletes != 0 || secrets != 0 || locks != 0 || !strings.Contains(output.String(), "DRY RUN") {
		t.Fatal(posts, deletes, secrets, locks, output.String())
	}
	if err := runWith(context.Background(), []string{"--backup", path, "--apply"}, &output, deps); err == nil {
		t.Fatal("existing backup overwritten")
	}
	if posts != 0 || deletes != 0 {
		t.Fatal("failed backup allowed mutations")
	}
	if err := runWith(context.Background(), []string{"--backup", path, "--resume", "--apply"}, &output, deps); err != nil {
		t.Fatal(err)
	}
	if posts != 1 || deletes != 1 || secrets != 1 || locks != 1 {
		t.Fatal(posts, deletes, secrets, locks)
	}
	if err := runWith(context.Background(), []string{"--backup", path, "--resume", "--apply"}, &output, deps); err != nil {
		t.Fatal(err)
	}
	if posts != 1 || deletes != 1 {
		t.Fatal("resume duplicated completed work", posts, deletes)
	}
	if !strings.Contains(output.String(), "migrated this run 0; already migrated 1; failed this run 0") || !strings.Contains(output.String(), "remaining 0") {
		t.Fatal("summary missing", output.String())
	}
	saved, err := os.ReadFile(path + ".state.json")
	if err != nil || !strings.Contains(string(saved), `"deletedOld": true`) {
		t.Fatal("journal not compacted into state", string(saved), err)
	}
	for _, filename := range []string{path, path + ".state.json", path + ".journal.jsonl"} {
		data, err := os.ReadFile(filename)
		if err != nil {
			t.Fatal(err)
		}
		for _, secret := range []string{"private-token", "legacy-client-secret", "dedicated-signing-secret"} {
			if strings.Contains(string(data), secret) {
				t.Fatal("persisted credential", filename)
			}
		}
	}
}
func TestCLIArgumentAndConcurrentCheckpointGuards(t *testing.T) {
	options, err := parse(nil)
	if err != nil || options.apply || options.rollback || options.resume || options.verify || options.limit != 20 || options.rate != 150 || options.reserve != 200 || options.maxAttempts != 3 {
		t.Fatal(options, err)
	}
	for _, args := range [][]string{{"--all"}, {"--limit", "0"}} {
		if options, err = parse(append(args, "--timeout", "96h")); err != nil || options.limit != 0 || options.timeout != 96*time.Hour {
			t.Fatal(args, options, err)
		}
	}
	for _, args := range [][]string{{"--rollback"}, {"--limit", "-1"}, {"--timeout", "0"}, {"--timeout", "200h"}, {"--rate", "0"}, {"--rate", "900"}, {"--max-attempts", "0"}, {"--project", "unrelated"}, {"unexpected"}} {
		if _, err := parse(args); err == nil {
			t.Fatal(fmt.Sprint(args))
		}
	}
	path := filepath.Join(t.TempDir(), "checkpoint.lock")
	release, err := lockCheckpoint(path)
	if err != nil {
		t.Fatal(err)
	}
	if releaseOther, err := lockCheckpoint(path); err == nil {
		releaseOther()
		t.Fatal("concurrent checkpoint writer accepted")
	}
	release()
	release, err = lockCheckpoint(path)
	if err != nil {
		t.Fatal(err)
	}
	release()
}

func fastPacer() *eventsubmigration.Pacer {
	pacer := eventsubmigration.NewPacer(150, 200)
	now := time.Unix(1_800_000_000, 0)
	pacer.Now = func() time.Time { return now }
	pacer.Sleep = func(ctx context.Context, d time.Duration) error { now = now.Add(d); return ctx.Err() }
	return pacer
}

func TestDryRunOrdersByActivityAndAcceptsPreexistingDestinations(t *testing.T) {
	subscription := func(id, broadcaster, callback string) eventsubmigration.Subscription {
		return eventsubmigration.Subscription{ID: id, Type: "stream.online", Version: "1", Status: "enabled", Cost: 1, Condition: json.RawMessage(`{"broadcaster_user_id":"` + broadcaster + `"}`), Transport: eventsubmigration.Transport{Method: "webhook", Callback: callback}}
	}
	subs := []eventsubmigration.Subscription{
		subscription("a", "1", eventsubmigration.LegacyCallback),
		subscription("b", "2", eventsubmigration.LegacyCallback),
		subscription("c", "3", eventsubmigration.LegacyCallback),
		subscription("agent", "2", eventsubmigration.TargetCallback),
	}
	requests := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requests++
		if r.Method != http.MethodGet {
			t.Error("dry run mutated", r.Method)
		}
		json.NewEncoder(w).Encode(eventsubmigration.Listing{Data: subs, TotalCost: 11920, MaxTotalCost: 10000})
	}))
	defer server.Close()
	deps := runtime{
		LoadAPI: func(context.Context) (*eventsubmigration.API, string, error) {
			return &eventsubmigration.API{Client: server.Client(), BaseURL: server.URL, ClientID: "client", Token: "token", Pacer: fastPacer()}, "legacy-client-secret", nil
		},
		Activity: func(context.Context, []string) (map[string]time.Time, error) {
			return map[string]time.Time{"1": time.Unix(100, 0), "2": time.Unix(200, 0)}, nil
		},
	}
	var output bytes.Buffer
	if err := runWith(context.Background(), []string{"--backup", filepath.Join(t.TempDir(), "backup.json"), "--all"}, &output, deps); err != nil {
		t.Fatal(err)
	}
	text := output.String()
	if strings.Contains(text, "BLOCKER") || !strings.Contains(text, "destinations already at "+eventsubmigration.TargetCallback+": 1") || !strings.Contains(text, "exceeds max_total_cost") {
		t.Fatal(text)
	}
	b, a, c := strings.Index(text, "\nb "), strings.Index(text, "\na "), strings.Index(text, "\nc ")
	if b < 0 || !(b < a && a < c) || requests != 1 {
		t.Fatal("not ordered most recently active first", text)
	}
}
