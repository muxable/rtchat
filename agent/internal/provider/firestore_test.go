package provider

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"google.golang.org/api/option"
)

type cancelBeforeFirestoreCommit struct {
	Store
	cancel context.CancelFunc
}

func (s cancelBeforeFirestoreCommit) Finish(ctx context.Context, lease Lease, result RefreshResult) error {
	s.cancel()
	return s.Store.Finish(ctx, lease, result)
}

func TestFirestorePersistsRotationAfterRequestCancellation(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("set FIRESTORE_EMULATOR_HOST")
	}
	db, err := firestore.NewClient(context.Background(), fmt.Sprintf("demo-provider-%d", time.Now().UnixNano()), option.WithoutAuthentication())
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	ref := db.Collection("tokens").Doc("user")
	if _, err := ref.Set(context.Background(), map[string]any{"kick": expired}); err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	store := cancelBeforeFirestoreCommit{Store: FirestoreStore{DB: db}, cancel: cancel}
	service := newTestService(store, func(*http.Request) (*http.Response, error) {
		return response(200, `{"access_token":"new","refresh_token":"rotated","expires_in":3600}`), nil
	})
	_, _ = service.AccessToken(ctx, "user", "kick")
	doc, err := ref.Get(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	token, err := decodeToken(doc.Data()["kick"].(string))
	if err != nil {
		t.Fatal(err)
	}
	if tokenString(token, "refresh_token") != "rotated" || doc.Data()["_refresh_kick"] != nil {
		t.Fatal("rotation or lease completion lost")
	}
	if ctx.Err() == nil {
		t.Fatal("request was not canceled")
	}
}
