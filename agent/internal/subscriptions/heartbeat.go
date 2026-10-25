package subscriptions

import (
	"context"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
)

// HeartbeatField is set on an assignment by heartbeats. Unlike subscribedAt,
// which a subscribe on channel open rewrites, a change to it alone doesn't
// make the agent reconnect the channel's chat.
const HeartbeatField = "heartbeatAt"

// kickHeartbeatCheck is how long a heartbeat trusts a Kick channel's last
// subscription check. It spans two heartbeats, so at most every other one
// lists the channel's subscriptions.
const kickHeartbeatCheck = 2 * time.Hour

// heartbeat keeps a channel that a client is still showing from going idle.
// The profile, owner and provider subscription work was done by the subscribe
// when the channel was opened, so this only refreshes the channel's activity.
// A channel that was cleaned up in the meantime is subscribed to again.
func (s *Service) heartbeat(ctx context.Context, provider, channel string) (interface{}, error) {
	switch provider {
	case "youtube":
		return channel, s.touchAssignment(ctx, "youtube:"+channel)
	case "twitch":
		user, err := s.twitchChannel(ctx, channel)
		if err != nil {
			return nil, err
		}
		return user.Login, s.touchAssignment(ctx, "twitch:"+user.Login)
	case "kick":
		// Heartbeats are an hour apart, so the open path's one-hour check
		// cache would reconcile with Kick on every one.
		if err := subscriptionlock.With(ctx, s.DB, "kick:"+channel, func(ctx context.Context) error { return s.ensureKick(ctx, channel, kickHeartbeatCheck) }); err != nil {
			return nil, err
		}
		return channel, nil
	}
	return nil, invalid("invalid provider")
}

// touchAssignment sets the heartbeat on an assignment, creating it if cleanup
// removed it, so the agent joins the channel again.
func (s *Service) touchAssignment(ctx context.Context, id string) error {
	_, err := s.DB.Collection("assignments").Doc(id).Set(ctx, map[string]interface{}{HeartbeatField: firestore.ServerTimestamp}, firestore.MergeAll)
	return err
}
