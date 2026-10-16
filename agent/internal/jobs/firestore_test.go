package jobs

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"google.golang.org/api/option"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func emulator(t *testing.T) *firestore.Client {
	t.Helper()
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST for transaction integration tests")
	}
	client, err := firestore.NewClient(context.Background(), fmt.Sprintf("jobs-%d", time.Now().UnixNano()), option.WithoutAuthentication())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { client.Close() })
	return client
}
func TestFirestoreLeaseReplicasTakeover(t *testing.T) {
	db := emulator(t)
	leases := FirestoreLeases{Client: db}
	ctx := context.Background()
	now := time.Now()
	var acquired atomic.Int32
	var wg sync.WaitGroup
	for i := 0; i < 3; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			ok, err := leases.Acquire(ctx, "refresh", fmt.Sprint(i), "slot", now, time.Minute)
			if err != nil {
				t.Error(err)
			}
			if ok {
				acquired.Add(1)
			}
		}(i)
	}
	wg.Wait()
	if acquired.Load() != 1 {
		t.Fatal(acquired.Load())
	}
	ok, err := leases.Acquire(ctx, "refresh", "takeover", "slot", now.Add(time.Minute), time.Minute)
	if err != nil || !ok {
		t.Fatal(ok, err)
	}
	if err := leases.Finish(ctx, "refresh", "stale", "slot", true); err == nil {
		t.Fatal("stale owner finished")
	}
	if err := leases.Finish(ctx, "refresh", "takeover", "slot", false); err != nil {
		t.Fatal(err)
	}
	ok, err = leases.Acquire(ctx, "refresh", "retry", "slot", now.Add(time.Minute), time.Minute)
	if err != nil || !ok {
		t.Fatal(ok, err)
	}
	if err := leases.Finish(ctx, "refresh", "retry", "slot", true); err != nil {
		t.Fatal(err)
	}
	ok, err = leases.Acquire(ctx, "refresh", "duplicate", "slot", now.Add(24*time.Hour), time.Minute)
	if err != nil || ok {
		t.Fatal(ok, err)
	}
}
func TestFirestoreCleanupIdempotencyAndActivity(t *testing.T) {
	db := emulator(t)
	ctx := context.Background()
	old := time.Now().Add(-8 * 24 * time.Hour)
	for _, id := range []string{"twitch:muxfd", "twitch:old", "youtube:old"} {
		if _, err := db.Collection("assignments").Doc(id).Set(ctx, map[string]interface{}{"subscribedAt": old}); err != nil {
			t.Fatal(err)
		}
	}
	db.Collection("assignments").Doc("twitch:active").Set(ctx, map[string]interface{}{"subscribedAt": time.Now()})
	ids := []string{}
	for i := 0; i < 105; i++ {
		ids = append(ids, fmt.Sprint(i))
	}
	db.Collection("webhooks").Doc("kick:old").Set(ctx, map[string]interface{}{"lastActiveAt": old, "subscriptionIds": ids})
	db.Collection("webhooks").Doc("kick:active").Set(ctx, map[string]interface{}{"lastActiveAt": time.Now(), "subscriptionIds": []string{"active"}})
	db.Collection("webhooks").Doc("twitch:old").Set(ctx, map[string]interface{}{"lastActiveAt": old})
	calls := 0
	deleted := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			fmt.Fprint(w, `{"data":[]}`)
			return
		}
		if r.Method != http.MethodDelete {
			t.Error(r.Method)
		}
		calls++
		batch := r.URL.Query()["id"]
		if len(batch) > 50 {
			t.Error("oversized Kick delete")
		}
		deleted += len(batch)
		w.WriteHeader(204)
	}))
	defer server.Close()
	service := Service{Client: db, API: &API{Tokens: testTokens{}, Client: server.Client(), KickURL: server.URL}}
	for i := 0; i < 2; i++ {
		if err := service.Cleanup(ctx); err != nil {
			t.Fatal(err)
		}
	}
	if calls != 3 || deleted != 105 {
		t.Fatal(calls, deleted)
	}
	for _, id := range []string{"twitch:muxfd", "twitch:active"} {
		if _, err := db.Collection("assignments").Doc(id).Get(ctx); err != nil {
			t.Fatal(id, err)
		}
	}
	for _, id := range []string{"twitch:old", "youtube:old"} {
		if _, err := db.Collection("assignments").Doc(id).Get(ctx); status.Code(err) != codes.NotFound {
			t.Fatal(id, err)
		}
	}
	for _, id := range []string{"kick:active", "twitch:old"} {
		if _, err := db.Collection("webhooks").Doc(id).Get(ctx); err != nil {
			t.Fatal(id, err)
		}
	}
}
func TestFirestoreMetadataOrdering(t *testing.T) {
	db := emulator(t)
	ctx := context.Background()
	service := Service{Client: db}
	started := time.Now().Add(-time.Second)
	ref := db.Collection("channels").Doc("kick:1")
	ref.Set(ctx, map[string]interface{}{"viewerCount": int64(100), "title": "new webhook"})
	if err := service.write(ctx, started, []ChannelUpdate{{"kick:1", map[string]interface{}{"viewerCount": int64(1), "title": "stale poll"}}}); err != nil {
		t.Fatal(err)
	}
	doc, err := ref.Get(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if doc.Data()["title"] != "new webhook" {
		t.Fatal(doc.Data())
	}
	if err := service.write(ctx, started, []ChannelUpdate{{"kick:1", map[string]interface{}{"followerCount": int64(42)}}}); err != nil {
		t.Fatal(err)
	}
	doc, _ = ref.Get(ctx)
	if doc.Data()["followerCount"] != int64(42) {
		t.Fatal(doc.Data())
	}
}
func TestFirestoreKickActiveBatching(t *testing.T) {
	db := emulator(t)
	ctx := context.Background()
	now := time.Now()
	writes := db.Batch()
	for i := 0; i < 52; i++ {
		writes.Set(db.Collection("webhooks").Doc(fmt.Sprint("kick:", i)), map[string]interface{}{"lastActiveAt": now})
	}
	writes.Set(db.Collection("webhooks").Doc("kick:idle"), map[string]interface{}{"lastActiveAt": now.Add(-25 * time.Hour)})
	writes.Set(db.Collection("webhooks").Doc("twitch:123"), map[string]interface{}{"lastActiveAt": now})
	if _, err := writes.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	calls, total := 0, 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls++
		ids := r.URL.Query()["broadcaster_user_id"]
		if len(ids) > 50 {
			t.Error("oversized Kick batch")
		}
		total += len(ids)
		fmt.Fprint(w, `{"data":[{"broadcaster_user_id":0,"slug":"zero","stream":{"is_live":false}}]}`)
	}))
	defer server.Close()
	service := Service{Client: db, API: &API{Tokens: testTokens{}, Client: server.Client(), KickURL: server.URL}}
	if err := service.Kick(ctx); err != nil {
		t.Fatal(err)
	}
	if calls != 2 || total != 52 {
		t.Fatal(calls, total)
	}
	doc, err := db.Collection("channels").Doc("kick:0").Get(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if doc.Data()["viewerCount"] != int64(0) || doc.Data()["login"] != "zero" {
		t.Fatal(doc.Data())
	}
}

