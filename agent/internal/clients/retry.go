package clients

import (
	"context"
	"net/http"
	"strconv"
	"time"
)

func RetryDelay(headers http.Header, attempt int) time.Duration {
	delay := time.Duration(1<<attempt) * time.Second
	if seconds, err := strconv.Atoi(headers.Get("Retry-After")); err == nil && seconds > 0 {
		delay = time.Duration(seconds) * time.Second
	}
	if at, err := http.ParseTime(headers.Get("Retry-After")); err == nil && time.Until(at) > delay {
		delay = time.Until(at)
	}
	if reset, err := strconv.ParseInt(headers.Get("Ratelimit-Reset"), 10, 64); err == nil && time.Until(time.Unix(reset, 0)) > delay {
		delay = time.Until(time.Unix(reset, 0))
	}
	return delay
}

func Wait(ctx context.Context, delay time.Duration) error {
	timer := time.NewTimer(delay)
	defer timer.Stop()
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-timer.C:
		return nil
	}
}
