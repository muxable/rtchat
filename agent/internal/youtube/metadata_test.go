package youtube

import (
	"context"
	"io"
	"net/http"
	"reflect"
	"strings"
	"sync"
	"testing"
	"time"
)

func str(s string) *string { return &s }
func i64(n int64) *int64   { return &n }
func boolean(b bool) *bool { return &b }

func assertInfo(t *testing.T, got, want streamInfo) {
	t.Helper()
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %s, want %s", describe(got), describe(want))
	}
}
func describe(info streamInfo) string {
	var b strings.Builder
	v := reflect.ValueOf(info)
	for i := 0; i < v.NumField(); i++ {
		b.WriteString(v.Type().Field(i).Name)
		b.WriteString("=")
		if v.Field(i).IsNil() {
			b.WriteString("nil ")
		} else {
			b.WriteString(strings.TrimSpace(strings.Replace(reflect.Indirect(v.Field(i)).String(), "<", "", 1)))
			b.WriteString(" ")
		}
	}
	return b.String()
}

const endedPlayer = `{"videoDetails":{"title":"Done","author":"Lofi Girl","isLiveContent":true},"microformat":{"playerMicroformatRenderer":{"category":"Music","liveBroadcastDetails":{"isLiveNow":false,"startTimestamp":"2026-10-01T17:00:26+00:00","endTimestamp":"2026-10-14T22:00:00+00:00"}}}}`

func TestPageInfo(t *testing.T) {
	info, err := pageInfo(fixture(t, "watch_live.html"))
	if err != nil {
		t.Fatal(err)
	}
	assertInfo(t, info, streamInfo{Live: boolean(true), Title: str("24/7 halloween ambience 🎃 spooky lofi to get chills to"),
		DisplayName: str("Lofi Girl"), Category: str("Music"), ViewerCount: i64(3921)})
	channel, err := pageInfo(fixture(t, "channel_offline.html"))
	if err != nil {
		t.Fatal(err)
	}
	assertInfo(t, channel, streamInfo{DisplayName: str("Google for Developers"), Login: str("GoogleDevelopers")})
	if _, err := pageInfo([]byte(`<html>offline</html>`)); err == nil {
		t.Fatal("expected missing ytInitialData")
	}
}

func TestPlayerInfo(t *testing.T) {
	info, err := playerInfo(fixture(t, "innertube_player.json"))
	if err != nil {
		t.Fatal(err)
	}
	start := time.Date(2026, 10, 1, 17, 0, 26, 0, time.UTC)
	if info.StartedAt == nil || !info.StartedAt.Equal(start) {
		t.Fatalf("start %v", info.StartedAt)
	}
	info.StartedAt = nil
	assertInfo(t, info, streamInfo{Live: boolean(true), Title: str("24/7 halloween ambience 🎃 spooky lofi to get chills to"),
		DisplayName: str("Lofi Girl"), Login: str("LofiGirl"), Category: str("Music")})

	upcoming, err := playerInfo([]byte(`{"videoDetails":{"title":"Soon","author":"A","isUpcoming":true},"microformat":{"playerMicroformatRenderer":{"category":"Gaming","ownerProfileUrl":"http://www.youtube.com/channel/UC1","liveBroadcastDetails":{"isLiveNow":false,"startTimestamp":"2030-01-01T00:00:00+00:00"}}}}`))
	if err != nil {
		t.Fatal(err)
	}
	assertInfo(t, upcoming, streamInfo{Live: boolean(false), Title: str("Soon"), DisplayName: str("A"), Category: str("Gaming")})

	ended, err := playerInfo([]byte(endedPlayer))
	if err != nil {
		t.Fatal(err)
	}
	end := time.Date(2026, 10, 14, 22, 0, 0, 0, time.UTC)
	if ended.EndedAt == nil || !ended.EndedAt.Equal(end) || ended.StartedAt != nil || *ended.Live {
		t.Fatalf("ended %s", describe(ended))
	}
}

