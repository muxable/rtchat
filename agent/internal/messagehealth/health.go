package messagehealth

import (
	"context"
	"encoding/json"
	"net/http"
	"sync/atomic"
	"time"

	"go.uber.org/zap"
)

var (
	lastMessageUnixNano atomic.Int64
	messageCount        atomic.Uint64
)

type Snapshot struct {
	Status         string     `json:"status"`
	MessageCount   uint64     `json:"messageCount"`
	LastMessageAt  *time.Time `json:"lastMessageAt"`
	CheckedAt      time.Time  `json:"checkedAt"`
	StaleAfterSecs int64      `json:"staleAfterSeconds"`
}

func MarkMessageReceived() {
	lastMessageUnixNano.Store(time.Now().UnixNano())
	messageCount.Add(1)
}

func Current(staleAfter time.Duration) Snapshot {
	now := time.Now()
	last := lastMessageUnixNano.Load()

	result := Snapshot{
		Status:         "waiting",
		MessageCount:   messageCount.Load(),
		CheckedAt:      now,
		StaleAfterSecs: int64(staleAfter.Seconds()),
	}

	if last == 0 {
		return result
	}

	lastAt := time.Unix(0, last)
	result.LastMessageAt = &lastAt

	if staleAfter <= 0 || now.Sub(lastAt) <= staleAfter {
		result.Status = "healthy"
	} else {
		result.Status = "stale"
	}

	return result
}

// Run logs the delivery status periodically until ctx is cancelled.
func Run(ctx context.Context, interval, staleAfter time.Duration) {
	if interval <= 0 {
		interval = 5 * time.Minute
	}
	if staleAfter <= 0 {
		staleAfter = 15 * time.Minute
	}

	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	check := func() {
		s := Current(staleAfter)

		fields := []zap.Field{
			zap.String("status", s.Status),
			zap.Uint64("messageCount", s.MessageCount),
			zap.Duration("staleAfter", staleAfter),
		}

		if s.LastMessageAt != nil {
			fields = append(fields,
				zap.Time("lastMessageAt", *s.LastMessageAt))
		}

		if s.Status == "stale" || s.Status == "waiting" {
			zap.L().Warn("message delivery health check", fields...)
		} else {
			zap.L().Info("message delivery health check", fields...)
		}
	}

	check()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			check()
		}
	}
}

// Handler reports message-delivery health independently of API readiness.
func Handler(staleAfter time.Duration) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.Header().Set("Allow", http.MethodGet)
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		s := Current(staleAfter)
		w.Header().Set("Content-Type", "application/json")

		if s.Status != "healthy" {
			w.WriteHeader(http.StatusServiceUnavailable)
		}

		if err := json.NewEncoder(w).Encode(s); err != nil {
			zap.L().Warn("failed to write message health response",
				zap.Error(err))
		}
	})
}
