package provider

import (
	"context"
	"net/http"
	"testing"
)

type cancelOnPersistStore struct {
	memoryStore
	cancel context.CancelFunc
}

func (s *cancelOnPersistStore) Finish(ctx context.Context, l Lease, r RefreshResult) error {
	s.cancel()
	if err := ctx.Err(); err != nil {
		return err
	}
	return s.memoryStore.Finish(ctx, l, r)
}
func TestPersistSuccessfulRotationAfterCallerCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	store := &cancelOnPersistStore{memoryStore: memoryStore{encoded: expired}, cancel: cancel}
	s := newTestService(store, func(*http.Request) (*http.Response, error) {
		return response(200, `{"access_token":"new","refresh_token":"rotated","expires_in":3600}`), nil
	})
	_, _ = s.AccessToken(ctx, "user", "kick")
	token, _ := decodeToken(store.encoded)
	if tokenString(token, "refresh_token") != "rotated" {
		t.Fatalf("successful rotation was lost after caller cancellation: %s", store.encoded)
	}
}
