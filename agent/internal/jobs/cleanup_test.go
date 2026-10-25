package jobs

import (
	"testing"
	"time"
)

func TestIdleTimeout(t *testing.T) {
	for value, want := range map[string]time.Duration{
		"":      defaultIdleTimeout,
		"26h":   idleTimeoutWithHeartbeat,
		"bogus": defaultIdleTimeout,
		"-1h":   defaultIdleTimeout,
		"1m":    defaultIdleTimeout,
		"168h":  7 * 24 * time.Hour,
	} {
		t.Setenv("IDLE_CHANNEL_TIMEOUT", value)
		if got := idleTimeout(); got != want {
			t.Errorf("%q: got %v, want %v", value, got, want)
		}
	}
}
