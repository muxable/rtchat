package jobs

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
)

func TestPollIntervalDividesSlot(t *testing.T) {
	if pollInterval > 4*time.Minute || (4*time.Minute)%pollInterval != 0 {
		t.Fatal(pollInterval)
	}
}

func TestChannelCacheLifetime(t *testing.T) {
	var c channelCache
	now := time.Now()
	slot := func(n int) string { return Slot(now.Add(time.Duration(n)*slotLength), false) }
	data := map[string]interface{}{"viewerCount": int64(1)}
	c.begin(slot(0))
	c.store("a", data, now)
	c.end(slot(0), true)
	c.begin(slot(1))
	if !c.fresh("a", data, now) {
		t.Fatal("consecutive slot lost the cache")
	}
	if c.fresh("a", map[string]interface{}{"viewerCount": int64(2)}, now) {
		t.Fatal("changed value treated as cached")
	}
	if c.fresh("a", data, now.Add(cacheTTL+time.Second)) {
		t.Fatal("expired entry treated as cached")
	}
	c.end(slot(1), false)
	c.begin(slot(2))
	if c.fresh("a", data, now) {
		t.Fatal("cache kept after a failed run")
	}
	c.store("a", data, now)
	c.end(slot(2), true)
	c.begin(slot(4))
	if c.fresh("a", data, now) {
		t.Fatal("cache kept across a skipped slot")
	}
	c.store("a", data, now)
	c.end(slot(4), true)
	// Outside a runner there is no slot, so nothing carries over.
	c.begin("")
	if c.fresh("a", data, now) {
		t.Fatal("cache kept without a slot")
	}
	c.store("a", data, now.Add(-cacheTTL-time.Minute))
	c.end(slot(5), true)
	if len(c.channels) != 0 {
		t.Fatal("expired entries not pruned", c.channels)
	}
}

// Replica A runs slot S late, B runs S+1, and A runs S+2 less than six
// minutes after its previous run. A must not trust what it cached in S.
func TestChannelCacheReplicaHandoff(t *testing.T) {
	base := time.Date(2026, 10, 25, 12, 0, 0, 0, time.UTC)
	s0, s1, s2 := Slot(base, false), Slot(base.Add(slotLength), false), Slot(base.Add(2*slotLength), false)
	if previousSlot(s1) != s0 || previousSlot(s2) != s1 || previousSlot("2026-10-25") != "" {
		t.Fatal(previousSlot(s1), previousSlot(s2))
	}
	var a, b channelCache
	offline := map[string]interface{}{"viewerCount": int64(0), "onlineAt": nil}
	a.begin(s0)
	a.store("twitch:1", offline, time.Now())
	a.end(s0, true)
	b.begin(s1)
	b.store("twitch:1", map[string]interface{}{"viewerCount": int64(50), "onlineAt": base}, time.Now())
	b.end(s1, true)
	a.begin(s2)
	if a.fresh("twitch:1", offline, time.Now()) {
		t.Fatal("replica A reused its cache after B ran the previous slot")
	}
}

func TestRunnerReportsFinalResult(t *testing.T) {
	store := &memoryLeases{leases: map[string]Lease{}}
	runner := Runner{Leases: store}
	now := time.Now()
	type result struct {
		slot    string
		success bool
	}
	var got []result
	finished := func(slot string, success bool) { got = append(got, result{slot, success}) }
	var seen string
	ok := Job{Name: "ok", Timeout: time.Minute, Finished: finished, Run: func(ctx context.Context) error { seen = RunSlot(ctx); return nil }}
	runner.Once(context.Background(), ok, now)
	// Run ignores its deadline and returns nil; the runner still records a failure.
	late := Job{Name: "late", Timeout: time.Millisecond, Finished: finished, Run: func(ctx context.Context) error { <-ctx.Done(); return nil }}
	runner.Once(context.Background(), late, now)
	slot := Slot(now, false)
	if seen != slot || len(got) != 2 || got[0] != (result{slot, true}) || got[1] != (result{slot, false}) {
		t.Fatal(seen, got)
	}
	if store.leases["late"].CompletedSlot != "" {
		t.Fatal("timed-out run completed its slot")
	}
}

