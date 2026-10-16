package subscriptions

import (
	"context"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type KickEvent struct {
	Name    string `json:"name"`
	Version int    `json:"version"`
}

var KickEvents = []KickEvent{{"chat.message.sent", 1}, {"channel.followed", 1}, {"channel.subscription.new", 1}, {"channel.subscription.renewal", 1}, {"channel.subscription.gifts", 1}, {"kicks.gifted", 1}, {"livestream.status.updated", 1}, {"livestream.metadata.updated", 1}, {"moderation.banned", 1}, {"channel.reward.redemption.updated", 1}}

type kickSubscription struct {
	ID      string `json:"id"`
	Event   string `json:"event"`
	Version int    `json:"version"`
}

func missingKick(existing []kickSubscription) []KickEvent {
	var missing []KickEvent
	for _, event := range KickEvents {
		found := false
		for _, sub := range existing {
			if sub.Event == event.Name && sub.Version == event.Version {
				found = true
				break
			}
		}
		if !found {
			missing = append(missing, event)
		}
	}
	return missing
}
func (s *Service) listKick(ctx context.Context, id, token string) ([]kickSubscription, error) {
	var result struct {
		Data []kickSubscription `json:"data"`
	}
	if err := s.API.request(ctx, "kick", token, http.MethodGet, "/events/subscriptions", url.Values{"broadcaster_user_id": {id}}, nil, &result); err != nil {
		return nil, err
	}
	if result.Data == nil {
		return nil, fmt.Errorf("Kick subscriptions response missing data")
	}
	return result.Data, nil
}
func (s *Service) ensureKick(ctx context.Context, id string) error {
	ref := s.DB.Collection("webhooks").Doc("kick:" + id)
	doc, err := ref.Get(ctx)
	if err != nil && status.Code(err) != codes.NotFound {
		return err
	}
	if err == nil && activeCheck(doc.Data(), time.Now()) {
		// A failed partial creation never writes checkedAt, so it always reconciles.
		_, err = ref.Set(ctx, map[string]interface{}{"lastActiveAt": firestore.ServerTimestamp}, firestore.MergeAll)
		return err
	}
	token, err := s.API.Tokens.AppAccessToken(ctx, "kick")
	if err != nil {
		return err
	}
	existing, err := s.listKick(ctx, id, token)
	if err != nil {
		return err
	}
	missing := missingKick(existing)
	if len(missing) > 0 {
		// Serialize capacity checks with creation, not just per-channel work. This
		// prevents two replicas admitting different new channels into the last slot.
		err = subscriptionlock.With(ctx, s.DB, "kick-capacity", func(ctx context.Context) error {
			needsChat := false
			for _, event := range missing {
				if event.Name == "chat.message.sent" {
					needsChat = true
				}
			}
			if needsChat {
				docs, err := s.DB.Collection("webhooks").Documents(ctx).GetAll()
				if err != nil {
					return err
				}
				count := 0
				alreadyTracked := false
				for _, doc := range docs {
					if strings.HasPrefix(doc.Ref.ID, "kick:") {
						count++
						if doc.Ref.ID == "kick:"+id {
							alreadyTracked = true
						}
					}
				}
				limit := s.KickChannelLimit
				if limit <= 0 {
					limit = 1000
				}
				if count >= limit && !alreadyTracked {
					return &callable.Error{Code: "resource-exhausted", Message: "Kick chat subscription capacity reached"}
				}
				if count >= 900 {
					zap.L().Warn("Kick chat subscription capacity warning", zap.Int("channels", count), zap.Int("limit", limit))
				}
			}
			// Reserve capacity before POST: an ambiguous provider failure must leave
			// a tracked channel that later reconciliation/cleanup can recover.
			reservedIDs := []string{}
			for _, sub := range existing {
				reservedIDs = append(reservedIDs, sub.ID)
			}
			if _, err := ref.Set(ctx, map[string]interface{}{"subscriptionIds": reservedIDs, "lastActiveAt": firestore.ServerTimestamp, "checkedAt": time.Unix(0, 0)}, firestore.MergeAll); err != nil {
				return err
			}
			number, _ := strconv.ParseUint(id, 10, 53)
			body := map[string]interface{}{"broadcaster_user_id": number, "events": missing, "method": "webhook"}
			var created struct {
				Data []struct {
					SubscriptionID string      `json:"subscription_id"`
					Name           string      `json:"name"`
					Version        int         `json:"version"`
					Error          interface{} `json:"error"`
				} `json:"data"`
			}
			if err := s.API.request(ctx, "kick", token, http.MethodPost, "/events/subscriptions", nil, body, &created); err != nil {
				return err
			}
			// Always list provider state again; a partial/ambiguous response must not
			// claim a complete subscription set or lose successfully created IDs.
			listed, err := s.listKick(ctx, id, token)
			if err != nil {
				return err
			}
			existing = listed
			ids := []string{}
			for _, sub := range listed {
				ids = append(ids, sub.ID)
			}
			updates := map[string]interface{}{"subscriptionIds": ids, "lastActiveAt": firestore.ServerTimestamp}
			complete := len(missingKick(listed)) == 0
			if complete {
				updates["checkedAt"] = firestore.ServerTimestamp
			} else {
				updates["checkedAt"] = time.Unix(0, 0)
			}
			// Save while holding capacity lock so subsequent admissions see this slot.
			if _, err := ref.Set(ctx, updates, firestore.MergeAll); err != nil {
				return err
			}
			if !complete {
				return unavailable("Kick did not create all required event subscriptions; retry to reconcile")
			}
			return nil
		})
		if err != nil {
			return err
		}
	}
	ids := []string{}
	for _, sub := range existing {
		ids = append(ids, sub.ID)
	}
	_, err = ref.Set(ctx, map[string]interface{}{"subscriptionIds": ids, "checkedAt": firestore.ServerTimestamp, "lastActiveAt": firestore.ServerTimestamp}, firestore.MergeAll)
	return err
}
