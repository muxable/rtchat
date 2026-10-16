package catalog

import (
	"context"
	"net/url"
	"os"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
)

func TestFirestoreYouTubeCacheTTLAndProfiles(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("requires Firestore emulator")
	}
	ctx := context.Background()
	db, err := firestore.NewClient(ctx, "demo-catalog")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	store := FirestoreStore{Client: db}
	key := "@cache-test"
	ref := db.Collection("youtube-lookups").Doc(url.QueryEscape(key))
	defer ref.Delete(ctx)
	if _, hit, err := store.CachedYouTube(ctx, key); err != nil || hit {
		t.Fatalf("missing cache %v %v", hit, err)
	}
	if err := store.CacheYouTube(ctx, key, []map[string]any{}); err != nil {
		t.Fatal(err)
	}
	if values, hit, err := store.CachedYouTube(ctx, key); err != nil || !hit || values == nil || len(values) != 0 {
		t.Fatal("negative cache lost")
	}
	doc, err := ref.Get(ctx)
	if err != nil {
		t.Fatal(err)
	}
	timestamp, ok := doc.Data()["cachedAt"].(time.Time)
	if !ok {
		t.Fatal("cache has no server timestamp")
	}
	store.Now = func() time.Time { return timestamp.Add(24*time.Hour + time.Second) }
	if _, hit, err := store.CachedYouTube(ctx, key); err != nil || hit {
		t.Fatal("expired cache accepted")
	}
	store.Now = nil
	results := []map[string]any{{"provider": "youtube", "channelId": "UCabcdefghijklmnopqr12_-", "login": "cached", "isOnline": false}}
	if err := store.CacheYouTube(ctx, key, results); err != nil {
		t.Fatal(err)
	}
	if cached, hit, err := store.CachedYouTube(ctx, key); err != nil || !hit || len(cached) != 1 || cached[0]["login"] != "cached" {
		t.Fatal("positive cache lost")
	}
	profile := db.Collection("profiles").Doc("catalog-test")
	defer profile.Delete(ctx)
	if _, err := profile.Set(ctx, map[string]any{"twitch": map[string]any{"id": "123", "login": "creator"}}); err != nil {
		t.Fatal(err)
	}
	if uid, err := store.BroadcasterUID(ctx, "123"); err != nil || uid != "catalog-test" {
		t.Fatalf("broadcaster lookup %q %v", uid, err)
	}
	if twitch, err := store.Profile(ctx, "catalog-test", "twitch"); err != nil || twitch["login"] != "creator" {
		t.Fatal("profile schema mismatch")
	}
}
