package catalog

import (
	"bufio"
	"context"
	"fmt"
	"net"
	"net/http"
	"reflect"
	"strings"
	"testing"
	"time"
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
	emotes, err := s.twitchEmotes(context.Background(), "user-token")
	if err != nil || len(emotes) != 2 || emotes[0].Category != nil || emotes[1].Category != "Category" {
		t.Fatalf("owner categories: %+v %v", emotes, err)
	}
}
func TestIRCEmoteStateAndCancellation(t *testing.T) {
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()
	serverDone := make(chan struct{})
	go func() {
		defer close(serverDone)
		reader := bufio.NewReader(server)
		for _, prefix := range []string{"CAP REQ :twitch.tv/tags twitch.tv/commands", "PASS oauth:user-token", "NICK streamer"} {
			line, err := reader.ReadString('\n')
			if err != nil || strings.TrimSpace(line) != prefix {
				t.Error("incorrect IRC login sequence")
				return
			}
		}
		fmt.Fprint(server, "PING :tmi.twitch.tv\r\n")
		line, err := reader.ReadString('\n')
		if err != nil || strings.TrimSpace(line) != "PONG :tmi.twitch.tv" {
			t.Error("PING not answered")
			return
		}
		fmt.Fprint(server, "@emote-sets=0,11,22;user-id=123 :tmi.twitch.tv GLOBALUSERSTATE\r\n")
	}()
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	sets, err := readEmoteSets(ctx, client, "user-token", "streamer")
	if err != nil || !reflect.DeepEqual(sets, []string{"0", "11", "22"}) {
		t.Fatalf("IRC state %v %v", sets, err)
	}
	<-serverDone
	client2, server2 := net.Pipe()
	defer client2.Close()
	defer server2.Close()
	ctx2, cancel2 := context.WithCancel(context.Background())
	done := make(chan struct{})
	go func() { defer close(done); readEmoteSets(ctx2, client2, "token", "login") }()
	cancel2()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("IRC cancellation leaked connection")
	}
	if _, err := readEmoteSets(context.Background(), client, "injected\r\nJOIN #channel", "login"); err == nil {
		t.Fatal("IRC command injection accepted")
	}
}
