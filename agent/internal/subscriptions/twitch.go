package subscriptions

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/chatmessage"
	"github.com/muxable/rtchat/agent/internal/provider"
	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const TwitchCallback = "https://rtchat-api.rtirl.com/twitch/eventsub"

// LegacyTwitchCallback is the Cloud Function that received EventSub before the
// agent. It now forwards deliveries to TwitchCallback with the same signing
// secret, so subscriptions there still reach the agent until migrate-eventsub
// moves them.
const LegacyTwitchCallback = "https://us-central1-rtchat-47692.cloudfunctions.net/eventsub"

func ownCallback(sub twitchSubscription) bool {
	return sub.Transport.Method == "webhook" && (sub.Transport.Callback == TwitchCallback || sub.Transport.Callback == LegacyTwitchCallback)
}

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
		if err := s.checkTwitchSecret(); err != nil {
			return err
		}
		// Twitch's rate and cost limits make EventSub creation too slow and
		// too likely to fail for the request; the worker reconciles it.
		s.Queue.Enqueue(channel)
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

// sameCondition compares EventSub conditions, treating an empty value as
// absent. Twitch lists every condition field of a type, so a raid sent to the
// broadcaster comes back with from_broadcaster_user_id "" and a redemption
// without a reward with reward_id "".
func sameCondition(a, b map[string]string) bool {
	for key, value := range a {
		if value != "" && b[key] != value {
			return false
		}
	}
	for key, value := range b {
		if value != "" && a[key] != value {
			return false
		}
	}
	return true
}

func (s *Service) checkTwitchSecret() error {
	if len(s.TwitchSecret) < 10 || len(s.TwitchSecret) > 100 {
		return &callable.Error{Code: "failed-precondition", Message: "dedicated Twitch webhook signing secret is not configured"}
	}
	return nil
}

// twitchCall sends one request to /eventsub/subscriptions.
type twitchCall func(ctx context.Context, method string, q url.Values, body, out any) error

