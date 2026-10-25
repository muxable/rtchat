package chatmessage

import (
	"testing"
	"time"
)

func TestTTLFor(t *testing.T) {
	for messageType, want := range map[string]time.Duration{
		"stream.online":  90 * 24 * time.Hour,
		"stream.offline": 90 * 24 * time.Hour,
		"message":        7 * 24 * time.Hour,
		"channel.follow": 7 * 24 * time.Hour,
		"":               7 * 24 * time.Hour,
	} {
		if got := TTLFor(messageType); got != want {
			t.Errorf("TTLFor(%q) = %v, want %v", messageType, got, want)
		}
	}
}
