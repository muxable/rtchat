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
	t.Logf("writes=%d types=%v online=%d counters=%+v", store.writes, types, len(store.online), c.counts)
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
}
