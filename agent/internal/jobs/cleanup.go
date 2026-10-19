package jobs

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func idleAssignment(id string, data map[string]interface{}, cutoff time.Time) bool {
	at, ok := data["subscribedAt"].(time.Time)
	return id != "twitch:muxfd" && ok && at.Before(cutoff)
}
func (s *Service) Cleanup(ctx context.Context) error {
	cutoff := time.Now().Add(-7 * 24 * time.Hour)
	assignments, err := s.Client.Collection("assignments").Documents(ctx).GetAll()
	if err != nil {
		return err
	}
	for _, doc := range assignments {
		if !idleAssignment(doc.Ref.ID, doc.Data(), cutoff) {
			continue
		}
		if err := s.Client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
			current, err := tx.Get(doc.Ref)
			if status.Code(err) == codes.NotFound {
				return nil
			}
			if err != nil {
				return err
			}
			if !idleAssignment(current.Ref.ID, current.Data(), cutoff) {
				return nil
			}
			return tx.Delete(current.Ref)
		}); err != nil {
			return err
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
		}
	}
	if failures > 0 {
		return fmt.Errorf("%d idle Kick cleanup failures", failures)
	}
	return nil
}
func (s *Service) removeIdleKick(ctx context.Context, doc *firestore.DocumentSnapshot, cutoff time.Time) error {
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
