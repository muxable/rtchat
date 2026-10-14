package webhook

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"math"
	"net/http"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"go.uber.org/zap"
)

// twitchStore keeps notification mapping independent of Firestore I/O.
type twitchStore interface {
	Set(context.Context, string, map[string]interface{}, bool) error
	Update(context.Context, string, map[string]interface{}) error
	mergeBatch(context.Context, []twitchDocument) error
}

type twitchFirestoreStore struct{ client *firestore.Client }

func (s twitchFirestoreStore) Set(ctx context.Context, path string, data map[string]interface{}, merge bool) error {
	var options []firestore.SetOption
	if merge {
		options = append(options, firestore.MergeAll)
	}
	_, err := s.client.Doc(path).Set(ctx, data, options...)
	return err
}

func (s twitchFirestoreStore) Update(ctx context.Context, path string, data map[string]interface{}) error {
	updates := make([]firestore.Update, 0, len(data))
	for key, value := range data {
		updates = append(updates, firestore.Update{Path: key, Value: value})
	}
	_, err := s.client.Doc(path).Update(ctx, updates)
	return err
}

func (s twitchFirestoreStore) mergeBatch(ctx context.Context, documents []twitchDocument) error {
	if len(documents) == 0 {
		return nil
	}
	batch := s.client.Batch()
	for _, doc := range documents {
		batch.Set(s.client.Doc(doc.Path), doc.Data, firestore.MergeAll)
	}
	_, err := batch.Commit(ctx)
	return err
}

type twitchPayload struct {
	Subscription struct {
		Type    string `json:"type"`
		Version string `json:"version"`
		Status  string `json:"status"`
	} `json:"subscription"`
	Challenge *string                `json:"challenge"`
	Event     map[string]interface{} `json:"event"`
}

// Firebase's JavaScript serializer stores safe integral numbers as Firestore
// integers. Go's JSON decoder otherwise leaves every event number a double.
func decodeTwitchPayload(body []byte) (twitchPayload, error) {
	var payload twitchPayload
	if err := json.Unmarshal(body, &payload); err != nil {
		return payload, err
	}
	if payload.Event != nil {
		payload.Event = twitchFirestoreValue(payload.Event).(map[string]interface{})
	}
	return payload, nil
}

func twitchFirestoreValue(value interface{}) interface{} {
	switch value := value.(type) {
	case float64:
		const maxSafeInteger = 9007199254740991
		if math.Trunc(value) == value && math.Abs(value) <= maxSafeInteger {
			return int64(value)
		}
	case map[string]interface{}:
		data := make(map[string]interface{}, len(value))
		for key, child := range value {
			data[key] = twitchFirestoreValue(child)
		}
		return data
	case []interface{}:
		data := make([]interface{}, len(value))
		for i, child := range value {
			data[i] = twitchFirestoreValue(child)
		}
		return data
	}
	return value
}

type twitchDocument struct {
	Path        string
	Data        map[string]interface{}
	Merge       bool
	Update      bool
	IgnoreError bool
}

type twitchNotification struct {
	Documents        []twitchDocument
	RefreshChannelID string
}

// mapTwitchNotification mirrors eventsub.ts: all event types share the same
// message envelope, including types added by Twitch in the future.
func mapTwitchNotification(payload twitchPayload, messageID string, timestamp, now time.Time) (twitchNotification, error) {
	if payload.Subscription.Status != "enabled" || (payload.Subscription.Type == "channel.follow" && payload.Subscription.Version == "1") {
		return twitchNotification{}, nil
	}
	id, _ := payload.Event["broadcaster_user_id"].(string)
	if id == "" {
		id, _ = payload.Event["to_broadcaster_user_id"].(string)
	}
	if id == "" || strings.Contains(id, "/") || messageID == "" || strings.Contains(messageID, "/") || payload.Subscription.Type == "" {
		return twitchNotification{}, errors.New("invalid notification identifiers")
	}
	channelID := "twitch:" + id
	channelPath := "channels/" + channelID
	notification := twitchNotification{Documents: []twitchDocument{{
		Path: channelPath + "/messages/twitch:" + messageID,
		Data: map[string]interface{}{
			"channelId": channelID, "type": payload.Subscription.Type,
			// JavaScript Date.parse only retains millisecond precision.
			"timestamp": timestamp.Truncate(time.Millisecond),
			"expiresAt": now.Truncate(time.Millisecond).Add(14 * 24 * time.Hour),
			"event":     payload.Event,
		},
	}}}
	var data map[string]interface{}
	update := false
	switch payload.Subscription.Type {
	case "stream.online":
		data = map[string]interface{}{"onlineAt": firestore.ServerTimestamp}
		notification.RefreshChannelID = channelID
	case "stream.offline":
		data = map[string]interface{}{"onlineAt": nil}
	case "channel.follow":
		data = map[string]interface{}{"followerCount": firestore.Increment(1)}
		update = true
	case "channel.update":
		data = map[string]interface{}{
			"login": payload.Event["broadcaster_user_login"], "displayName": payload.Event["broadcaster_user_name"],
			"title": payload.Event["title"], "language": payload.Event["language"],
			"categoryId": payload.Event["category_id"], "categoryName": payload.Event["category_name"],
		}
	}
	if data != nil {
		notification.Documents = append(notification.Documents, twitchDocument{
			Path: channelPath, Data: data, Merge: !update, Update: update, IgnoreError: update,
		})
	}
	return notification, nil
}

