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

func TestIdleAssignmentHeartbeat(t *testing.T) {
	cutoff := time.Now()
	old, recent := cutoff.Add(-time.Hour), cutoff.Add(time.Hour)
	for _, c := range []struct {
		data map[string]interface{}
		idle bool
	}{
		{map[string]interface{}{"subscribedAt": old}, true},
		{map[string]interface{}{"subscribedAt": recent}, false},
		{map[string]interface{}{"subscribedAt": old, "heartbeatAt": recent}, false},
		{map[string]interface{}{"subscribedAt": recent, "heartbeatAt": old}, false},
		{map[string]interface{}{"subscribedAt": old, "heartbeatAt": old}, true},
		// recreated by a heartbeat after cleanup.
		{map[string]interface{}{"heartbeatAt": recent}, false},
		{map[string]interface{}{"heartbeatAt": old}, true},
		{map[string]interface{}{}, false},
	} {
		if got := idleAssignment("twitch:user", c.data, cutoff); got != c.idle {
			t.Errorf("%v: got %v, want %v", c.data, got, c.idle)
		}
	}
}
