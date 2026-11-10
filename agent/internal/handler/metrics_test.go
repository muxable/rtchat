package handler

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/chatmetrics"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"
)

func flushedCounts(t *testing.T) map[string]int64 {
	t.Helper()
	core, logs := observer.New(zap.InfoLevel)
	chatmetrics.Default.Flush(zap.New(core))
	counts := map[string]int64{}
	for _, e := range logs.All() {
		f := e.ContextMap()
		counts[fmt.Sprintf("%s/%s/%s", f["provider"], f["kind"], f["outcome"])] = f["count"].(int64)
	}
	return counts
}

func TestWriteDocumentCountsOutcomes(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("requires Firestore emulator")
	}
	ctx := context.Background()
	client, err := firestore.NewClient(ctx, "demo-chat-metrics")
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	defer func(saved *chatmetrics.Counters) { chatmetrics.Default = saved }(chatmetrics.Default)
	chatmetrics.Default = &chatmetrics.Counters{}

	h := &TwitchAgent{Firestore: client}
	id := fmt.Sprintf("twitch:metrics-%d", time.Now().UnixNano())
	doc := &chatDocument{"twitch:1", id, map[string]interface{}{"type": "message"}}
	defer client.Collection("channels").Doc("twitch:1").Collection("messages").Doc(id).Delete(ctx)
	h.writeDocument("message", doc)
	h.writeDocument("message", doc) // another instance already wrote it
	h.writeDocument("usernotice", nil)

	got := flushedCounts(t)
	want := map[string]int64{"twitch/message/created": 1, "twitch/message/duplicate": 1, "twitch/usernotice/skipped": 1}
	if len(got) != len(want) {
		t.Fatalf("counts = %v, want %v", got, want)
	}
	for k, v := range want {
		if got[k] != v {
			t.Fatalf("counts = %v, want %v", got, want)
		}
	}
}
