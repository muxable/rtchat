package subscriptions

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/muxable/rtchat/agent/internal/jobs"
)

type kickFixture struct {
	mu      sync.Mutex
	state   map[string][]kickSubscription
	posts   int
	partial bool
	fail    bool
}

func (f *kickFixture) handler(w http.ResponseWriter, r *http.Request) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if r.Method == http.MethodGet {
		data := f.state[r.URL.Query().Get("broadcaster_user_id")]
		if data == nil {
			data = []kickSubscription{}
		}
		json.NewEncoder(w).Encode(map[string]interface{}{"data": data})
		return
	}
	if r.Method != http.MethodPost {
		w.WriteHeader(400)
		return
	}
	f.posts++
	var body struct {
		ID     uint64      `json:"broadcaster_user_id"`
		Events []KickEvent `json:"events"`
		Method string      `json:"method"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		panic(err)
	}
	if body.Method != "webhook" {
		w.WriteHeader(400)
		return
	}
	if f.fail {
		w.WriteHeader(500)
		return
	}
	id := fmt.Sprint(body.ID)
	events := body.Events
	if f.partial && f.posts == 1 {
		events = events[:len(events)-1]
	}
	for _, event := range events {
		f.state[id] = append(f.state[id], kickSubscription{ID: fmt.Sprintf("%s-%s", id, event.Name), Event: event.Name, Version: event.Version})
	}
	fmt.Fprint(w, `{"data":[]}`)
}
func TestKickReconciliationConcurrencyAndPartialFailure(t *testing.T) {
	for _, partial := range []bool{false, true} {
		t.Run(fmt.Sprint(partial), func(t *testing.T) {
			db := database(t)
			fixture := &kickFixture{state: map[string][]kickSubscription{}, partial: partial}
			server := httptest.NewServer(http.HandlerFunc(fixture.handler))
			defer server.Close()
			service := &Service{DB: db, API: &API{Tokens: fakeTokens{}, Client: server.Client(), KickURL: server.URL}}
			if partial {
				response := call(service, "subscribe", "", `{"provider":"kick","channelId":123}`)
				if response.Code != 503 {
					t.Fatal(response.Code, response.Body.String())
				}
				doc, err := db.Collection("webhooks").Doc("kick:123").Get(context.Background())
				if err != nil || activeCheck(doc.Data(), time.Now()) {
					t.Fatal("partial creation cached", err)
				}
			}
			var wg sync.WaitGroup
			for i := 0; i < 3; i++ {
				wg.Add(1)
				go func() {
					defer wg.Done()
					response := call(service, "subscribe", "", `{"provider":"kick","channelId":"123"}`)
					if response.Code != 200 {
						t.Error(response.Code, response.Body.String())
					}
				}()
			}
			wg.Wait()
			expected := 1
			if partial {
				expected = 2
			}
			if fixture.posts != expected || len(fixture.state["123"]) != len(KickEvents) {
				t.Fatal(fixture.posts, len(fixture.state["123"]))
			}
			doc, err := db.Collection("webhooks").Doc("kick:123").Get(context.Background())
			if err != nil || !activeCheck(doc.Data(), time.Now()) {
				t.Fatal("complete creation not cached", err)
			}
			if _, err := db.Collection("profiles").Doc("owner").Set(context.Background(), map[string]interface{}{"kick": map[string]interface{}{"id": "123"}}); err != nil {
				t.Fatal(err)
			}
			response := call(service, "subscribe", "owner", `{"provider":"kick","channelId":"123"}`)
			if response.Code != 200 {
				t.Fatal(response.Body.String())
			}
			channel, err := db.Collection("channels").Doc("kick:123").Get(context.Background())
			if err != nil || channel.Data()["lastActiveAt"] == nil {
				t.Fatal(err)
			}
		})
	}
}
func TestKickCapacityAndAmbiguousFailureReservation(t *testing.T) {
	db := database(t)
	ctx := context.Background()
	fixture := &kickFixture{state: map[string][]kickSubscription{}}
	server := httptest.NewServer(http.HandlerFunc(fixture.handler))
	defer server.Close()
	service := &Service{DB: db, KickChannelLimit: 1, API: &API{Tokens: fakeTokens{}, Client: server.Client(), KickURL: server.URL}}
	if _, err := db.Collection("webhooks").Doc("kick:456").Set(ctx, map[string]interface{}{"lastActiveAt": time.Now()}); err != nil {
		t.Fatal(err)
	}
	response := call(service, "subscribe", "", `{"provider":"kick","channelId":"123"}`)
	if response.Code != 429 || fixture.posts != 0 {
		t.Fatal(response.Code, fixture.posts, response.Body.String())
	}
	db.Collection("webhooks").Doc("kick:456").Delete(ctx)
	fixture.fail = true
	response = call(service, "subscribe", "", `{"provider":"kick","channelId":"123"}`)
	if response.Code < 400 {
		t.Fatal(response.Code)
	}
	if fixture.posts != 1 {
		t.Fatal("ambiguous POST automatically repeated", fixture.posts)
	}
	doc, err := db.Collection("webhooks").Doc("kick:123").Get(ctx)
	if err != nil || activeCheck(doc.Data(), time.Now()) {
		t.Fatal("ambiguous reservation lost or cached", err)
	}
}
func TestKickSubscribeAndCleanupShareLifecycleLease(t *testing.T) {
	db := database(t)
	ctx := context.Background()
	old := time.Now().Add(-8 * 24 * time.Hour)
	ids := []string{}
	state := []kickSubscription{}
	for _, event := range KickEvents {
		id := event.Name
		ids = append(ids, id)
		state = append(state, kickSubscription{ID: id, Event: event.Name, Version: 1})
	}
	if _, err := db.Collection("webhooks").Doc("kick:123").Set(ctx, map[string]interface{}{"lastActiveAt": old, "checkedAt": old, "subscriptionIds": ids}); err != nil {
		t.Fatal(err)
	}
	deleting := make(chan struct{})
	release := make(chan struct{})
	posts := 0
	var mu sync.Mutex
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodDelete {
			close(deleting)
			<-release
			mu.Lock()
			state = []kickSubscription{}
			mu.Unlock()
			w.WriteHeader(204)
			return
		}
		mu.Lock()
		defer mu.Unlock()
		if r.Method == http.MethodPost {
			posts++
			state = []kickSubscription{}
			for _, event := range KickEvents {
				state = append(state, kickSubscription{ID: "new-" + event.Name, Event: event.Name, Version: 1})
			}
			fmt.Fprint(w, `{"data":[]}`)
			return
		}
		json.NewEncoder(w).Encode(map[string]interface{}{"data": state})
	}))
	defer server.Close()
	api := &API{Tokens: fakeTokens{}, Client: server.Client(), KickURL: server.URL}
	service := &Service{DB: db, API: api}
	cleanup := &jobs.Service{Client: db, API: &jobs.API{Tokens: fakeTokens{}, Client: server.Client(), KickURL: server.URL}}
	cleanupDone := make(chan error, 1)
	go func() { cleanupDone <- cleanup.Cleanup(ctx) }()
	<-deleting
	subscribeDone := make(chan *httptest.ResponseRecorder, 1)
	go func() { subscribeDone <- call(service, "subscribe", "", `{"provider":"kick","channelId":"123"}`) }()
	select {
	case response := <-subscribeDone:
		t.Fatal("subscribe bypassed cleanup lease", response.Code)
	case <-time.After(100 * time.Millisecond):
	}
	close(release)
	if err := <-cleanupDone; err != nil {
		t.Fatal(err)
	}
	response := <-subscribeDone
	if response.Code != 200 {
		t.Fatal(response.Code, response.Body.String())
	}
	doc, err := db.Collection("webhooks").Doc("kick:123").Get(ctx)
	if err != nil || !activeCheck(doc.Data(), time.Now()) || posts != 1 {
		t.Fatal("active subscription lost after cleanup", posts, err)
	}
}
