//go:build live

package youtube

import (
	"context"
	"fmt"
	"testing"
	"time"
)

// go test -tags live -v -run TestLiveMetadata ./internal/youtube

func checkLiveInfo(t *testing.T, source string, info streamInfo) {
	t.Helper()
	if info.Live == nil || !*info.Live {
		t.Errorf("%s: not live", source)
	}
	if info.Title == nil || *info.Title == "" {
		t.Errorf("%s: no title", source)
	}
	if info.ViewerCount != nil && *info.ViewerCount <= 0 {
		t.Errorf("%s: viewer count %d", source, *info.ViewerCount)
	}
}

// TestLiveMetadata checks that each metadata source decodes into sane values
// for a live stream.
func TestLiveMetadata(t *testing.T) {
	stream := findLiveStream(t)
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	c, err := newClient(stream.channel, liveHTTPClient(), &memoryStore{})
	if err != nil {
		t.Fatal(err)
	}

	page, err := pageInfo(stream.watch)
	if err != nil {
		t.Fatalf("/live page: %v", err)
	}
	t.Logf("/live page: %s", infoString(page))
	checkLiveInfo(t, "/live page", page)
	if page.ViewerCount == nil {
		t.Error("/live page: no viewer count")
	}

	player, err := c.player(ctx, stream.key, stream.version, stream.video)
	if err != nil {
		t.Fatalf("player: %v", err)
	}
	t.Logf("player: %s", infoString(player))
	checkLiveInfo(t, "player", player)
	if player.DisplayName == nil || *player.DisplayName == "" {
		t.Error("player: no channel name")
	}
	if player.Category == nil {
		t.Error("player: no category")
	} else if _, ok := categoryIDs[*player.Category]; !ok {
		t.Errorf("player: category %q has no id", *player.Category)
	}
	if player.Login == nil || *player.Login == "" {
		t.Error("player: no handle")
	}
	if player.StartedAt == nil || !player.StartedAt.Before(time.Now()) || player.StartedAt.Year() < 2005 {
		t.Errorf("player: start time %v", player.StartedAt)
	}
	if player.EndedAt != nil {
		t.Errorf("player: live stream ended at %v", player.EndedAt)
	}

	update, err := c.updatedMetadata(ctx, stream.key, stream.version, stream.video)
	if err != nil {
		t.Fatalf("updated_metadata: %v", err)
	}
	t.Logf("updated_metadata: %s", infoString(update))
	checkLiveInfo(t, "updated_metadata", update)
	if update.ViewerCount == nil {
		t.Error("updated_metadata: no viewer count")
	}
	if n := c.counts.parseFailures.Load(); n > 0 {
		t.Errorf("%d parse failures", n)
	}
}

// TestLiveMetadataSession runs the reader against a live stream and checks
// what it writes to channels/youtube:{id} and the stream.online message.
func TestLiveMetadataSession(t *testing.T) {
	stream := findLiveStream(t)
	store := &memoryStore{}
	c, err := newClient(stream.channel, liveHTTPClient(), store)
	if err != nil {
		t.Fatal(err)
	}
	c.metadataInterval = 15 * time.Second
	started := time.Now()
	c.start()
	time.Sleep(40 * time.Second)
	c.Close()

	store.mu.Lock()
	defer store.mu.Unlock()
	for _, data := range store.channel {
		t.Logf("channel write: %v", data)
	}
	if len(store.channel) < 2 {
		t.Fatalf("%d channel writes, want the initial one and an update", len(store.channel))
	}
	first := store.channel[0]
	onlineAt, ok := first["onlineAt"].(time.Time)
	if !ok || !onlineAt.Before(started) {
		t.Errorf("onlineAt %v, want the stream's start", first["onlineAt"])
	}
	for _, field := range []string{"title", "displayName", "login", "categoryName", "categoryId"} {
		if s, _ := first[field].(string); s == "" {
			t.Errorf("first write has no %s: %v", field, first)
		}
	}
	if first["login"] == stream.channel {
		t.Errorf("login fell back to the channel id")
	}
	for i, data := range store.channel {
		if data["onlineAt"] == nil {
			t.Errorf("write %d marked the stream offline: %v", i, data)
		}
		if n, ok := data["viewerCount"].(int64); !ok || n <= 0 {
			t.Errorf("write %d viewer count %v", i, data["viewerCount"])
		}
	}
	online := store.messages["youtube:"+stream.video+":online"]
	if online == nil || online["type"] != "stream.online" || online["timestamp"] != onlineAt {
		t.Errorf("stream.online %v, want timestamp %v", online, onlineAt)
	}
	if _, ok := store.messages["youtube:"+stream.video+":offline"]; ok {
		t.Error("wrote stream.offline for a live stream")
	}
	if n := c.counts.parseFailures.Load(); n > 0 {
		t.Errorf("%d parse failures", n)
	}
}

func infoString(info streamInfo) string {
	var title, name, login, category, live, viewers, start, end interface{}
	for _, f := range []struct {
		dst *interface{}
		src *string
	}{{&title, info.Title}, {&name, info.DisplayName}, {&login, info.Login}, {&category, info.Category}} {
		if f.src != nil {
			*f.dst = *f.src
		}
	}
	if info.Live != nil {
		live = *info.Live
	}
	if info.ViewerCount != nil {
		viewers = *info.ViewerCount
	}
	if info.StartedAt != nil {
		start = info.StartedAt.Format(time.RFC3339)
	}
	if info.EndedAt != nil {
		end = info.EndedAt.Format(time.RFC3339)
	}
	return fmt.Sprintf("live=%v viewers=%v title=%v displayName=%v login=%v category=%v start=%v end=%v", live, viewers, title, name, login, category, start, end)
}