// listTwitch pages through the subscriptions matching filter, such as user_id
// or type.
func listTwitch(ctx context.Context, filter url.Values, call twitchCall) ([]twitchSubscription, error) {
	var subscriptions []twitchSubscription
	seen := map[string]bool{}
	q := url.Values{}
	for key, values := range filter {
		q[key] = values
	}
	for {
		var result struct {
			Data       []twitchSubscription `json:"data"`
			Pagination struct {
				Cursor string `json:"cursor"`
			} `json:"pagination"`
		}
		if err := call(ctx, http.MethodGet, q, nil, &result); err != nil {
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

type twitchReconcile struct {
	created int
	skipped []string
	held    []string
}

// reconcileTwitch lists a broadcaster's subscriptions and creates the missing
// ones. Every attempt lists first, so a POST with an uncertain outcome is not
// created twice. Types Twitch rejects are skipped and types over the cost
// limit are returned as held; any other failure stops the attempt.
func (s *Service) reconcileTwitch(ctx context.Context, id string, call twitchCall) (twitchReconcile, error) {
	var result twitchReconcile
	if err := s.checkTwitchSecret(); err != nil {
		return result, err
	}
	existing, err := listTwitch(ctx, url.Values{"user_id": {id}}, call)
	if err != nil {
		return result, err
	}
	wantedSubscriptions := twitchConditions(id)
	// Validate the entire existing set before any creation/deletion. A later
	// legacy callback conflict must not leave a partially migrated broadcaster.
	for _, wanted := range wantedSubscriptions {
		for _, sub := range existing {
			if sub.Type == wanted.Type && sub.Version == wanted.Version && sameCondition(sub.Condition, wanted.Condition) && !ownCallback(sub) {
				return result, &callable.Error{Code: "failed-precondition", Message: "Twitch callbacks require coordinated migration before enabling subscriptions"}
			}
		}
	}
	for _, wanted := range wantedSubscriptions {
		found := false
		for _, sub := range existing {
			if sub.Type != wanted.Type || sub.Version != wanted.Version || !sameCondition(sub.Condition, wanted.Condition) {
				continue
			}
			if sub.Status == "enabled" || sub.Status == "webhook_callback_verification_pending" {
				found = true
				break
			}
			// Failed subscriptions at our own callback may be replaced safely. Never
			// delete a legacy or unknown transport as a side effect of app activity.
			if err = call(ctx, http.MethodDelete, url.Values{"id": {sub.ID}}, nil, nil); err != nil && !isStatus(err, 404) {
				return result, err
			}
		}
		if found {
			continue
		}
		body := map[string]interface{}{"type": wanted.Type, "version": wanted.Version, "condition": wanted.Condition, "transport": map[string]interface{}{"method": "webhook", "callback": TwitchCallback, "secret": s.TwitchSecret}}
		err = call(ctx, http.MethodPost, nil, body, nil)
		outcome := "created"
		switch {
		case err == nil:
			result.created++
		case isStatus(err, 409):
			// Created concurrently, such as by migrate-eventsub or another replica.
			outcome = "exists"
		case isStatus(err, 403):
			outcome = "scope_unavailable"
			result.skipped = append(result.skipped, wanted.Type)
		case errors.As(err, new(*costLimitError)):
			outcome = "cost_limited"
			result.held = append(result.held, wanted.Type)
		case isStatus(err, 400):
			// Retired types or versions.
			outcome = "rejected"
			result.skipped = append(result.skipped, wanted.Type)
		case errors.Is(err, errTwitchBudget):
			return result, err
		case isStatus(err, 429):
			outcome = "rate_limited"
		default:
			outcome = "error"
		}
		zap.L().Info("twitch eventsub create", zap.String("channel", id), zap.String("type", wanted.Type), zap.String("outcome", outcome), zap.Error(err))
		if outcome == "rate_limited" || outcome == "error" {
			return result, err
		}
	}
	return result, nil
}

// twitchTargets reports whether a subscription's condition is about the
// broadcaster, as every subscription twitchConditions creates is.
func twitchTargets(sub twitchSubscription, id string) bool {
	for _, key := range []string{"broadcaster_user_id", "to_broadcaster_user_id", "from_broadcaster_user_id"} {
		if sub.Condition[key] == id {
			return true
		}
	}
	return false
}

// twitchReauthorized reports whether the broadcaster has authorized the app
// again since a deauthorization: a profile linked to them holds a Twitch grant
// that Twitch accepts as theirs. A removal delayed past re-authorization would
// otherwise delete what subscribe, perhaps on another replica, just created.
// The stored grant has no timestamp of its own, so it is checked with Twitch.
func (s *Service) twitchReauthorized(ctx context.Context, id string) (bool, error) {
	ids := []interface{}{id}
	if n, err := strconv.ParseInt(id, 10, 64); err == nil {
		// Older profiles store the id as a number.
		ids = append(ids, n)
	}
	docs, err := s.DB.Collection("profiles").Where("twitch.id", "in", ids).Limit(10).Documents(ctx).GetAll()
	if err != nil {
		return false, err
	}
	for _, doc := range docs {
		token, err := s.API.Tokens.AccessToken(ctx, doc.Ref.ID, "twitch")
		if errors.Is(err, provider.ErrNoToken) {
			continue
		}
		if err != nil {
			return false, err
		}
		user, err := s.twitchUser(ctx, token, nil)
		if isStatus(err, 401) {
			// The grant the deauthorization revoked.
			continue
		}
		if err != nil {
			return false, err
		}
		if user.ID == id {
			return true, nil
		}
	}
	return false, nil
}

// removeTwitch deletes a deauthorized broadcaster's subscriptions at our
// callbacks. Twitch revokes the ones that needed their authorization, but
// keeps the unscoped ones, such as stream.online, enabled and counted against
// the client's cost limit. Every attempt lists first, so a retry only deletes
// what is left.
func (s *Service) removeTwitch(ctx context.Context, id string, call twitchCall) (int, error) {
	existing, err := listTwitch(ctx, url.Values{"user_id": {id}}, call)
	if err != nil {
		return 0, err
	}
	deleted := 0
	for _, sub := range existing {
		if !ownCallback(sub) || !twitchTargets(sub, id) {
			continue
		}
		err := call(ctx, http.MethodDelete, url.Values{"id": {sub.ID}}, nil, nil)
		switch {
		case err == nil:
			deleted++
		case !isStatus(err, 404):
			return deleted, err
		}
	}
	return deleted, nil
}

// twitchAppType tells the app when a user deauthorizes it. Twitch delivers it
// only to webhooks, and it costs nothing.
const twitchAppType = "user.authorization.revoke"

// ensureTwitchApp creates the app's user.authorization.revoke subscription
// unless one at our callbacks is enabled or verifying. Like reconcileTwitch,
// it lists first, replaces a failed one, and holds on the cost limit.
func (s *Service) ensureTwitchApp(ctx context.Context, call twitchCall) (twitchReconcile, error) {
	var result twitchReconcile
	if err := s.checkTwitchSecret(); err != nil {
		return result, err
	}
	credentials, err := s.API.Tokens.Credentials(ctx, "twitch")
	if err != nil {
		return result, err
	}
	existing, err := listTwitch(ctx, url.Values{"type": {twitchAppType}}, call)
	if err != nil {
		return result, err
	}
	for _, sub := range existing {
		if sub.Type != twitchAppType || sub.Condition["client_id"] != credentials.ClientID || !ownCallback(sub) {
			continue
		}
		if sub.Status == "enabled" || sub.Status == "webhook_callback_verification_pending" {
			return result, nil
		}
		if err := call(ctx, http.MethodDelete, url.Values{"id": {sub.ID}}, nil, nil); err != nil && !isStatus(err, 404) {
			return result, err
		}
	}
	body := map[string]interface{}{"type": twitchAppType, "version": "1", "condition": map[string]string{"client_id": credentials.ClientID}, "transport": map[string]interface{}{"method": "webhook", "callback": TwitchCallback, "secret": s.TwitchSecret}}
	err = call(ctx, http.MethodPost, nil, body, nil)
	switch {
	case err == nil:
		result.created++
	case isStatus(err, 409):
		// Created by an attempt whose response was lost.
	case errors.As(err, new(*costLimitError)):
		result.held = append(result.held, twitchAppType)
	default:
		return result, err
	}
	return result, nil
}

func (s *Service) welcome(ctx context.Context, uid, channel, login string) error {
	messages := []string{fmt.Sprintf("Welcome to RealtimeChat, @%s! VoHiYo", login), "Your chat will appear here, even if you close the app. Have a good stream!"}
	for i, message := range messages {
		ref := s.DB.Collection("channels").Doc("twitch:" + channel).Collection("messages").Doc(fmt.Sprintf("welcome-v1-%d", i+1))
		_, err := ref.Create(ctx, map[string]interface{}{
			"channelId": "twitch:" + channel, "annotations": map[string]interface{}{"isAction": false, "isFirstTimeChatter": false}, "author": map[string]interface{}{"displayName": "muxfd", "userId": "158394109", "color": ""}, "reply": nil, "timestamp": firestore.ServerTimestamp,
			"tags": map[string]interface{}{"user-id": "158394109", "room-id": "158394109", "display-name": "muxfd", "color": "", "username": "muxfd", "badges": map[string]interface{}{}, "emotes-raw": "", "badges-raw": ""}, "type": "message", "message": message, "expiresAt": time.Now().Add(chatmessage.TTL),
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