func TestUpdatedMetadataInfo(t *testing.T) {
	info, err := updatedMetadataInfo(fixture(t, "innertube_updated_metadata.json"))
	if err != nil {
		t.Fatal(err)
	}
	assertInfo(t, info, streamInfo{Live: boolean(true), Title: str("24/7 halloween ambience 🎃 spooky lofi to get chills to"), ViewerCount: i64(3872)})

	waiting, err := updatedMetadataInfo([]byte(`{"actions":[{"updateViewershipAction":{"viewCount":{"videoViewCountRenderer":{"viewCount":{"simpleText":"12 waiting"},"originalViewCount":"12"}}}}]}`))
	if err != nil {
		t.Fatal(err)
	}
	assertInfo(t, waiting, streamInfo{Live: boolean(false)})
	empty, err := updatedMetadataInfo([]byte(`{}`))
	if err != nil {
		t.Fatal(err)
	}
	assertInfo(t, empty, streamInfo{})
	if _, err := updatedMetadataInfo([]byte(`{bad`)); err == nil {
		t.Fatal("expected error")
	}
}

func TestChannelFields(t *testing.T) {
	c := &Client{channel: "UC1"}
	start := time.Date(2026, 10, 1, 17, 0, 26, 123456789, time.UTC)
	got := c.channelFields(streamInfo{Title: str("t"), DisplayName: str("d"), Login: str("l"), Category: str("Gaming"), ViewerCount: i64(5)}, &start)
	want := map[string]interface{}{"onlineAt": start.Truncate(time.Millisecond), "viewerCount": int64(5), "title": "t", "displayName": "d", "login": "l", "categoryName": "Gaming", "categoryId": "20"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("live fields %v", got)
	}
	if got := c.channelFields(streamInfo{Category: str("Unknown")}, &start); got["categoryId"] != nil || got["categoryName"] != "Unknown" || got["viewerCount"] != nil {
		t.Fatalf("unknown category or viewers %v", got)
	}
	if _, ok := c.channelFields(streamInfo{}, &start)["viewerCount"]; ok {
		t.Fatal("unknown viewers overwrote the count")
	}
	if got := c.channelFields(streamInfo{ViewerCount: i64(5)}, nil); !reflect.DeepEqual(got, map[string]interface{}{"onlineAt": nil, "viewerCount": int64(0)}) {
		t.Fatalf("offline fields %v", got)
	}
	// Search shows channels with a displayName and needs their login.
	if got := c.channelFields(streamInfo{DisplayName: str("d")}, nil); got["login"] != "UC1" {
		t.Fatalf("login fallback %v", got)
	}
}

// metadataServer serves a live stream whose chat lasts until updated_metadata
// has been polled twice, then ends.
func metadataServer(t *testing.T, watch, player []string) (*testServer, func() (int, int)) {
	initial := htmlFixture(t, `var ytInitialData = `)
	updated := fixture(t, "innertube_updated_metadata.json")
	var mu sync.Mutex
	players, updates := 0, 0
	server := newTestServer(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		defer mu.Unlock()
		switch r.URL.Path {
		case "/channel/channel/live":
			io.WriteString(w, watch[0])
			if len(watch) > 1 {
				watch = watch[1:]
			}
		case "/live_chat":
			io.WriteString(w, initial)
		case "/youtubei/v1/player":
			if r.Method != http.MethodPost || !strings.Contains(r.URL.RawQuery, "key=public-key") {
				t.Errorf("bad player request %s %s", r.Method, r.URL)
			}
			io.WriteString(w, player[0])
			if len(player) > 1 {
				player = player[1:]
			}
			players++
		case "/youtubei/v1/updated_metadata":
			body, _ := io.ReadAll(r.Body)
			if !strings.Contains(string(body), `"videoId":"1-LpQekNa9g"`) || !strings.Contains(string(body), `"hl":"en"`) {
				t.Errorf("bad updated_metadata body %s", body)
			}
			w.Write(updated)
			updates++
		default:
			if updates >= 2 {
				io.WriteString(w, `{}`)
			} else {
				io.WriteString(w, `{"continuationContents":{"liveChatContinuation":{"continuations":[{"timedContinuationData":{"continuation":"next","timeoutMs":1}}]}}}`)
			}
		}
	}))
	return server, func() (int, int) { mu.Lock(); defer mu.Unlock(); return players, updates }
}