// TwitchHandler serves only /twitch/eventsub. RefreshChannel refreshes Helix
// statistics after stream.online, just as the TypeScript callback does.
type TwitchHandler struct {
	Secret         string
	Store          twitchStore
	RefreshChannel func(context.Context, string) error
	now            func() time.Time
}

func NewTwitchHandler(secret string, client *firestore.Client, clientID, clientSecret string) *TwitchHandler {
	store := twitchFirestoreStore{client: client}
	stats := twitchStats{store: store, client: &http.Client{Timeout: 15 * time.Second}, clientID: clientID, clientSecret: clientSecret}
	return &TwitchHandler{Secret: secret, Store: store, RefreshChannel: stats.refresh, now: time.Now}
}

func verifyTwitchSignature(secret, messageID, timestamp, signature string, body []byte) bool {
	if messageID == "" || timestamp == "" || !strings.HasPrefix(signature, "sha256=") {
		return false
	}
	supplied, err := hex.DecodeString(strings.TrimPrefix(signature, "sha256="))
	if err != nil {
		return false
	}
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(messageID))
	mac.Write([]byte(timestamp))
	mac.Write(body)
	return hmac.Equal(supplied, mac.Sum(nil))
}

func (h *TwitchHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/twitch/eventsub" {
		http.NotFound(w, r)
		return
	}
	if r.Method != http.MethodPost {
		w.Header().Set("Allow", http.MethodPost)
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	if h.Secret == "" {
		w.WriteHeader(http.StatusServiceUnavailable)
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 1024*1024))
	if err != nil {
		var tooLarge *http.MaxBytesError
		if errors.As(err, &tooLarge) {
			w.WriteHeader(http.StatusRequestEntityTooLarge)
		} else {
			w.WriteHeader(http.StatusBadRequest)
		}
		return
	}
	messageID := r.Header.Get("Twitch-Eventsub-Message-Id")
	timestampHeader := r.Header.Get("Twitch-Eventsub-Message-Timestamp")
	if !verifyTwitchSignature(h.Secret, messageID, timestampHeader, r.Header.Get("Twitch-Eventsub-Message-Signature"), body) {
		w.WriteHeader(http.StatusForbidden)
		return
	}
	now := time.Now()
	if h.now != nil {
		now = h.now()
	}
	timestamp, err := time.Parse(time.RFC3339Nano, timestampHeader)
	if err != nil || now.Sub(timestamp) > 10*time.Minute {
		w.WriteHeader(http.StatusForbidden)
		return
	}
	payload, err := decodeTwitchPayload(body)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	switch r.Header.Get("Twitch-Eventsub-Message-Type") {
	case "webhook_callback_verification":
		if payload.Challenge == nil {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		io.WriteString(w, *payload.Challenge)
		return
	case "revocation":
		zap.L().Info("twitch eventsub subscription revoked", zap.String("type", payload.Subscription.Type), zap.String("status", payload.Subscription.Status))
	case "notification":
		notification, err := mapTwitchNotification(payload, messageID, timestamp, now)
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		if err := h.writeNotification(r.Context(), notification); err != nil {
			zap.L().Error("failed to process twitch eventsub", zap.String("messageId", messageID), zap.Error(err))
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
	default:
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func (h *TwitchHandler) writeNotification(ctx context.Context, notification twitchNotification) error {
	for _, doc := range notification.Documents {
		var err error
		if doc.Update {
			err = h.Store.Update(ctx, doc.Path, doc.Data)
		} else {
			err = h.Store.Set(ctx, doc.Path, doc.Data, doc.Merge)
		}
		if err != nil && !doc.IgnoreError {
			return err
		}
	}
	if notification.RefreshChannelID != "" && h.RefreshChannel != nil {
		return h.RefreshChannel(ctx, notification.RefreshChannelID)
	}
	return nil
}
