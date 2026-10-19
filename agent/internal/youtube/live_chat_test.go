package youtube

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"
)

// go test -v -run TestLive ./internal/youtube (skipped when CI is set or with -short)

func TestLiveDiscovery(t *testing.T) {
	stream := findLiveStream(t)
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	video, err := (&HTTPDiscovery{HTTP: liveHTTPClient()}).LiveChat(ctx, stream.channel)
	if err != nil {
		t.Fatal(err)
	}
	if video != stream.video {
		t.Fatalf("HTTPDiscovery found %q, the reader found %q", video, stream.video)
	}
	token, timeout := stream.page.next()
	if stream.key == "" || stream.version == "" || token == "" || timeout <= 0 {
		t.Fatalf("incomplete live_chat page: key %q version %q token %q timeout %v", stream.key, stream.version, token, timeout)
	}
	t.Logf("initial page: %d actions, next poll in %v", len(stream.page.Actions), timeout)
}

// skippedActions are the InnerTube actions the reader drops on purpose. Any
// other action that actionData drops fails TestLiveChat, so a renamed or new
// renderer is caught.
var skippedActions = map[string]string{
	"addChatItemAction/liveChatViewerEngagementMessageRenderer": "the chat's own welcome and rules notices",
	"addChatItemAction/liveChatPlaceholderItemRenderer":         "a message held for review; it has no content",
	"addChatItemAction/liveChatModeChangeMessageRenderer":       "slow mode or members-only mode notices",
	"addChatItemAction/liveChatBannerRedirectRenderer":          "raid and redirect notices",
	"addLiveChatTickerItemAction":                               "the ticker repeats paid items that also arrive as chat items",
	"addBannerToLiveChatCommand":                                "pinned messages",
	"removeBannerForLiveChatCommand":                            "pinned messages",
	"replaceChatItemAction":                                     "a held message being released",
	"updateLiveChatPollAction":                                  "polls",
	"showLiveChatActionPanelAction":                             "polls",
	"closeLiveChatActionPanelAction":                            "polls",
	"updateOrAddInteractivityWidgetAction":                      "interactive widgets such as quizzes",
	"showLiveChatTooltipCommand":                                "UI hints",
	"liveChatReportModerationStateCommand":                      "moderation UI state",
	"updateDateTextAction":                                      "the watch page's date text",
	"addToPlaceholderAction":                                    "UI placeholders",
	"markChatItemsByAuthorAsDeletedAction":                      "a timeout; the messages are hidden, not removed",
}

// actionKind names an action by its key, and for added chat items, by
// renderer too.
func actionKind(raw json.RawMessage) string {
	var action map[string]json.RawMessage
	if json.Unmarshal(raw, &action) != nil {
		return "<malformed>"
	}
	var keys []string
	for key := range action {
		if key != "clickTrackingParams" {
			keys = append(keys, key)
		}
	}
	sort.Strings(keys)
	kind := strings.Join(keys, "+")
	if kind != "addChatItemAction" {
		return kind
	}
	var add struct {
		Item map[string]json.RawMessage `json:"item"`
	}
	if json.Unmarshal(action[kind], &add) != nil {
		return kind + "/<malformed>"
	}
	var renderers []string
	for name := range add.Item {
		renderers = append(renderers, name)
	}
	sort.Strings(renderers)
	return kind + "/" + strings.Join(renderers, "+")
}

// recorder keeps the live_chat page and every get_live_chat response the
// reader received, so the test sees exactly the actions the reader saw.
type recorder struct {
	mu        sync.Mutex
	pages     [][]byte
	responses [][]byte
}

func (r *recorder) RoundTrip(req *http.Request) (*http.Response, error) {
	resp, err := http.DefaultTransport.RoundTrip(req)
	if err != nil || resp.StatusCode != http.StatusOK {
		return resp, err
	}
	body, err := io.ReadAll(resp.Body)
	resp.Body.Close()
	if err != nil {
		return nil, err
	}
	resp.Body = io.NopCloser(bytes.NewReader(body))
	r.mu.Lock()
	defer r.mu.Unlock()
	switch req.URL.Path {
	case "/live_chat":
		r.pages = append(r.pages, body)
	case "/youtubei/v1/live_chat/get_live_chat":
		r.responses = append(r.responses, body)
	}
	return resp, nil
}

func (r *recorder) actions(t *testing.T) []json.RawMessage {
	r.mu.Lock()
	defer r.mu.Unlock()
	var actions []json.RawMessage
	for _, page := range r.pages {
		initial, _, _, err := initialPage(page)
		if err != nil {
			t.Errorf("live_chat page: %v", err)
		}
		actions = append(actions, initial.Actions...)
	}
	for _, body := range r.responses {
		var result struct {
			Contents *struct {
				Chat chatPage `json:"liveChatContinuation"`
			} `json:"continuationContents"`
		}
		if err := json.Unmarshal(body, &result); err != nil || result.Contents == nil {
			t.Errorf("get_live_chat response without liveChatContinuation: %v %.200s", err, body)
			continue
		}
		actions = append(actions, result.Contents.Chat.Actions...)
	}
	return actions
}