func runUntilOffline(t *testing.T, server *testServer) *memoryStore {
	t.Helper()
	store := &memoryStore{}
	c := testClient(t, server, store)
	c.metadataInterval = 5 * time.Millisecond
	c.start()
	defer c.Close()
	eventually(t, func() bool {
		store.mu.Lock()
		defer store.mu.Unlock()
		n := len(store.channel)
		return n >= 3 && store.channel[n-1]["onlineAt"] == nil && store.channel[n-1]["title"] == nil
	})
	closeClient(t, c)
	return store
}

func TestLiveMetadataLifecycle(t *testing.T) {
	server, counts := metadataServer(t, []string{string(fixture(t, "watch_live.html")), `<html>offline</html>`}, []string{string(fixture(t, "innertube_player.json")), endedPlayer})
	defer server.Close()
	before := time.Now().UTC().Truncate(time.Millisecond)
	store := runUntilOffline(t, server)
	after := time.Now().UTC()
	if players, updates := counts(); players != 2 || updates < 2 {
		t.Fatalf("players=%d updates=%d", players, updates)
	}
	start := time.Date(2026, 10, 1, 17, 0, 26, 0, time.UTC)
	title := "24/7 halloween ambience 🎃 spooky lofi to get chills to"
	first := store.channel[0]
	want := map[string]interface{}{"onlineAt": start, "viewerCount": int64(3921), "title": title, "displayName": "Lofi Girl", "login": "LofiGirl", "categoryName": "Music", "categoryId": "10"}
	if !reflect.DeepEqual(first, want) {
		t.Fatalf("first write %v", first)
	}
	if update := store.channel[1]; !reflect.DeepEqual(update, map[string]interface{}{"onlineAt": start, "viewerCount": int64(3872), "title": title}) {
		t.Fatalf("update %v", update)
	}
	offline := false
	for _, data := range store.channel {
		if data["onlineAt"] == nil {
			offline = true
			if !reflect.DeepEqual(data, map[string]interface{}{"onlineAt": nil, "viewerCount": int64(0)}) {
				t.Fatalf("offline write %v", data)
			}
		} else if offline {
			t.Fatal("metadata written after the stream ended")
		}
	}
	end := time.Date(2026, 10, 14, 22, 0, 0, 0, time.UTC)
	for id, at := range map[string]time.Time{"youtube:1-LpQekNa9g:online": start, "youtube:1-LpQekNa9g:offline": end} {
		message := store.messages[id]
		if message == nil || message["type"] != "stream."+strings.Split(id, ":")[2] || message["timestamp"] != at || message["channelId"] != "youtube:channel" {
			t.Fatalf("%s: %v", id, message)
		}
		if !reflect.DeepEqual(message["event"], map[string]interface{}{"videoId": "1-LpQekNa9g"}) {
			t.Fatalf("%s event %v", id, message["event"])
		}
		// Stream state outlives chat messages so a long stream still reads as live.
		if expiresAt, _ := message["expiresAt"].(time.Time); expiresAt.Before(before.Add(90*24*time.Hour)) || expiresAt.After(after.Add(90*24*time.Hour)) {
			t.Fatalf("%s expiresAt %v, want 90 days after the write", id, message["expiresAt"])
		}
	}
}

