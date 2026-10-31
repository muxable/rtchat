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
		{"unrecognized unban rejection", "unban", "private-provider-detail", 400, 400, "FAILED_PRECONDITION", "Twitch rejected this unban request."},
		{"empty unban rejection", "unban", "", 400, 500, "INTERNAL", "INTERNAL"},
		{"blank unban rejection", "unban", "  ", 400, 500, "INTERNAL", "INTERNAL"},
		{"unban server failure", "unban", "user is not banned", 503, 500, "INTERNAL", "INTERNAL"},
		{"unban forbidden", "unban", "private-provider-detail", 403, 500, "INTERNAL", "INTERNAL"},
		{"documented wording", "ban", "The user specified in the user_id field is already banned.", 400, 400, "FAILED_PRECONDITION", "This user is already banned."},
		{"missing provider parameter", "ban", "user_id is required", 400, 500, "INTERNAL", "INTERNAL"},
		{"unrecognized ban rejection", "ban", "private-provider-detail", 400, 400, "FAILED_PRECONDITION", "Twitch rejected this ban request."},
		{"unrecognized timeout rejection", "timeout", "private-provider-detail", 400, 400, "FAILED_PRECONDITION", "Twitch rejected this timeout request."},
		{"not a matching reason", "ban", "user is already banned private-provider-detail", 400, 400, "FAILED_PRECONDITION", "Twitch rejected this ban request."},
		{"empty ban rejection", "ban", "", 400, 500, "INTERNAL", "INTERNAL"},
		{"missing query parameter", "ban", `Missing required parameter "moderator_id"`, 400, 500, "INTERNAL", "INTERNAL"},
		{"malformed parameter", "timeout", "The value in the duration field is not valid.", 400, 500, "INTERNAL", "INTERNAL"},
		{"malformed unban", "unban", "The user_id query parameter is required.", 400, 500, "INTERNAL", "INTERNAL"},
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

func TestTwitchUnbanMalformedRejection(t *testing.T) {
	for _, payload := range []string{`not JSON`, `{"message":42}`, `{"message":"private-provider-detail"`, `{}`, `null`} {
		t.Run(payload, func(t *testing.T) {
			s, _ := newMock(func(r *http.Request) (*http.Response, error) {
				return respond(400, payload), nil
			})
			code, body := call(t, s, "unban", map[string]any{"provider": "twitch", "channelId": "broadcaster", "userId": "target"}, true)
			if code != 500 || object(body["error"])["status"] != "INTERNAL" {
				t.Fatal(code, body)
			}
		})
	}
}

func TestTwitchTimeoutBoundsCheckedLocally(t *testing.T) {
	for _, tc := range []struct {
		name   string
		length float64
		reason string
	}{
		{"too long", 1209601, "moderation"},
		{"fractional", 1.5, "moderation"},
		{"negative", -60, "moderation"},
		{"long reason", 60, strings.Repeat("é", 501)},
	} {
		t.Run(tc.name, func(t *testing.T) {
			s, _ := newMock(func(r *http.Request) (*http.Response, error) {
				t.Fatalf("invalid timeout sent to Twitch: %s", r.URL.Path)
				return nil, nil
			})
			code, body := call(t, s, "timeout", map[string]any{"provider": "twitch", "channelId": "broadcaster", "userId": "target", "length": tc.length, "reason": tc.reason}, true)
			if code != 400 || object(body["error"])["status"] != "INVALID_ARGUMENT" {
				t.Fatal(code, body)
			}
		})
	}
}
