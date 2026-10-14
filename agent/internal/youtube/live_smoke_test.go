//go:build live

package youtube

import (
	"encoding/json"
	"net/http"
	"testing"
	"time"
)

// go test -tags live -run TestLiveSmoke ./internal/youtube
func TestLiveSmoke(t *testing.T) {
	store := &memoryStore{messages: map[string]map[string]interface{}{}}
	c, err := newClient("UCSJ4gkVC6NrvII8umztf0Ow", &http.Client{Timeout: 30 * time.Second}, store)
	if err != nil {
		t.Fatal(err)
	}
	c.metadataInterval = 20 * time.Second
	c.start()
	time.Sleep(75 * time.Second)
	c.Close()
	store.mu.Lock()
	defer store.mu.Unlock()
	types := map[string]int{}
	var sample map[string]interface{}
	for _, m := range store.messages {
		types[m["type"].(string)]++
		if sample == nil && m["type"] == "youtube.textMessageEvent" {
			sample = m
		}
	}
	t.Logf("writes=%d types=%v requests=%d 429s=%d parseFailures=%d skipped=%d", store.writes, types, c.counts.requests.Load(), c.counts.rateLimits.Load(), c.counts.parseFailures.Load(), c.counts.skipped.Load())
	for _, data := range store.channel {
		t.Logf("channel write: %v", data)
	}
	if sample != nil {
		ev, _ := json.Marshal(sample["event"])
		// show the shape without the user's text.
		var shape map[string]interface{}
		json.Unmarshal(ev, &shape)
		sn := shape["snippet"].(map[string]interface{})
		sn["displayMessage"], sn["textMessageDetails"] = "<redacted>", "<redacted>"
		ad := shape["authorDetails"].(map[string]interface{})
		ad["displayName"] = "<redacted>"
		out, _ := json.MarshalIndent(shape, "", " ")
		t.Logf("sample event shape: %s", out)
	}
	if store.writes == 0 {
		t.Fatal("no messages written")
	}
	if len(store.channel) < 2 || store.channel[0]["onlineAt"] == nil || store.channel[1]["viewerCount"] == nil {
		t.Fatal("live metadata not written")
	}
	if types["stream.online"] != 1 {
		t.Fatal("stream.online not written")
	}
}
