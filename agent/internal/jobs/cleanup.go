package jobs

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// defaultIdleTimeout is how long a channel keeps its assignment (and a Kick
// channel its webhooks) after its last subscribe. Clients since the heartbeat
// release re-subscribe hourly while they show or read out a channel, so this
// can drop to idleTimeoutWithHeartbeat once older clients, which subscribe
// only when a channel is opened, have aged out.
const defaultIdleTimeout = 7 * 24 * time.Hour

// idleTimeoutWithHeartbeat is the timeout to set IDLE_CHANNEL_TIMEOUT to once
// heartbeating clients are the norm: a day plus slack over the hourly
// heartbeat for clients that are briefly offline.
const idleTimeoutWithHeartbeat = 26 * time.Hour

// idleTimeout reads IDLE_CHANNEL_TIMEOUT (a Go duration, e.g. "26h"), falling
// back to defaultIdleTimeout when it's unset or invalid.
func idleTimeout() time.Duration {
	value := os.Getenv("IDLE_CHANNEL_TIMEOUT")
	if value == "" {
		return defaultIdleTimeout
	}
	timeout, err := time.ParseDuration(value)
	if err != nil || timeout < time.Hour {
		zap.L().Error("invalid IDLE_CHANNEL_TIMEOUT, using default", zap.String("value", value), zap.Duration("default", defaultIdleTimeout))
		return defaultIdleTimeout
	}
	return timeout
}

// idleAssignment reports whether an assignment's last subscribe and heartbeat
// (subscriptions.HeartbeatField) are both before cutoff. One with neither is
// kept.
func idleAssignment(id string, data map[string]interface{}, cutoff time.Time) bool {
	subscribed, hasSubscribed := data["subscribedAt"].(time.Time)
	beat, hasBeat := data["heartbeatAt"].(time.Time)
	if id == "twitch:muxfd" || (!hasSubscribed && !hasBeat) {
		return false
	}
	return (!hasSubscribed || subscribed.Before(cutoff)) && (!hasBeat || beat.Before(cutoff))
}
func (s *Service) Cleanup(ctx context.Context) error {
	cutoff := time.Now().Add(-idleTimeout())
	assignments, err := s.Client.Collection("assignments").Documents(ctx).GetAll()
	if err != nil {
		return err
	}
	var assignmentsRemoved, kickProcessed int
	defer func() {
		zap.L().Info("idle channels cleaned up", zap.Int("assignmentsRemoved", assignmentsRemoved), zap.Int("kickProcessed", kickProcessed))
	}()
	for _, doc := range assignments {
		if !idleAssignment(doc.Ref.ID, doc.Data(), cutoff) {
			continue
		}
		removed := false
		if err := s.Client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
			current, err := tx.Get(doc.Ref)
			if status.Code(err) == codes.NotFound {
				return nil
			}
			if err != nil {
				return err
			}
			removed = idleAssignment(current.Ref.ID, current.Data(), cutoff)
			if !removed {
				return nil
			}
			return tx.Delete(current.Ref)
		}); err != nil {
			return err
		}
		if removed {
			assignmentsRemoved++
		}
	}
	docs, err := s.Client.Collection("webhooks").Where("lastActiveAt", "<", cutoff).Documents(ctx).GetAll()
	if err != nil {
		return err
	}
	var failures int
	for _, doc := range docs {
		if !strings.HasPrefix(doc.Ref.ID, "kick:") {
			continue
		}
		if err := s.removeIdleKick(ctx, doc, cutoff); err != nil {
			failures++
			zap.L().Error("idle kick cleanup failed", zap.String("channel", doc.Ref.ID), zap.Error(err))
			continue
		}
		kickProcessed++
	}
	if failures > 0 {
		return fmt.Errorf("%d idle Kick cleanup failures", failures)
	}
	return nil
}
func (s *Service) removeIdleKick(ctx context.Context, doc *firestore.DocumentSnapshot, cutoff time.Time) error {
	return subscriptionlock.With(ctx, s.Client, doc.Ref.ID, func(ctx context.Context) error {
		return s.removeIdleKickLocked(ctx, doc, cutoff)
	})
}

func (s *Service) removeIdleKickLocked(ctx context.Context, doc *firestore.DocumentSnapshot, cutoff time.Time) error {
	current, err := doc.Ref.Get(ctx)
	if status.Code(err) == codes.NotFound {
		return nil
	}
	if err != nil {
		return err
	}
	var data struct {
		LastActiveAt    time.Time `firestore:"lastActiveAt"`
		SubscriptionIDs []string  `firestore:"subscriptionIds"`
	}
	if err := current.DataTo(&data); err != nil {
		return err
	}
	if data.LastActiveAt.IsZero() || !data.LastActiveAt.Before(cutoff) {
		return nil
	}
	ids := data.SubscriptionIDs
	// Reconcile actual provider state before deleting. A creation can have
	// succeeded before its caller lost the response or Firestore write.
	var listed struct {
		Data []struct {
			ID string `json:"id"`
		} `json:"data"`
	}
	if err := s.API.kick(ctx, http.MethodGet, "/events/subscriptions", params("broadcaster_user_id", []string{strings.TrimPrefix(doc.Ref.ID, "kick:")}), &listed); err != nil {
		return err
	}
	if listed.Data == nil {
		return errors.New("Kick subscriptions response missing data")
	}
	seen := map[string]bool{}
	for _, id := range ids {
		seen[id] = true
	}
	for _, sub := range listed.Data {
		if !seen[sub.ID] {
			ids = append(ids, sub.ID)
			seen[sub.ID] = true
		}
	}
	for start := 0; start < len(ids); start += 50 {
		if err := s.API.kick(ctx, http.MethodDelete, "/events/subscriptions", params("id", ids[start:min(start+50, len(ids))]), nil); err != nil {
			return err
		}
	}
	_, err = doc.Ref.Delete(ctx, firestore.LastUpdateTime(current.UpdateTime))
	if status.Code(err) == codes.NotFound {
		return nil
	}
	if status.Code(err) == codes.FailedPrecondition {
		// A concurrent subscribe retains its document; invalidate the cached check
		// so its next refresh verifies/recreates any deleted provider subscriptions.
		_, repairErr := doc.Ref.Set(ctx, map[string]interface{}{"checkedAt": time.Unix(0, 0)}, firestore.MergeAll)
		return repairErr
	}
	return err
}
