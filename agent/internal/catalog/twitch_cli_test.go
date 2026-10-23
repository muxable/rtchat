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
	emoteBatches := []int{}
	requestAuth := map[string]string{}
	s.HTTP = mock.HTTPClient(func(r *http.Request, body []byte) {
		var result map[string]any
		if json.Unmarshal(body, &result) != nil {
			return
		}
		mu.Lock()
		captured[r.URL.Path] = append(captured[r.URL.Path], result)
		requestAuth[r.URL.Path] = r.Header.Get("Authorization")
		if r.URL.Path == "/helix/chat/emotes/set" {
			emoteBatches = append(emoteBatches, len(r.URL.Query()["emote_set_id"]))
		}
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
	t.Run("legacy mixed ordering and Kick fallback", func(t *testing.T) {
		// Twitch data comes from the CLI; only Kick's unsupported service is stubbed.
		query := user.Login[:3]
		cliClient := s.HTTP
		defer func() { s.HTTP = cliClient }()
		kickFails := false
		s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
			if r.URL.Host != "api.kick.com" {
				return cliClient.Transport.RoundTrip(r)
			}
			if kickFails || r.URL.Path == "/public/v1/users" {
				return response(503, `{}`), nil
			}
			return response(200, `{"data":[{"broadcaster_user_id":1234567,"slug":"`+query+`","stream":{"is_live":true,"viewer_count":4,"language":"en"},"category":{"name":"IRL"},"stream_title":"Title"}]}`), nil
		})}
		status, result := invoke(t, s, "search", body(query), "")
		items := array(result["result"])
		wantKick := map[string]any{
			"provider": "kick", "channelId": "1234567", "login": query,
			"displayName": query, "isOnline": true, "viewerCount": float64(4),
			"categoryName": "IRL", "title": "Title", "language": "en",
			"imageUrl": "https://rtirl.com/pfp.png?provider=kick&channelId=1234567",
		}
		if status != 200 || len(items) < 2 || !reflect.DeepEqual(items[0], wantKick) {
			t.Fatalf("mixed ordering/large Kick ID: %+v", result)
		}
		kickFails = true
		status, result = invoke(t, s, "search", body(query), "")
		if status != 200 || len(array(result["result"])) != len(items)-1 {
			t.Fatal("Kick failure discarded CLI Twitch results")
		}
	})

	t.Run("followed", func(t *testing.T) {
		status, result := invoke(t, s, "search", `{"provider":"twitch","query":""}`, "uid")
		items := array(result["result"])
		raw := array(last("streams/followed")["data"])
		if status != 200 || len(items) != len(raw) {
			t.Fatal(result)
		}
		if requestAuth["/helix/streams/followed"] != "Bearer "+userToken {
			t.Fatal("followed channels used app token")
		}
		for i, item := range items {
			channel := raw[i]
			want := map[string]any{"provider": "twitch", "channelId": channel["user_id"], "login": channel["user_login"], "displayName": channel["user_name"], "isOnline": channel["type"] == "live", "imageUrl": "https://rtirl.com/pfp.png?provider=twitch&channelId=" + text(channel["user_id"]), "categoryName": channel["game_name"], "title": channel["title"], "viewerCount": channel["viewer_count"], "language": channel["language"]}
			if !reflect.DeepEqual(item, want) {
				t.Fatal("full followed-channel schema differs")
			}
		}
		beforeSearch := len(captured["/helix/search/channels"])
		beforeFollowed := len(captured["/helix/streams/followed"])
		delete(tokens.user, "uid:twitch")
		defer func() { tokens.user["uid:twitch"] = userToken }()
		// Without a user token there is nothing to list, and Twitch rejects an
		// empty channel search, so the fallback answers with no results.
		status, result = invoke(t, s, "search", `{"provider":"twitch","query":""}`, "uid")
		if status != 200 || result["result"] == nil || len(array(result["result"])) != 0 || len(captured["/helix/search/channels"]) != beforeSearch || len(captured["/helix/streams/followed"]) != beforeFollowed {
			t.Fatal("missing user token did not fall back to an empty search", status, result)
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
		defer func() { tokens.app["twitch"] = mock.AppToken }()
		var streams struct {
			Data []struct {
				UserID string `json:"user_id"`
			}
		}
		if code, err := mock.Request("GET", "/units/streams", nil, "", &streams); err != nil || code != 200 {
			t.Fatalf("CLI stream inventory: %d %v", code, err)
		}
		liveIDs := map[string]bool{}
		for _, stream := range streams.Data {
			liveIDs[stream.UserID] = true
		}
		offline := ""
		for _, candidate := range mock.Users {
			if !liveIDs[candidate.ID] {
				offline = candidate.ID
				break
			}
		}
		if offline == "" {
			t.Fatal("CLI generated no offline users")
		}
		for _, channelID := range []string{user.ID, offline} {
			tokens.app["twitch"] = mock.UserToken(t, channelID, "moderator:read:followers")
			status, result := invoke(t, s, "getStatistics", body(map[string]any{"provider": "twitch", "channelId": channelID}), "")
			stats := object(result["result"])
			stream := first(last("streams")["data"])
			channel := first(last("channels")["data"])
			followers := last("channels/followers")["total"]
			viewers := any(float64(0))
			if stream != nil {
				viewers = stream["viewer_count"]
			}
			if status != 200 || stats["isOnline"] != (stream != nil) || stats["viewers"] != viewers || stats["followers"] != followers || stats["language"] != channel["broadcaster_language"] {
				t.Fatalf("CLI online/offline statistics differ: %+v", result)
			}
		}

		t.Log("CLI requires scoped user token for successful follower-total test; production app-token path validated separately")
	})
	t.Run("emotes", func(t *testing.T) {
		// Twitch CLI implements Helix emotes but no IRC server. The independent
		// net.Pipe test covers the real IRC handshake/discovery/cancellation logic.
		s.EmoteSets = func(_ context.Context, token, login string) ([]string, error) {
			if token != userToken || login != user.Login {
				t.Fatal("IRC discovery did not use the generated user identity")
			}
			sets := []string{}
			for i := 0; i < 26; i++ {
				sets = append(sets, fmt.Sprint(i))
			}
			return sets, nil
		}
		status, result := invoke(t, s, "getEmotes", body(map[string]any{"provider": "twitch", "channelId": user.ID}), "uid")
		items := array(result["result"])
		sources := captured["/helix/chat/emotes/set"]
		if status != 200 || len(items) == 0 || !reflect.DeepEqual(emoteBatches, []int{25, 1}) {
			t.Fatalf("CLI emote set batching: %v, result=%+v", emoteBatches, result)
		}
		index := 0
		for _, raw := range sources {
			for _, source := range array(raw["data"]) {
				if index >= len(items) {
					t.Fatal("CLI emotes dropped")
				}
				item := items[index]
				index++
				scales, _ := source["scale"].([]any)
				scale := fmt.Sprint(scales[len(scales)-1])
				image := strings.NewReplacer("{{id}}", text(source["id"]), "{{format}}", "default", "{{theme_mode}}", "dark", "{{scale}}", scale).Replace(text(raw["template"]))
				if item["provider"] != "twitch" || item["id"] != source["id"] || item["code"] != source["name"] || item["imageUrl"] != image {
					t.Fatal("CLI emote transformation differs")
				}
			}
		}
		if index != len(items) {
			t.Fatal("unexpected extra Twitch emotes")
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
		roleIDs := map[string]map[string]bool{"moderators": {}, "vips": {}}
		for key, path := range map[string]string{"moderators": "moderation/moderators", "vips": "channels/vips"} {
			for _, u := range array(last(path)["data"]) {
				roleIDs[key][text(u["user_id"])] = true
			}
			if len(array(groups[key+"Data"])) != len(roleIDs[key]) {
				t.Fatal("CLI role membership count changed")
			}
			for _, u := range array(groups[key+"Data"]) {
				if !roleIDs[key][text(u["user_id"])] {
					t.Fatal("viewer placed in incorrect role group")
				}
			}
		}
		for _, u := range array(groups["viewersData"]) {
			id := text(u["user_id"])
			if id == user.ID || roleIDs["moderators"][id] || roleIDs["vips"][id] {
				t.Fatal("privileged chatter not filtered from viewers")
			}
		}
		broadcaster := array(groups["broadcasterData"])
		if len(broadcaster) != 1 || broadcaster[0]["user_id"] != user.ID {
			t.Fatal("broadcaster role missing")
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