// TestLiveChat runs the reader against a live stream for 75 seconds and checks
// that every action it received was written as a sane event or is a known
// skip. Set LIVE_CAPTURE_DIR to save the non-text actions, e.g. to refresh
// testdata/actions with real captures.
func TestLiveChat(t *testing.T) {
	stream := findLiveStream(t)
	rec := &recorder{}
	store := &memoryStore{}
	c, err := newClient(stream.channel, &http.Client{Timeout: 30 * time.Second, Transport: rec}, store)
	if err != nil {
		t.Fatal(err)
	}
	started := time.Now()
	c.start()
	time.Sleep(75 * time.Second)
	c.Close()

	store.mu.Lock()
	defer store.mu.Unlock()
	if len(store.online) == 0 || store.online[0] == nil {
		t.Fatalf("channel not marked online: %v", store.online)
	}
	if n := c.counts.parseFailures.Load(); n > 0 {
		t.Errorf("%d parse failures", n)
	}
	rec.mu.Lock()
	polls := len(rec.responses)
	rec.mu.Unlock()
	if polls < 2 {
		t.Errorf("only %d get_live_chat responses in 75s", polls)
	}

	actions := rec.actions(t)
	kinds := map[string]int{}
	written := map[string]int{}
	captured := map[string]int{}
	for _, raw := range actions {
		kind := actionKind(raw)
		kinds[kind]++
		if dir := os.Getenv("LIVE_CAPTURE_DIR"); dir != "" && kind != "addChatItemAction/liveChatTextMessageRenderer" {
			captured[kind]++
			name := strings.NewReplacer("/", "_", "+", "_").Replace(kind)
			if err := os.WriteFile(filepath.Join(dir, fmt.Sprintf("%s_%d.json", name, captured[kind])), raw, 0o644); err != nil {
				t.Error(err)
			}
		}
		data := actionData(stream.channel, stream.video, raw, time.Now())
		if data == nil {
			if _, ok := skippedActions[kind]; !ok {
				t.Errorf("unknown or unparsed action %s: %.300s", kind, raw)
			}
			continue
		}
		written[data["type"].(string)]++
		checkEvent(t, kind, data, started)
	}
	t.Logf("%s: %d polls, %d actions, %d messages stored, %d skipped", stream.name, polls, len(actions), len(store.messages), c.counts.skipped.Load())
	for _, kind := range sortedKeys(kinds) {
		t.Logf("  %5d %s", kinds[kind], kind)
	}
	for _, kind := range sortedKeys(written) {
		t.Logf("  %5d written as %s", written[kind], kind)
	}
	if len(store.messages) == 0 {
		t.Fatal("no messages written")
	}
	// The reader writes what the test parsed; deduplicated ids can only lower it.
	total := 0
	for _, n := range written {
		total += n
	}
	// stream.online/offline come from the metadata reader, not chat actions.
	chat := 0
	for _, data := range store.messages {
		if kind, _ := data["type"].(string); !strings.HasPrefix(kind, "stream.") {
			chat++
		}
	}
	if chat > total {
		t.Errorf("stored %d chat messages from %d parsed actions", chat, total)
	}
}

// checkEvent catches renamed fields that leave actionData returning an event
// with empty values.
func checkEvent(t *testing.T, kind string, data map[string]interface{}, started time.Time) {
	t.Helper()
	event := data["event"].(map[string]interface{})
	snippet := event["snippet"].(map[string]interface{})
	author := event["authorDetails"].(map[string]interface{})
	if event["id"] == "" {
		t.Errorf("%s: empty id", kind)
	}
	if !strings.HasPrefix(kind, "addChatItemAction/") {
		return
	}
	ts := data["timestamp"].(time.Time)
	if ts.Before(started.Add(-24*time.Hour)) || ts.After(time.Now().Add(5*time.Minute)) {
		t.Errorf("%s: implausible timestamp %v", kind, ts)
	}
	if id, _ := author["channelId"].(string); kind == "addChatItemAction/giftMessageViewModel" {
		// The captured gift model identifies the author only by display name.
		if id != "" {
			t.Errorf("%s: fabricated author channel id %q", kind, id)
		}
	} else if !strings.HasPrefix(id, "UC") {
		t.Errorf("%s: author channel id %q", kind, id)
	}
	if author["displayName"] == "" {
		t.Errorf("%s: empty author name", kind)
	}
	if url, _ := author["profileImageUrl"].(string); !strings.HasPrefix(url, "https://") {
		t.Errorf("%s: author photo %q", kind, url)
	}
	if kind == "addChatItemAction/liveChatTextMessageRenderer" && snippet["displayMessage"] == "" {
		t.Errorf("%s: empty message", kind)
	}
}

func sortedKeys(m map[string]int) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}
