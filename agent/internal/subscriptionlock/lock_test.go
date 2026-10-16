package subscriptionlock

import (
	"context"
	"fmt"
	"os"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"google.golang.org/api/option"
)

func TestLeaseExclusionExpiryAndCancellation(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST")
	}
	ctx := context.Background()
	db, err := firestore.NewClient(ctx, fmt.Sprintf("lifecycle-%d", time.Now().UnixNano()), option.WithoutAuthentication())
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	var active atomic.Int32
	var runs atomic.Int32
	var wg sync.WaitGroup
	for i := 0; i < 3; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := With(ctx, db, "kick:123", func(context.Context) error {
				if active.Add(1) != 1 {
					t.Error("concurrent lifecycle work")
				}
				runs.Add(1)
				time.Sleep(10 * time.Millisecond)
				active.Add(-1)
				return nil
			}); err != nil {
				t.Error(err)
			}
		}()
	}
	wg.Wait()
	if runs.Load() != 3 {
		t.Fatal(runs.Load())
	}
	if _, err := db.Collection("subscriptionLeases").Doc("kick:dead").Set(ctx, map[string]interface{}{"owner": "dead", "until": time.Now().Add(-time.Second)}); err != nil {
		t.Fatal(err)
	}
	if err := With(ctx, db, "kick:dead", func(context.Context) error { return nil }); err != nil {
		t.Fatal("expired lease not taken", err)
	}
	if _, err := db.Collection("subscriptionLeases").Doc("kick:busy").Set(ctx, map[string]interface{}{"owner": "live", "until": time.Now().Add(time.Minute)}); err != nil {
		t.Fatal(err)
	}
	bounded, cancel := context.WithTimeout(ctx, 30*time.Millisecond)
	defer cancel()
	if err := With(bounded, db, "kick:busy", func(context.Context) error { t.Error("entered busy lease"); return nil }); err == nil {
		t.Fatal("canceled wait succeeded")
	}
}
