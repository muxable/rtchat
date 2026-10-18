package main

import (
	"context"
	"fmt"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/clients/twitch"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type chatFirestore struct{ DB *firestore.Client }

func (s chatFirestore) Profile(ctx context.Context, uid string) (map[string]any, error) {
	doc, err := s.DB.Collection("profiles").Doc(uid).Get(ctx)
	if status.Code(err) == codes.NotFound {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return doc.Data(), nil
}
func (s chatFirestore) channel(id string) *firestore.DocumentRef {
	return s.DB.Collection("channels").Doc("twitch:" + id)
}
func (s chatFirestore) raidMessage(ctx context.Context, id, kind string, raid map[string]any, at time.Time) error {
	_, err := s.channel(id).Collection("messages").Doc(kind+"-"+field(raid, "id")).Create(ctx, map[string]any{"channelId": "twitch:" + id, "type": kind, "raid": raid, "timestamp": at, "expiresAt": time.Now().Add(14 * 24 * time.Hour)})
	if status.Code(err) == codes.AlreadyExists {
		return nil
	}
	return err
}
func (s chatFirestore) RaidStart(ctx context.Context, id string, target twitch.User, at time.Time) error {
	if target.DisplayName == "" {
		target.DisplayName = target.Login
	}
	raid := map[string]any{"id": fmt.Sprintf("%s-%d", target.ID, at.UnixMilli()), "target_id": target.ID, "target_login": target.Login, "target_display_name": target.DisplayName, "force_raid_now_seconds": 90}
	if err := s.raidMessage(ctx, id, "raid_update_v2", raid, at); err != nil {
		return err
	}
	_, err := s.channel(id).Set(ctx, map[string]any{"outgoingRaid": raid}, firestore.MergeAll)
	return err
}
func (s chatFirestore) RaidCancel(ctx context.Context, id string, at time.Time) error {
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
