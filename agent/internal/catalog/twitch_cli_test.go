package catalog

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"reflect"
	"strings"
	"sync"
	"testing"

	"github.com/muxable/rtchat/agent/internal/twitchtest"
)

// These tests use Twitch CLI-generated users, permissions and API responses.
// Only Firebase identities/profile mapping and IRC discovery are local seams.
func TestCatalogWithTwitchCLI(t *testing.T) {
	mock := twitchtest.Start(t)
	user := mock.Users[0]
	userToken := mock.UserToken(t, user.ID, "moderator:read:chatters", "moderation:read", "channel:read:vips", "user:read:follows", "moderator:read:followers")
	s, store, tokens := fixture()
	s.TwitchClientID = mock.ClientID
	tokens.app["twitch"] = mock.AppToken
	tokens.user["uid:twitch"] = userToken
	store.profiles["uid:twitch"] = map[string]any{"id": user.ID}
	store.owner = "uid"
	var mu sync.Mutex
	captured := map[string][]map[string]any{}
	s.HTTP = mock.HTTPClient(func(r *http.Request, body []byte) {
		var result map[string]any
		if json.Unmarshal(body, &result) != nil {
			return
		}
		mu.Lock()
		captured[r.URL.Path] = append(captured[r.URL.Path], result)
		mu.Unlock()
	})
	last := func(path string) map[string]any {
		t.Helper()
		mu.Lock()
		defer mu.Unlock()
		items := captured["/helix/"+path]
		if len(items) == 0 {
			t.Fatalf("handler never called CLI %s", path)
		}
		return items[len(items)-1]
	}
	body := func(v any) string { raw, _ := json.Marshal(v); return string(raw) }
	t.Run("search", func(t *testing.T) {
		status, result := invoke(t, s, "search", body(map[string]any{"provider": "twitch", "query": user.Login}), "")
		items := array(result["result"])
		if status != 200 || len(items) == 0 {
			t.Fatal(result)
		}
		raw := first(last("search/channels")["data"])
		item := items[0]
		if item["channelId"] != user.ID || item["login"] != user.Login || item["displayName"] != user.DisplayName || item["title"] != raw["title"] || item["language"] != raw["broadcaster_language"] || item["isOnline"] != raw["is_live"] {
			t.Fatalf("generated search mismatch: %+v", item)
		}
		status, legacy := invoke(t, s, "search", body(user.Login), "")
		if status != 200 || !reflect.DeepEqual(result["result"], legacy["result"]) {
			t.Fatal("raw-string old client shape diverged")
		}
	})
	t.Run("followed", func(t *testing.T) {
		status, result := invoke(t, s, "search", `{"provider":"twitch","query":""}`, "uid")
		items := array(result["result"])
		raw := array(last("streams/followed")["data"])
		if status != 200 || len(items) != len(raw) {
			t.Fatal(result)
		}
		for i, item := range items {
			if item["channelId"] != raw[i]["user_id"] || item["viewerCount"] != raw[i]["viewer_count"] || item["login"] != raw[i]["user_login"] {
				t.Fatal("followed response transformation differs")
			}
		}
	})
	t.Run("badges", func(t *testing.T) {
		for _, channel := range []string{"", user.ID} {
			status, result := invoke(t, s, "getBadges", body(map[string]any{"provider": "twitch", "channelId": channel}), "")
			path := "chat/badges"
			if channel == "" {
				path += "/global"
			}
			if status != 200 || !reflect.DeepEqual(result["result"], last(path)["data"]) {
				t.Fatal("raw badge/version output differs from CLI response")
			}
		}
	})
	t.Run("statistics", func(t *testing.T) {
		// CLI 1.1.24 requires moderator-scoped user auth for follower totals, while
		// production allows our app token (also checked in live parity validation).
		status, _ := invoke(t, s, "getStatistics", body(map[string]any{"provider": "twitch", "channelId": user.ID}), "")
		if status != 403 {
			t.Fatalf("CLI app-token follower restriction changed: %d", status)
		}
		tokens.app["twitch"] = userToken
		defer func() { tokens.app["twitch"] = mock.AppToken }()
		status, result := invoke(t, s, "getStatistics", body(map[string]any{"provider": "twitch", "channelId": user.ID}), "")
		stats := object(result["result"])
		stream := first(last("streams")["data"])
		channel := first(last("channels")["data"])
		followers := last("channels/followers")["total"]
		if status != 200 || stats["isOnline"] != (stream != nil) || stats["viewers"] != stream["viewer_count"] || stats["followers"] != followers || stats["language"] != channel["broadcaster_language"] {
			t.Fatalf("CLI statistics schema differs %+v", result)
		}
		t.Log("CLI requires scoped user token for successful follower-total test; production app-token path validated separately")
	})
	t.Run("emotes", func(t *testing.T) {
		// Twitch CLI implements Helix emotes but no IRC server. The independent
		// net.Pipe test covers the real IRC handshake/discovery/cancellation logic.
		s.EmoteSets = func(context.Context, string, string) ([]string, error) { return []string{"0"}, nil }
		status, result := invoke(t, s, "getEmotes", body(map[string]any{"provider": "twitch", "channelId": user.ID}), "uid")
		items := array(result["result"])
		raw := last("chat/emotes/set")
		source := array(raw["data"])
		if status != 200 || len(items) == 0 || len(items) != len(source) {
			t.Fatal(result)
		}
		for i, item := range items {
			scales, _ := source[i]["scale"].([]any)
			scale := fmt.Sprint(scales[len(scales)-1])
			image := strings.NewReplacer("{{id}}", text(source[i]["id"]), "{{format}}", "default", "{{theme_mode}}", "dark", "{{scale}}", scale).Replace(text(raw["template"]))
			if item["provider"] != "twitch" || item["id"] != source[i]["id"] || item["code"] != source[i]["name"] || item["imageUrl"] != image {
				t.Fatal("CLI emote transformation differs")
			}
		}
	})
	t.Run("viewers", func(t *testing.T) {
		status, result := invoke(t, s, "getViewerList", body("twitch:"+user.ID), "uid")
		groups := object(result["result"])
		if status != 200 {
			t.Fatal(result)
		}
		all := map[string]bool{}
		for _, key := range []string{"broadcaster", "moderators", "vips", "viewers"} {
			full := array(groups[key+"Data"])
			names, _ := groups[key].([]any)
			if len(full) != len(names) {
				t.Fatal("legacy and full viewer data differ")
			}
			for i, u := range full {
				if names[i] != u["user_name"] {
					t.Fatal("legacy username mismatch")
				}
				all[text(u["user_id"])] = true
			}
		}
		chatters := array(last("chat/chatters")["data"])
		if len(chatters) == 0 || len(all) != len(chatters) {
			t.Fatalf("generated chatter coverage: got %d want %d", len(all), len(chatters))
		}
		for _, u := range chatters {
			if !all[text(u["user_id"])] {
				t.Fatal("chatter lost during role grouping")
			}
		}
		status, _ = invoke(t, s, "getViewerList", body("twitch:"+user.ID), "")
		if status != 401 {
			t.Fatal("unauthenticated access accepted")
		}
		tokens.user["uid:twitch"] = mock.UserToken(t, user.ID, "user:read:email")
		defer func() { tokens.user["uid:twitch"] = userToken }()
		status, _ = invoke(t, s, "getViewerList", body("twitch:"+user.ID), "uid")
		if status != 403 {
			t.Fatalf("CLI missing chatter scope accepted: %d", status)
		}
	})
	// A direct CLI probe proves the endpoints actually enforce generated tokens.
	var raw map[string]any
	if status, err := mock.Request("GET", "/mock/chat/chatters", url.Values{"broadcaster_id": {user.ID}, "moderator_id": {user.ID}}, mock.AppToken, &raw); err != nil || status != 401 {
		t.Fatalf("CLI permission probe %d %v", status, err)
	}
}
