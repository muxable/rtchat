package cancel

import (
	"context"
	"errors"
	"fmt"
	"net"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestIsCanceled(t *testing.T) {
	for _, tc := range []struct {
		err  error
		want bool
	}{
		{nil, false}, {context.Canceled, true}, {fmt.Errorf("wrapped: %w", context.Canceled), true}, {context.DeadlineExceeded, false}, {errors.New("canceled"), false}, {status.Error(codes.Canceled, "stop"), true}, {status.Error(codes.Unavailable, "down"), false}, {&net.OpError{Err: context.Canceled}, true},
	} {
		if got := IsCanceled(tc.err); got != tc.want {
			t.Errorf("IsCanceled(%v)=%v", tc.err, got)
		}
	}
}
