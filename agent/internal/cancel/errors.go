package cancel

import (
	"context"
	"errors"
	"net"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func IsCanceled(err error) bool {
	if errors.Is(err, context.Canceled) {
		return true
	}
	// is it a status.Error?
	if s, ok := status.FromError(err); ok {
		if s.Code() == codes.Canceled || errors.Is(s.Err(), context.Canceled) {
			return true
		}
	}
	// check if it's a net.OpError.
	if opErr, ok := err.(*net.OpError); ok {
		if errors.Is(opErr.Err, context.Canceled) {
			return true
		}
	}
	return false
}