func TestChatEndsWhileStillLive(t *testing.T) {
	live := string(fixture(t, "innertube_player.json"))
	server, counts := metadataServer(t, []string{""}, []string{live, live})
	defer server.Close()
	store := &memoryStore{}
	c := testClient(t, server, store)
	c.metadataInterval = 5 * time.Millisecond
	page, key, version, err := initialPage([]byte(htmlFixture(t, `var ytInitialData = `)))
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	if !c.session(ctx, "1-LpQekNa9g", key, version, page, fixture(t, "watch_live.html")) {
		t.Fatal("session reported the stream ended")
	}
	if players, _ := counts(); players != 2 {
		t.Fatalf("players=%d", players)
	}
	store.mu.Lock()
	defer store.mu.Unlock()
	if _, ok := store.messages["youtube:1-LpQekNa9g:offline"]; ok {
		t.Fatal("wrote stream.offline for a live stream")
	}
	for _, data := range store.channel {
		if data["onlineAt"] == nil {
			t.Fatalf("marked a live stream offline: %v", data)
		}
	}
}

func TestOfflineChannelIsNamed(t *testing.T) {
	server, _ := metadataServer(t, []string{string(fixture(t, "channel_offline.html"))}, []string{""})
	defer server.Close()
	store := &memoryStore{}
	c := testClient(t, server, store)
	c.start()
	defer c.Close()
	eventually(t, func() bool { store.mu.Lock(); defer store.mu.Unlock(); return len(store.channel) > 0 })
	closeClient(t, c)
	want := map[string]interface{}{"onlineAt": nil, "viewerCount": int64(0), "displayName": "Google for Developers", "login": "GoogleDevelopers"}
	if !reflect.DeepEqual(store.channel[0], want) || len(store.messages) != 0 {
		t.Fatalf("offline channel %v %v", store.channel, store.messages)
	}
}

func TestUpcomingStreamGoesLive(t *testing.T) {
	// The chat of a scheduled stream opens before it starts.
	upcomingPlayer := `{"videoDetails":{"title":"Soon","author":"Lofi Girl","isUpcoming":true},"microformat":{"playerMicroformatRenderer":{"category":"Music"}}}`
	watch := `<link rel="canonical" href="https://www.youtube.com/watch?v=1-LpQekNa9g"><script>var ytInitialPlayerResponse = ` + upcomingPlayer + `;</script>`
	server, counts := metadataServer(t, []string{watch, `<html>offline</html>`}, []string{upcomingPlayer, string(fixture(t, "innertube_player.json")), endedPlayer})
	defer server.Close()
	store := runUntilOffline(t, server)
	if players, _ := counts(); players != 3 {
		t.Fatalf("players=%d", players)
	}
	if first := store.channel[0]; !reflect.DeepEqual(first, map[string]interface{}{"onlineAt": nil, "viewerCount": int64(0), "title": "Soon", "displayName": "Lofi Girl", "login": "channel", "categoryName": "Music", "categoryId": "10"}) {
		t.Fatalf("upcoming write %v", first)
	}
	start := time.Date(2026, 10, 1, 17, 0, 26, 0, time.UTC)
	if live := store.channel[1]; live["onlineAt"] != start || live["viewerCount"] != int64(3872) || live["login"] != "LofiGirl" {
		t.Fatalf("live write %v", live)
	}
	if online := store.messages["youtube:1-LpQekNa9g:online"]; online == nil || online["timestamp"] != start {
		t.Fatalf("online message %v", online)
	}
}

func TestPageInfoBotCheck(t *testing.T) {
	// The bot-check page has no videoDetails; the title and viewers still render.
	info, err := pageInfo(fixture(t, "discovery_botcheck.html"))
	if err != nil {
		t.Fatal(err)
	}
	if info.Live != nil {
		t.Error("live state should be unknown without videoDetails")
	}
	if info.Title == nil || *info.Title != "24/7 halloween ambience 🎃 spooky lofi to get chills to" {
		t.Errorf("title = %v", info.Title)
	}
	if info.ViewerCount == nil || *info.ViewerCount <= 0 {
		t.Errorf("viewers = %v", info.ViewerCount)
	}
}
