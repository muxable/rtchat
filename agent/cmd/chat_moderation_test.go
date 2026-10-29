package main

import (
	"encoding/json"
	"net/http"
	"strings"
	"testing"

	"github.com/muxable/rtchat/agent/internal/observability"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"
)

func TestTwitchModerationRejectionReporting(t *testing.T) {
	for _, tc := range []struct {
		name, action, message      string
		providerStatus, wantStatus int
		wantCode, wantMessage      string
	}{
		{"already banned", "ban", "user is already banned", 400, 400, "FAILED_PRECONDITION", "This user is already banned."},
		{"banned user timeout", "timeout", "user is already banned", 400, 400, "FAILED_PRECONDITION", "This user is already banned."},
		{"protected user", "ban", "user may not be banned", 400, 400, "FAILED_PRECONDITION", "Twitch does not allow banning this user."},
		{"protected timeout", "timeout", "user may not be put in a timeout", 400, 400, "FAILED_PRECONDITION", "Twitch does not allow timing out this user."},
		{"already unbanned", "unban", "user is not banned", 400, 400, "FAILED_PRECONDITION", "This user is not banned."},
		{"documented wording", "ban", "The user specified in the user_id field is already banned.", 400, 400, "FAILED_PRECONDITION", "This user is already banned."},
		{"missing provider parameter", "ban", "user_id is required", 400, 500, "INTERNAL", "INTERNAL"},
		{"unexpected response", "ban", "private-provider-detail", 400, 500, "INTERNAL", "INTERNAL"},
		{"not a matching reason", "ban", "user is already banned private-provider-detail", 400, 500, "INTERNAL", "INTERNAL"},
		{"forbidden", "ban", "private-provider-detail", 403, 500, "INTERNAL", "INTERNAL"},
		{"server failure with known text", "ban", "user is already banned", 503, 500, "INTERNAL", "INTERNAL"},
		{"rate limited", "ban", "private-provider-detail", 429, 429, "RESOURCE_EXHAUSTED", "too many requests, try again shortly"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			core, logs := observer.New(zap.InfoLevel)
			defer zap.ReplaceGlobals(zap.New(observability.Wrap(core)))()
			requests := 0
			s, _ := newMock(func(r *http.Request) (*http.Response, error) {
				requests++
				if r.URL.Path != "/helix/moderation/bans" {
					t.Fatalf("unexpected endpoint: %s", r.URL.Path)
				}
				payload, err := json.Marshal(map[string]any{"message": tc.message, "access_token": "private-provider-detail"})
				if err != nil {
					t.Fatal(err)
				}
				return respond(tc.providerStatus, string(payload)), nil
			})
			code, body := call(t, s, tc.action, map[string]any{"provider": "twitch", "channelId": "broadcaster", "userId": "target", "length": 60, "reason": "moderation"}, true)
			e := object(body["error"])
			if requests != 1 || code != tc.wantStatus || e["status"] != tc.wantCode || e["message"] != tc.wantMessage {
				t.Fatalf("requests=%d code=%d response=%v", requests, code, body)
			}
			entries := logs.FilterMessage("http request").All()
			if len(entries) != 1 {
				t.Fatal(entries)
			}
			fields := entries[0].ContextMap()
			if fields["status"] != int64(tc.wantStatus) {
				t.Fatal(fields)
			}
			if tc.wantStatus < 500 && (entries[0].Level != zap.InfoLevel || fields["@type"] != nil) {
				t.Fatalf("user rejection reported as an agent issue: %v", fields)
			}
			if tc.wantStatus >= 500 && fields["@type"] == nil {
				t.Fatalf("unexpected failure no longer reported: %v", fields)
			}
			logged, err := json.Marshal(fields)
			if err != nil {
				t.Fatal(err)
			}
			encoded, err := json.Marshal(body)
			if err != nil {
				t.Fatal(err)
			}
			if strings.Contains(string(logged)+string(encoded), "private-provider-detail") {
				t.Fatal("provider details leaked")
			}
		})
	}
}

func TestTwitchModerationMissingUserDoesNotSendInvalidBan(t *testing.T) {
	for _, action := range []string{"ban", "unban", "timeout"} {
		t.Run(action, func(t *testing.T) {
			requests := 0
			s, _ := newMock(func(r *http.Request) (*http.Response, error) {
				requests++
				if r.URL.Path != "/helix/users" {
					t.Fatalf("moderation request for a missing user: %s", r.URL.Path)
				}
				return respond(200, `{"data":[]}`), nil
			})
			code, body := call(t, s, action, map[string]any{"provider": "twitch", "channelId": "broadcaster", "username": "missing", "length": 60, "reason": "moderation"}, true)
			if code != 404 || object(body["error"])["status"] != "NOT_FOUND" || requests != 1 {
				t.Fatal(code, body, requests)
			}
		})
	}
}
