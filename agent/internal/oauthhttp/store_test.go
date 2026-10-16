package oauthhttp

import (
	"context"
	"encoding/json"
	"os"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
)

// Exercises real Firestore transactions. Run against an emulator, never production.
func TestFirestoreReplicaTransactions(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("requires Firestore emulator")
	}
	ctx := context.Background()
	client, err := firestore.NewClient(ctx, "demo-oauth-http")
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	store := &FirebaseStore{Firestore: client}
	replica := &FirebaseStore{Firestore: client}
	id := random()
	session := Session{State: "state", Provider: "kick", Verifier: "pkce", Companion: "desktop", Expires: time.Now().Add(time.Minute)}
	if err := store.SaveSession(ctx, id, session); err != nil {
		t.Fatal(err)
	}
	if _, err := replica.ConsumeSession(ctx, id, "kick", "wrong"); err == nil {
		t.Fatal("accepted mismatched state")
	}
	var successes int32
	var wg sync.WaitGroup
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			v, err := replica.ConsumeSession(ctx, id, "kick", "state")
			if err == nil {
				if v.Verifier != "pkce" || v.Companion != "desktop" {
					t.Error("lost shared state")
				}
				atomic.AddInt32(&successes, 1)
			}
		}()
	}
	wg.Wait()
	if successes != 1 {
		t.Fatalf("callbacks accepted: %d", successes)
	}
	session.Expires = time.Now().Add(-time.Second)
	expired := random()
	if err := store.SaveSession(ctx, expired, session); err != nil {
		t.Fatal(err)
	}
	defer client.Collection("oauth-http-sessions").Doc(expired).Delete(ctx)
	if _, err := replica.ConsumeSession(ctx, expired, "kick", "state"); err == nil {
		t.Fatal("accepted expired session")
	}
	tokenRef := client.Collection("tokens").Doc(random())
	defer tokenRef.Delete(ctx)
	if err := store.persistToken(ctx, tokenRef, "youtube", map[string]any{"access_token": "old", "refresh_token": "keep"}); err != nil {
		t.Fatal(err)
	}
	if err := replica.persistToken(ctx, tokenRef, "youtube", map[string]any{"access_token": "new"}); err != nil {
		t.Fatal(err)
	}
	doc, err := tokenRef.Get(ctx)
	if err != nil {
		t.Fatal(err)
	}
	var token map[string]any
	if err := json.Unmarshal([]byte(doc.Data()["youtube"].(string)), &token); err != nil {
		t.Fatal(err)
	}
	if token["refresh_token"] != "keep" || token["access_token"] != "new" {
		t.Fatal("refresh token lost")
	}
	peer := random()
	for i := 0; i < 30; i++ {
		ok, err := store.Allow(ctx, peer)
		if err != nil || !ok {
			t.Fatalf("request %d: %v %v", i, ok, err)
		}
	}
	if ok, err := replica.Allow(ctx, peer); err != nil || ok {
		t.Fatalf("replica bypassed rate limit: %v %v", ok, err)
	}
}
