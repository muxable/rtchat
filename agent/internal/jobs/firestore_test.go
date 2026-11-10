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
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
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
		go func() {
			defer wg.Done()
			if leases.Acquire(ctx, "refresh", "slot", now, time.Minute) {
				acquired.Add(1)
			}
		}()
	}
	wg.Wait()
	if acquired.Load() != 1 {
		t.Fatal(acquired.Load())
	}
	if !leases.Acquire(ctx, "refresh", "slot", now.Add(time.Minute), time.Minute) {
		t.Fatal("expired lease not taken over")
	}
	leases.Finish(ctx, "refresh", "slot", false)
	if !leases.Acquire(ctx, "refresh", "slot", now.Add(time.Minute), time.Minute) {
		t.Fatal("failed slot not retried")
	}
	leases.Finish(ctx, "refresh", "slot", true)
	if leases.Acquire(ctx, "refresh", "slot", now.Add(24*time.Hour), time.Minute) {
		t.Fatal("completed slot ran again")
	}
	if !leases.Acquire(ctx, "refresh", "next", now.Add(time.Minute), time.Minute) {
		t.Fatal("next slot not taken after completion")
	}
	canceled, cancel := context.WithCancel(ctx)
	cancel()
	if leases.Acquire(canceled, "other", "slot", now, time.Minute) {
		t.Fatal("unconfirmed lease reported as held")
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
	written, err := service.write(ctx, started, []ChannelUpdate{{"kick:1", map[string]interface{}{"viewerCount": int64(1), "title": "stale poll"}}})
	if err != nil {
		t.Fatal(err)
	}
	if written != 0 {
		t.Fatalf("stale poll counted %d writes", written)
	}
	doc, err := ref.Get(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if doc.Data()["title"] != "new webhook" {
		t.Fatal(doc.Data())
	}
	if written, err := service.write(ctx, started, []ChannelUpdate{{"kick:1", map[string]interface{}{"followerCount": int64(42)}}}); err != nil || written != 1 {
		t.Fatal(written, err)
	}
	doc, _ = ref.Get(ctx)
	if doc.Data()["followerCount"] != int64(42) {
		t.Fatal(doc.Data())
	}
}
func TestFirestoreMetadataSkipsUnchanged(t *testing.T) {
	db := emulator(t)
	ctx := context.Background()
	service := Service{Client: db}
	at := time.Now().UTC().Truncate(time.Millisecond)
	data := map[string]interface{}{"viewerCount": int64(5), "login": "live", "onlineAt": at, "title": nil}
	if written, err := service.write(ctx, time.Now(), []ChannelUpdate{{"kick:2", data}}); err != nil || written != 1 {
		t.Fatal(written, err)
	}
	ref := db.Collection("channels").Doc("kick:2")
	before, err := ref.Get(ctx)
	if err != nil {
		t.Fatal(err)
	}
	updates := []ChannelUpdate{{"kick:2", data}, {"kick:2", map[string]interface{}{"viewerCount": int64(5)}}}
	if written, err := service.write(ctx, time.Now(), updates); err != nil || written != 0 {
		t.Fatal("unchanged data written", written, err)
	}
	after, err := ref.Get(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if !after.UpdateTime.Equal(before.UpdateTime) {
		t.Fatal("unchanged data bumped the document")
	}
	if written, err := service.write(ctx, time.Now(), []ChannelUpdate{{"kick:2", map[string]interface{}{"viewerCount": int64(6), "followerCount": int64(1)}}}); err != nil || written != 1 {
		t.Fatal(written, err)
	}
	after, _ = ref.Get(ctx)
	if after.Data()["viewerCount"] != int64(6) || after.Data()["followerCount"] != int64(1) || after.Data()["login"] != "live" {
		t.Fatal(after.Data())
	}
}
func TestFirestoreKickActiveBatching(t *testing.T) {
	db := emulator(t)
	ctx := context.Background()
	now := time.Now()
	writes := db.BulkWriter(ctx)
	var jobs []*firestore.BulkWriterJob
	set := func(id string, data map[string]interface{}) {
		job, err := writes.Set(db.Collection("webhooks").Doc(id), data)
		if err != nil {
			t.Fatal(err)
		}
		jobs = append(jobs, job)
	}
	for i := 0; i < 52; i++ {
		set(fmt.Sprint("kick:", i), map[string]interface{}{"lastActiveAt": now})
	}
	set("kick:idle", map[string]interface{}{"lastActiveAt": now.Add(-25 * time.Hour)})
	set("twitch:123", map[string]interface{}{"lastActiveAt": now})
	writes.End()
	for _, job := range jobs {
		if _, err := job.Results(); err != nil {
			t.Fatal(err)
		}
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

// The refresh job timed out writing channels one transaction at a time: two
// serial round trips per channel. A batch of updates must cost a few.
func TestFirestoreMetadataWritesInFewRoundTrips(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST for transaction integration tests")
	}
	var rpcs atomic.Int32
	count := grpc.WithChainUnaryInterceptor(func(ctx context.Context, method string, req, reply any, cc *grpc.ClientConn, invoker grpc.UnaryInvoker, opts ...grpc.CallOption) error {
		rpcs.Add(1)
		return invoker(ctx, method, req, reply, cc, opts...)
	})
	stream := grpc.WithChainStreamInterceptor(func(ctx context.Context, desc *grpc.StreamDesc, cc *grpc.ClientConn, method string, streamer grpc.Streamer, opts ...grpc.CallOption) (grpc.ClientStream, error) {
		rpcs.Add(1)
		return streamer(ctx, desc, cc, method, opts...)
	})
	ctx := context.Background()
	conn, err := grpc.NewClient(os.Getenv("FIRESTORE_EMULATOR_HOST"), grpc.WithTransportCredentials(insecure.NewCredentials()), grpc.WithPerRPCCredentials(emulatorAdmin{}), count, stream)
	if err != nil {
		t.Fatal(err)
	}
	db, err := firestore.NewClient(ctx, fmt.Sprintf("jobs-%d", time.Now().UnixNano()), option.WithGRPCConn(conn))
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	service := Service{Client: db}
	var updates []ChannelUpdate
	for i := 0; i < 300; i++ {
		if i%2 == 0 { // half the channels already exist
			if _, err := db.Collection("channels").Doc(fmt.Sprint("twitch:", i)).Set(ctx, map[string]interface{}{"viewerCount": int64(0)}); err != nil {
				t.Fatal(err)
			}
		}
		updates = append(updates, ChannelUpdate{fmt.Sprint("twitch:", i), map[string]interface{}{"viewerCount": int64(i + 1), "login": fmt.Sprint("user", i)}})
	}
	rpcs.Store(0)
	written, err := service.write(ctx, time.Now(), updates)
	if err != nil || written != 300 {
		t.Fatal(written, err)
	}
	if n := rpcs.Load(); n > 30 {
		t.Fatalf("%d round trips to write %d channels", n, len(updates))
	}
	doc, err := db.Collection("channels").Doc("twitch:298").Get(ctx)
	if err != nil || doc.Data()["viewerCount"] != int64(299) || doc.Data()["login"] != "user298" {
		t.Fatal(doc.Data(), err)
	}
}

// emulatorAdmin is the credential the Firestore client sends the emulator.
type emulatorAdmin struct{}

func (emulatorAdmin) GetRequestMetadata(context.Context, ...string) (map[string]string, error) {
	return map[string]string{"authorization": "Bearer owner"}, nil
}
func (emulatorAdmin) RequireTransportSecurity() bool { return false }
