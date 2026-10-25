package chatmessage

import (
	"testing"
	"time"
)

func TestTTLIsSevenDays(t *testing.T) {
	if TTL != 7*24*time.Hour {
		t.Fatalf("TTL = %v, want 7 days", TTL)
	}
}
