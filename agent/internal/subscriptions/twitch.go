package subscriptions

import (
	"context"
	"fmt"
	"net/http"
	"net/url"
	"reflect"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const TwitchCallback = "https://rtchat-api.rtirl.com/twitch/eventsub"

type twitchUser struct {
	ID    string `json:"id"`
	Login string `json:"login"`
}

func (s *Service) twitchUser(ctx context.Context, token string, q url.Values) (twitchUser, error) {
	var result struct {
		Data []twitchUser `json:"data"`
	}
	if err := s.API.twitch(ctx, token, http.MethodGet, "/users", q, nil, &result); err != nil {
		return twitchUser{}, err
	}
	if len(result.Data) != 1 {
		return twitchUser{}, invalid("invalid Twitch channel")
	}
	return result.Data[0], nil
}
func (s *Service) subscribeTwitch(ctx context.Context, uid, channel string) (interface{}, error) {
	token, err := s.API.Tokens.AppAccessToken(ctx, "twitch")
	if err != nil {
		return nil, err
	}
	user, err := s.twitchUser(ctx, token, url.Values{"id": {channel}})
	if err != nil {
		return nil, err
	}
	if user.ID != channel || user.Login == "" {
		return nil, invalid("invalid Twitch channel")
	}
	_, err = s.DB.Collection("assignments").Doc("twitch:"+user.Login).Set(ctx, map[string]interface{}{"subscribedAt": firestore.ServerTimestamp})
	if err != nil {
		return nil, err
	}
	if uid == "" {
		return user.Login, nil
	}
	ref := s.DB.Collection("profiles").Doc(uid)
	doc, err := ref.Get(ctx)
	if status.Code(err) == codes.NotFound {
		return user.Login, nil
	}
	if err != nil {
		return nil, err
	}
	owner := stringID(profile(doc.Data(), "twitch")["id"]) == channel
	if !owner {
		_, err = ref.Set(ctx, map[string]interface{}{"lastActiveAt": firestore.ServerTimestamp}, firestore.MergeAll)
		return user.Login, err
	}
	err = subscriptionlock.With(ctx, s.DB, "twitch:"+channel, func(ctx context.Context) error {
		// A server profile and its stored OAuth grant must identify the same
		// broadcaster before authenticated-only subscriptions are reconciled.
		userToken, err := s.API.Tokens.AccessToken(ctx, uid, "twitch")
		if err != nil {
			return &callable.Error{Code: "failed-precondition", Message: "reconnect Twitch before subscribing"}
		}
		current, err := s.twitchUser(ctx, userToken, nil)
		if err != nil {
			return err
		}
		if current.ID != channel {
			return &callable.Error{Code: "permission-denied", Message: "Twitch identity no longer matches profile"}
		}
		if err = s.ensureTwitch(ctx, channel, token); err != nil {
			return err
		}
		pending := false
		if err := s.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
			pending = false
			profileDoc, err := tx.Get(ref)
			if err != nil {
				return err
			}
			data := profileDoc.Data()
			if stringID(profile(data, "twitch")["id"]) != channel {
				return &callable.Error{Code: "permission-denied", Message: "Twitch profile changed"}
			}
			updates := map[string]interface{}{"lastActiveAt": firestore.ServerTimestamp}
			if data["lastActiveAt"] == nil {
				updates["welcomePendingChannel"] = channel
				pending = true
			} else {
				pending = data["welcomePendingChannel"] == channel
			}
			if err = tx.Set(ref, updates, firestore.MergeAll); err != nil {
				return err
			}
			return tx.Set(s.DB.Collection("channels").Doc("twitch:"+channel), map[string]interface{}{"lastActiveAt": firestore.ServerTimestamp}, firestore.MergeAll)
		}); err != nil {
			return err
		}
		if pending {
			return s.welcome(ctx, uid, channel, user.Login)
		}
		return nil
	})
	return user.Login, err
}

type twitchSubscription struct {
	ID        string            `json:"id"`
	Type      string            `json:"type"`
	Version   string            `json:"version"`
	Status    string            `json:"status"`
	Condition map[string]string `json:"condition"`
	Transport struct {
		Method   string `json:"method"`
		Callback string `json:"callback"`
	} `json:"transport"`
}
type twitchWanted struct {
	Type      string
	Version   string
	Condition map[string]string
}

