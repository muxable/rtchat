package webhook

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
)

func TestKickChannelMergeSkipsUnchangedMetadata(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("requires Firestore emulator")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	db, err := firestore.NewClient(ctx, fmt.Sprintf("kick-metadata-%d", time.Now().UnixNano()))
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	store := NewKickFirestoreStore(db)
	ref := db.Collection("channels").Doc("kick:123")
	metadata := map[string]interface{}{"login": "streamer", "displayName": "Streamer"}
	if err := store.MergeChannel(ctx, ref.ID, metadata); err != nil {
		t.Fatal(err)
	}
	before, err := ref.Get(ctx)
	if err != nil {
		t.Fatal(err)
	}
	// Every chat message repeats these fields. A no-op must leave UpdateTime
	// unchanged so it cannot invalidate a concurrent metadata poll's transaction.
	for i := 0; i < 3; i++ {
		if err := store.MergeChannel(ctx, ref.ID, metadata); err != nil {
			t.Fatal(err)
		}
	}
	after, err := ref.Get(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if !after.UpdateTime.Equal(before.UpdateTime) {
		t.Fatal("unchanged metadata performed a write")
	}
	if _, err := ref.Set(ctx, map[string]interface{}{"viewerCount": int64(99)}, firestore.MergeAll); err != nil {
		t.Fatal(err)
	}
	if err := store.MergeChannel(ctx, ref.ID, map[string]interface{}{"displayName": "New Name", "categoryId": float64(42), "onlineAt": nil}); err != nil {
		t.Fatal(err)
	}
	updated, err := ref.Get(ctx)
	if err != nil {
		t.Fatal(err)
	}
	data := updated.Data()
	if data["displayName"] != "New Name" || data["login"] != "streamer" || data["viewerCount"] != int64(99) || data["categoryId"] != int64(42) {
		t.Fatal(data)
	}
	if _, ok := data["onlineAt"]; !ok {
		t.Fatal("missing explicit nil field")
	}
	if err := store.MergeChannel(ctx, ref.ID, map[string]interface{}{"categoryId": float64(42), "onlineAt": nil}); err != nil {
		t.Fatal(err)
	}
	unchanged, err := ref.Get(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if !unchanged.UpdateTime.Equal(updated.UpdateTime) {
		t.Fatal("numeric normalization caused an unnecessary write")
	}
}
