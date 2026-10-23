package catalog

import (
	"context"
	"net/http"
	"strings"
	"testing"
)

func TestAllThirdPartyEmoteSourcesAndFallback(t *testing.T) {
	s, _, _ := fixture()
	failLocal := false
	s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		if failLocal && (strings.Contains(r.URL.Path, "/users/") || strings.Contains(r.URL.Path, "/room/")) {
			return response(404, `{}`), nil
		}
		switch r.URL.Host + r.URL.Path {
		case "api.betterttv.net/3/cached/emotes/global":
			return response(200, `[{"id":"bg","code":"BTTVGlobal"}]`), nil
		case "api.betterttv.net/3/cached/users/twitch/123":
			return response(200, `{"channelEmotes":[{"id":"bc","code":"BTTVChannel"}],"sharedEmotes":[{"id":"bs","code":"BTTVShared"}]}`), nil
		case "api.frankerfacez.com/v1/set/global":
			return response(200, `{"default_sets":[1539687],"sets":{"1539687":{"title":"FFZ Global","emoticons":[{"id":11,"name":"FFZGlobal","urls":{"1":"https://one","2":"https://two","4":"https://four"}}]}}}`), nil
		case "api.frankerfacez.com/v1/room/id/123":
			return response(200, `{"room":{"set":1154282},"sets":{"1154282":{"title":"FFZ Channel","emoticons":[{"id":22,"name":"FFZChannel","urls":{"1":"https://one"}}]}}}`), nil
		case "7tv.io/v3/emote-sets/global":
			return response(200, `{"emotes":[{"id":"sg","name":"SevenGlobal"}]}`), nil
		case "7tv.io/v3/users/twitch/123":
			return response(200, `{"emote_set":{"emotes":[{"id":"sc","name":"SevenChannel"}]}}`), nil
		}
		t.Fatalf("unexpected endpoint %s", r.URL)
		return nil, nil
	})}
	status, result := invoke(t, s, "getEmotes", `{"provider":"twitch","channelId":"123"}`, "")
	items := array(result["result"])
	if status != 200 || len(items) != 7 {
		t.Fatal(result)
	}
	expected := []struct {
		provider, code, image string
		category              any
		id                    any
	}{{"bttv", "BTTVGlobal", "https://cdn.betterttv.net/emote/bg/3x", nil, "bg"}, {"bttv", "BTTVChannel", "https://cdn.betterttv.net/emote/bc/3x", "Channel Emotes", "bc"}, {"bttv", "BTTVShared", "https://cdn.betterttv.net/emote/bs/3x", "Shared Emotes", "bs"}, {"ffz", "FFZGlobal", "https://four", "FFZ Global", float64(11)}, {"ffz", "FFZChannel", "https://one", "FFZ Channel", float64(22)}, {"7tv", "SevenGlobal", "https://cdn.7tv.app/emote/sg/4x.webp", nil, "sg"}, {"7tv", "SevenChannel", "https://cdn.7tv.app/emote/sc/4x.webp", nil, "sc"}}
	for i, want := range expected {
		e := items[i]
		if e["provider"] != want.provider || e["code"] != want.code || e["imageUrl"] != want.image || e["category"] != want.category || e["id"] != want.id {
			t.Fatalf("emote schema %+v", e)
		}
	}
	failLocal = true
	status, result = invoke(t, s, "getEmotes", `{"provider":"twitch","channelId":"123"}`, "")
	if status != 200 || len(array(result["result"])) != 3 {
		t.Fatal("local provider failure dropped global emotes")
	}
}

// CLI gives random owner IDs that are absent from its generated users. Keep
// only this small category-resolution gap; batching/templates use real CLI data.
func TestTwitchEmoteOwnerCategories(t *testing.T) {
	s, _, _ := fixture()
	s.EmoteSets = func(context.Context, string, string) ([]string, error) { return []string{"0"}, nil }
	s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
		if r.URL.Path == "/helix/chat/emotes/set" {
			return response(200, `{"data":[{"owner_id":"0"},{"owner_id":"42"}]}`), nil
		}
		if r.URL.Query().Get("id") == "42" {
			return response(200, `{"data":[{"id":"42","display_name":"Category"}]}`), nil
		}
		return response(200, `{"data":[{"login":"streamer"}]}`), nil
	})}
	emotes, err := s.twitchEmotes(context.Background(), "user-token", "123")
	if err != nil || len(emotes) != 2 || emotes[0].Category != nil || emotes[1].Category != "Category" {
		t.Fatalf("owner categories: %+v %v", emotes, err)
	}
}

func TestTwitchUserEmotesWithFallback(t *testing.T) {
	for _, scoped := range []bool{true, false} {
		s, _, _ := fixture()
		irc := false
		s.EmoteSets = func(context.Context, string, string) ([]string, error) { irc = true; return []string{"1"}, nil }
		pages := 0
		s.HTTP = &http.Client{Transport: transport(func(r *http.Request) (*http.Response, error) {
			q := r.URL.Query()
			switch {
			case r.URL.Path == "/helix/chat/emotes/user":
				if !scoped {
					return response(403, `{"error":"Forbidden"}`), nil
				}
				if q.Get("user_id") != "7" || q.Get("broadcaster_id") != "123" {
					t.Fatalf("user emotes query %s", r.URL.RawQuery)
				}
				pages++
				if q.Get("after") == "" {
					return response(200, `{"template":"https://cdn/{{id}}/{{format}}/{{theme_mode}}/{{scale}}","data":[{"id":"a","name":"Kappa","owner_id":"0","scale":["1.0","3.0"]}],"pagination":{"cursor":"next"}}`), nil
				}
				return response(200, `{"template":"https://cdn/{{id}}/{{format}}/{{theme_mode}}/{{scale}}","data":[{"id":"b","name":"Follow","owner_id":"42","scale":["1.0"]}],"pagination":{}}`), nil
			case r.URL.Path == "/helix/chat/emotes/set":
				return response(200, `{"template":"https://cdn/{{id}}/{{format}}/{{theme_mode}}/{{scale}}","data":[{"id":"s","name":"SetEmote","owner_id":"42","scale":["2.0"]}]}`), nil
			case q.Get("id") == "42":
				return response(200, `{"data":[{"id":"42","display_name":"Streamer"}]}`), nil
			}
			return response(200, `{"data":[{"id":"7","login":"viewer"}]}`), nil
		})}
		emotes, err := s.twitchEmotes(context.Background(), "user-token", "123")
		if err != nil {
			t.Fatal(err)
		}
		if scoped {
			if irc || pages != 2 || len(emotes) != 2 || emotes[0].ImageURL != "https://cdn/a/default/dark/3.0" || emotes[0].Category != nil || emotes[1].Category != "Streamer" {
				t.Fatalf("user emotes: irc=%v pages=%d %+v", irc, pages, emotes)
			}
		} else if !irc || len(emotes) != 1 || emotes[0].Code != "SetEmote" || emotes[0].Category != "Streamer" {
			t.Fatalf("fallback: irc=%v %+v", irc, emotes)
		}
	}
}
