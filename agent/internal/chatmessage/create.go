package chatmessage

import (
	"context"
	"errors"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// Create runs create, a Firestore Create of one message document. Creates are
// idempotent: a document that already exists counts as written, and duplicate
// reports it. Stalled commits are hedged by the Firestore client itself.
func Create(ctx context.Context, create func(context.Context) error) (duplicate bool, err error) {
	err = create(ctx)
	if status.Code(err) == codes.AlreadyExists {
		return true, nil
	}
	return false, err
}

// Transient reports whether a Create that failed with err may succeed later.
func Transient(err error) bool {
	if errors.Is(err, context.DeadlineExceeded) {
		return true
	}
	switch status.Code(err) {
	case codes.Unavailable, codes.DeadlineExceeded, codes.Aborted, codes.ResourceExhausted:
		return true
	}
	return false
}