func twitchConditions(id string) []twitchWanted {
	types := []string{"channel.follow", "channel.subscribe", "channel.subscription.gift", "channel.subscription.message", "channel.subscription.end", "channel.cheer", "channel.raid", "channel.ban", "channel.unban", "channel.channel_points_custom_reward_redemption.add", "channel.channel_points_custom_reward_redemption.update", "channel.poll.begin", "channel.poll.progress", "channel.poll.end", "channel.prediction.begin", "channel.prediction.progress", "channel.prediction.lock", "channel.prediction.end", "channel.hype_train.begin", "channel.hype_train.progress", "channel.hype_train.end", "channel.update", "stream.online", "stream.offline", "channel.shoutout.create", "channel.shoutout.receive"}
	var wanted []twitchWanted
	for _, kind := range types {
		if kind == "channel.raid" {
			wanted = append(wanted, twitchWanted{kind, "1", map[string]string{"to_broadcaster_user_id": id}}, twitchWanted{kind, "1", map[string]string{"from_broadcaster_user_id": id}})
			continue
		}
		condition := map[string]string{"broadcaster_user_id": id}
		version := "1"
		if kind == "channel.follow" {
			version = "2"
		}
		if kind == "channel.follow" || kind == "channel.shoutout.create" || kind == "channel.shoutout.receive" {
			condition["moderator_user_id"] = id
		}
		wanted = append(wanted, twitchWanted{kind, version, condition})
	}
	return wanted
}
func (s *Service) listTwitch(ctx context.Context, id, token string) ([]twitchSubscription, error) {
	var subscriptions []twitchSubscription
	seen := map[string]bool{}
	q := url.Values{"user_id": {id}}
	for {
		var result struct {
			Data       []twitchSubscription `json:"data"`
			Pagination struct {
				Cursor string `json:"cursor"`
			} `json:"pagination"`
		}
		if err := s.API.twitch(ctx, token, http.MethodGet, "/eventsub/subscriptions", q, nil, &result); err != nil {
			return nil, err
		}
		if result.Data == nil {
			return nil, fmt.Errorf("Twitch subscriptions response missing data")
		}
		subscriptions = append(subscriptions, result.Data...)
		cursor := result.Pagination.Cursor
		if cursor == "" {
			return subscriptions, nil
		}
		if seen[cursor] {
			return nil, fmt.Errorf("Twitch subscription pagination loop")
		}
		seen[cursor] = true
		q.Set("after", cursor)
	}
}
func (s *Service) ensureTwitch(ctx context.Context, id, token string) error {
	if len(s.TwitchSecret) < 10 || len(s.TwitchSecret) > 100 {
		return &callable.Error{Code: "failed-precondition", Message: "dedicated Twitch webhook signing secret is not configured"}
	}
	existing, err := s.listTwitch(ctx, id, token)
	if err != nil {
		return err
	}
	wantedSubscriptions := twitchConditions(id)
	// Validate the entire existing set before any creation/deletion. A later
	// legacy callback conflict must not leave a partially migrated broadcaster.
	for _, wanted := range wantedSubscriptions {
		for _, sub := range existing {
			if sub.Type == wanted.Type && sub.Version == wanted.Version && reflect.DeepEqual(sub.Condition, wanted.Condition) && (sub.Transport.Method != "webhook" || sub.Transport.Callback != TwitchCallback) {
				return &callable.Error{Code: "failed-precondition", Message: "Twitch callbacks require coordinated migration before enabling subscriptions"}
			}
		}
	}
	for _, wanted := range wantedSubscriptions {
		found := false
		for _, sub := range existing {
			if sub.Type != wanted.Type || sub.Version != wanted.Version || !reflect.DeepEqual(sub.Condition, wanted.Condition) {
				continue
			}
			if sub.Status == "enabled" || sub.Status == "webhook_callback_verification_pending" {
				found = true
				break
			}
			// Failed subscriptions at our own callback may be replaced safely. Never
			// delete a legacy or unknown transport as a side effect of app activity.
			if err = s.API.twitch(ctx, token, http.MethodDelete, "/eventsub/subscriptions", url.Values{"id": {sub.ID}}, nil, nil); err != nil && !isStatus(err, 404) {
				return err
			}
		}
		if found {
			continue
		}
		body := map[string]interface{}{"type": wanted.Type, "version": wanted.Version, "condition": wanted.Condition, "transport": map[string]interface{}{"method": "webhook", "callback": TwitchCallback, "secret": s.TwitchSecret}}
		err = s.API.twitch(ctx, token, http.MethodPost, "/eventsub/subscriptions", nil, body, nil)
		if isStatus(err, 403) {
			zap.L().Warn("Twitch EventSub scope unavailable", zap.String("type", wanted.Type), zap.String("channel", id))
			continue
		}
		if err != nil {
			return err
		}
	}
	return nil
}

func (s *Service) welcome(ctx context.Context, uid, channel, login string) error {
	messages := []string{fmt.Sprintf("Welcome to RealtimeChat, @%s! VoHiYo", login), "Your chat will appear here, even if you close the app. Have a good stream!"}
	for i, message := range messages {
		ref := s.DB.Collection("channels").Doc("twitch:" + channel).Collection("messages").Doc(fmt.Sprintf("welcome-v1-%d", i+1))
		_, err := ref.Create(ctx, map[string]interface{}{
			"channelId": "twitch:" + channel, "annotations": map[string]interface{}{"isAction": false, "isFirstTimeChatter": false}, "author": map[string]interface{}{"displayName": "muxfd", "userId": "158394109", "color": ""}, "reply": nil, "timestamp": firestore.ServerTimestamp,
			"tags": map[string]interface{}{"user-id": "158394109", "room-id": "158394109", "display-name": "muxfd", "color": "", "username": "muxfd", "badges": map[string]interface{}{}, "emotes-raw": "", "badges-raw": ""}, "type": "message", "message": message, "expiresAt": time.Now().Add(14 * 24 * time.Hour),
		})
		if err != nil && status.Code(err) != codes.AlreadyExists {
			return err
		}
		if i == 0 && err == nil {
			timer := time.NewTimer(3 * time.Second)
			select {
			case <-ctx.Done():
				timer.Stop()
				return ctx.Err()
			case <-timer.C:
			}
		}
	}
	_, err := s.DB.Collection("profiles").Doc(uid).Set(ctx, map[string]interface{}{"welcomePendingChannel": firestore.Delete}, firestore.MergeAll)
	return err
}
