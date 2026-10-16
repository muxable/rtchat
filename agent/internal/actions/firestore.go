package actions

import (
	"context"
	"fmt"
	"time"

	"cloud.google.com/go/firestore"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type FirestoreStore struct{ DB *firestore.Client }

func (s FirestoreStore) Profile(ctx context.Context, uid string) (map[string]any, error) {
	doc, err := s.DB.Collection("profiles").Doc(uid).Get(ctx)
	if status.Code(err) == codes.NotFound {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return doc.Data(), nil
}
func (s FirestoreStore) channel(id string) *firestore.DocumentRef {
	return s.DB.Collection("channels").Doc("twitch:" + id)
}
func (s FirestoreStore) raidMessage(ctx context.Context, id, kind string, raid map[string]any, at time.Time) error {
	_, err := s.channel(id).Collection("messages").Doc(kind+"-"+field(raid, "id")).Create(ctx, map[string]any{"channelId": "twitch:" + id, "type": kind, "raid": raid, "timestamp": at, "expiresAt": time.Now().Add(14 * 24 * time.Hour)})
	if status.Code(err) == codes.AlreadyExists {
		return nil
	}
	return err
}
func (s FirestoreStore) RaidStart(ctx context.Context, id string, target map[string]any, at time.Time) error {
	raid := map[string]any{"id": fmt.Sprintf("%s-%d", field(target, "id"), at.UnixMilli()), "target_id": field(target, "id"), "target_login": field(target, "login"), "target_display_name": field(target, "displayName"), "force_raid_now_seconds": 90}
	if err := s.raidMessage(ctx, id, "raid_update_v2", raid, at); err != nil {
		return err
	}
	_, err := s.channel(id).Set(ctx, map[string]any{"outgoingRaid": raid}, firestore.MergeAll)
	return err
}
func (s FirestoreStore) RaidCancel(ctx context.Context, id string, at time.Time) error {
	doc, err := s.channel(id).Get(ctx)
	if status.Code(err) == codes.NotFound {
		return nil
	}
	if err != nil {
		return err
	}
	raid := object(doc.Data()["outgoingRaid"])
	if raid == nil {
		return nil
	}
	if err := s.raidMessage(ctx, id, "raid_cancel_v2", raid, at); err != nil {
		return err
	}
	_, err = s.channel(id).Set(ctx, map[string]any{"outgoingRaid": nil}, firestore.MergeAll)
	return err
}
