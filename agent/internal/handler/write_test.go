package handler

import (
	"context"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestCreateMessageRetriesTransientError(t *testing.T) {
	calls := 0
	err := createMessage(context.Background(), func(context.Context) error {
		calls++
		if calls == 1 {
			return status.Error(codes.Unavailable, "temporary outage")
		}
		return nil
	})
	if err != nil || calls != 2 {
		t.Fatalf("calls=%d err=%v; chat dropped", calls, err)
	}
}

func TestCreateMessageAlreadyExistsAndPermanentError(t *testing.T) {
	for _, code := range []codes.Code{codes.AlreadyExists, codes.PermissionDenied} {
		calls := 0
		err := createMessage(context.Background(), func(context.Context) error { calls++; return status.Error(code, "fake") })
		if calls != 1 || (err == nil) != (code == codes.AlreadyExists) {
			t.Fatalf("calls=%d err=%v", calls, err)
		}
	}
}
