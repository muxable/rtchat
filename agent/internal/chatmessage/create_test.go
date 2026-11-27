package chatmessage

import (
	"context"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestCreate(t *testing.T) {
	for _, tc := range []struct {
		err           error
		wantDuplicate bool
		wantCode      codes.Code
	}{
		{nil, false, codes.OK},
		{status.Error(codes.AlreadyExists, ""), true, codes.OK},
		{status.Error(codes.PermissionDenied, ""), false, codes.PermissionDenied},
	} {
		duplicate, err := Create(context.Background(), func(context.Context) error { return tc.err })
		if duplicate != tc.wantDuplicate || status.Code(err) != tc.wantCode {
			t.Errorf("%v: duplicate=%v err=%v", tc.err, duplicate, err)
		}
	}
}
