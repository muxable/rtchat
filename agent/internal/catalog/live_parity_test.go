package catalog

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"reflect"
	"testing"
	"time"

	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/provider"
)

// Read-only opt-in validation: never starts the agent or writes provider tokens,
// profiles, assignments or the YouTube lookup cache. Uses app tokens only.
func TestLiveCloudFunctionParity(t *testing.T) {
	if os.Getenv("RTCHAT_LIVE_CATALOG_PARITY") != "1" {
		t.Skip("opt-in read-only production comparison")
	}
	s := &Server{Tokens: provider.NewService(nil, &http.Client{Timeout: 15 * time.Second}), Store: &fakeStore{}, TwitchClientID: "edfnh2q85za8phifif9jxt3ey6t9b9", HTTP: &http.Client{Timeout: 15 * time.Second}}
	api := callable.NewServer(nil)
	s.Register(api)
	local := httptest.NewServer(api)
	defer local.Close()
	for _, tc := range []struct{ name, body string }{{"getBadges", `{"provider":"twitch"}`}, {"getBadges", `{"provider":"twitch","channelId":"158394109"}`}, {"search", `{"provider":"twitch","query":"muxfd"}`}, {"search", `"muxfd"`},
		{"search", `{"provider":"kick","query":"xqc"}`}, {"getStatistics", `{"provider":"twitch","channelId":"158394109"}`}, {"getEmotes", `{"provider":"twitch","channelId":"158394109"}`}, {"getViewerList", `"twitch:158394109"`}} {
		t.Run(tc.name+tc.body, func(t *testing.T) {
			type result struct {
				status int
				data   map[string]any
				err    error
			}
			requests := func(base string) result {
				ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
				defer cancel()
				req, _ := http.NewRequestWithContext(ctx, "POST", base+"/"+tc.name, bytes.NewBufferString(`{"data":`+tc.body+`}`))
				req.Header.Set("Content-Type", "application/json")
				resp, err := http.DefaultClient.Do(req)
				if err != nil {
					return result{err: err}
				}
				defer resp.Body.Close()
				raw, err := io.ReadAll(io.LimitReader(resp.Body, 8<<20))
				var data map[string]any
				if err == nil {
					err = json.Unmarshal(raw, &data)
				}
				return result{resp.StatusCode, data, err}
			}
			ch := make(chan result, 1)
			go func() { ch <- requests("https://us-central1-rtchat-47692.cloudfunctions.net") }()
			goResult := requests(local.URL)
			cloudResult := <-ch
			if goResult.err != nil || cloudResult.err != nil {
				t.Fatalf("request errors Go=%v CF=%v", goResult.err, cloudResult.err)
			}
			goData := goResult.data["result"]
			cfData := cloudResult.data["result"]
			same := goResult.status == cloudResult.status && reflect.DeepEqual(goData, cfData) && reflect.DeepEqual(goResult.data["error"], cloudResult.data["error"])
			if tc.name == "getViewerList" {
				same = goResult.status == cloudResult.status && object(goResult.data["error"])["status"] == object(cloudResult.data["error"])["status"]
			}
			summary := func(v any) any {
				if items, ok := v.([]any); ok {
					return map[string]any{"count": len(items)}
				}
				return v
			}
			t.Logf("Go status=%d result=%v error=%v; CF status=%d result=%v error=%v; comparison passed=%v", goResult.status, summary(goData), goResult.data["error"], cloudResult.status, summary(cfData), cloudResult.data["error"], same)
			if !same {
				if tc.name == "getEmotes" {
					for label, raw := range map[string]any{"Go": goData, "CF": cfData} {
						counts := map[string]int{}
						for _, emote := range array(raw) {
							counts[text(emote["provider"])]++
						}
						t.Logf("%s emote source counts: %v", label, counts)
					}
				}
				t.Errorf("Go/Cloud Function output mismatch")
			}
		})
	}
}