func TestFirestoreCleanupFailureRetainsState(t *testing.T) {
	db := emulator(t)
	ctx := context.Background()
	ref := db.Collection("webhooks").Doc("kick:old")
	if _, err := ref.Set(ctx, map[string]interface{}{"lastActiveAt": time.Now().Add(-8 * 24 * time.Hour), "subscriptionIds": []string{"failed"}}); err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(400) }))
	defer server.Close()
	service := Service{Client: db, API: &API{Tokens: testTokens{}, Client: server.Client(), KickURL: server.URL}}
	if err := service.Cleanup(ctx); err == nil {
		t.Fatal("provider failure hidden")
	}
	if _, err := ref.Get(ctx); err != nil {
		t.Fatal("lost retry state", err)
	}
}

func TestFirestoreConcurrentSubscribeRetainsAndInvalidatesCheck(t *testing.T) {
	db := emulator(t)
	ctx := context.Background()
	ref := db.Collection("webhooks").Doc("kick:old")
	if _, err := ref.Set(ctx, map[string]interface{}{"lastActiveAt": time.Now().Add(-8 * 24 * time.Hour), "checkedAt": time.Now(), "subscriptionIds": []string{"old"}}); err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			fmt.Fprint(w, `{"data":[]}`)
			return
		}
		if _, err := ref.Set(ctx, map[string]interface{}{"lastActiveAt": time.Now(), "checkedAt": time.Now(), "subscriptionIds": []string{"new"}}); err != nil {
			t.Error(err)
		}
		w.WriteHeader(204)
	}))
	defer server.Close()
	service := Service{Client: db, API: &API{Tokens: testTokens{}, Client: server.Client(), KickURL: server.URL}}
	if err := service.Cleanup(ctx); err != nil {
		t.Fatal(err)
	}
	doc, err := ref.Get(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if !doc.Data()["checkedAt"].(time.Time).Equal(time.Unix(0, 0)) {
		t.Fatal("cached provider state not invalidated", doc.Data())
	}
	if doc.Data()["lastActiveAt"].(time.Time).Before(time.Now().Add(-time.Minute)) {
		t.Fatal("new activity lost", doc.Data())
	}
}

func TestFirestoreCleanupRejectsMalformedSubscriptionIDs(t *testing.T) {
	db := emulator(t)
	ctx := context.Background()
	ref := db.Collection("webhooks").Doc("kick:malformed")
	if _, err := ref.Set(ctx, map[string]interface{}{"lastActiveAt": time.Now().Add(-8 * 24 * time.Hour), "subscriptionIds": []interface{}{"valid", 42}}); err != nil {
		t.Fatal(err)
	}
	doc, err := ref.Get(ctx)
	if err != nil {
		t.Fatal(err)
	}
	// No API is configured: validation must finish before any provider deletion.
	service := Service{Client: db}
	if err := service.removeIdleKick(ctx, doc, time.Now().Add(-7*24*time.Hour)); err == nil {
		t.Fatal("malformed IDs accepted")
	}
	if _, err := ref.Get(ctx); err != nil {
		t.Fatal("malformed subscription record was deleted", err)
	}
}