func TestFirestoreMetadataCacheSkipsTransaction(t *testing.T) {
	db := emulator(t)
	ctx := context.Background()
	service := Service{Client: db}
	var cache channelCache
	ref := db.Collection("channels").Doc("kick:3")
	if _, err := ref.Set(ctx, map[string]interface{}{"lastActiveAt": time.Now()}); err != nil {
		t.Fatal(err)
	}
	data := map[string]interface{}{"viewerCount": int64(5), "title": nil}
	if written, err := service.write(ctx, &cache, time.Now(), []ChannelUpdate{{"kick:3", data}}); err != nil || written != 1 {
		t.Fatal(written, err)
	}
	// A cache hit opens no transaction, so a direct change goes unseen.
	if _, err := ref.Set(ctx, map[string]interface{}{"viewerCount": int64(99)}, firestore.MergeAll); err != nil {
		t.Fatal(err)
	}
	if written, err := service.write(ctx, &cache, time.Now(), []ChannelUpdate{{"kick:3", data}}); err != nil || written != 0 {
		t.Fatal(written, err)
	}
	if doc, _ := ref.Get(ctx); doc.Data()["viewerCount"] != int64(99) {
		t.Fatal("cache hit wrote", doc.Data())
	}
	// Once the entry expires the transaction runs and corrects the doc.
	entry := cache.channels["kick:3"]
	entry.checked = entry.checked.Add(-cacheTTL - time.Second)
	cache.channels["kick:3"] = entry
	if written, err := service.write(ctx, &cache, time.Now(), []ChannelUpdate{{"kick:3", data}}); err != nil || written != 1 {
		t.Fatal(written, err)
	}
	doc, _ := ref.Get(ctx)
	if doc.Data()["viewerCount"] != int64(5) {
		t.Fatal(doc.Data())
	}
	// The cache holds the whole doc, so a field the doc already has is a hit.
	if _, ok := doc.Data()["lastActiveAt"]; !ok || !cache.fresh("kick:3", map[string]interface{}{"lastActiveAt": doc.Data()["lastActiveAt"]}, time.Now()) {
		t.Fatal("cache missing doc fields", cache.channels["kick:3"])
	}
	// A newer webhook drops the entry so the next poll checks again.
	started := time.Now()
	time.Sleep(10 * time.Millisecond)
	if _, err := ref.Set(ctx, map[string]interface{}{"viewerCount": int64(7)}, firestore.MergeAll); err != nil {
		t.Fatal(err)
	}
	if written, err := service.write(ctx, &cache, started, []ChannelUpdate{{"kick:3", map[string]interface{}{"viewerCount": int64(8), "title": nil}}}); err != nil || written != 0 {
		t.Fatal(written, err)
	}
	if _, ok := cache.channels["kick:3"]; ok {
		t.Fatal("entry kept after a newer webhook")
	}
}

func TestFirestoreAssignmentsSnapshot(t *testing.T) {
	db := emulator(t)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	if _, err := db.Collection("assignments").Doc("twitch:listed").Set(ctx, map[string]interface{}{}); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Collection("assignments").Doc("kick:other").Set(ctx, map[string]interface{}{}); err != nil {
		t.Fatal(err)
	}
	var assignments Assignments
	if _, ok := assignments.Logins("twitch:"); ok {
		t.Fatal("ready before the first snapshot")
	}
	snapshots := db.Collection("assignments").Snapshots(ctx)
	defer snapshots.Stop()
	next := func() {
		snapshot, err := snapshots.Next()
		if err != nil {
			t.Fatal(err)
		}
		assignments.Apply(snapshot.Changes)
	}
	next()
	if logins, ok := assignments.Logins("twitch:"); !ok || len(logins) != 1 || logins[0] != "listed" {
		t.Fatal(logins, ok)
	}
	if _, err := db.Collection("assignments").Doc("twitch:listed").Delete(ctx); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Collection("assignments").Doc("twitch:added").Set(ctx, map[string]interface{}{}); err != nil {
		t.Fatal(err)
	}
	for {
		next()
		if logins, _ := assignments.Logins("twitch:"); len(logins) == 1 && logins[0] == "added" {
			break
		}
	}
	// The job uses the snapshot even though the collection itself changed.
	if _, err := db.Collection("assignments").Doc("twitch:unseen").Set(ctx, map[string]interface{}{}); err != nil {
		t.Fatal(err)
	}
	var requested []string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/users" {
			requested = append(requested, r.URL.Query()["login"]...)
		}
		json.NewEncoder(w).Encode(map[string]interface{}{"data": []interface{}{}})
	}))
	defer server.Close()
	service := Service{Client: db, Assignments: &assignments, API: &API{Tokens: testTokens{}, Client: server.Client(), TwitchURL: server.URL}}
	if err := service.Twitch(ctx); err != nil {
		t.Fatal(err)
	}
	if len(requested) != 1 || requested[0] != "added" {
		t.Fatal(requested)
	}
}
