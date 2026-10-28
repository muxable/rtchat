package webhook

import (
	"context"
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"math"
	"net/http"
	"reflect"
	"strconv"
	"strings"
	"sync"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/chatmetrics"
	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const kickPublicKeyURL = "https://api.kick.com/public/v1/public-key"

// KickDelivery contains the webhook headers and the decoded, unmodified event.
type KickDelivery struct {
	MessageID string
	Timestamp string
	Type      string
	Version   string
	Event     interface{}
}

type KickMessageDoc struct {
	ID   string
	Data map[string]interface{}
}

type KickDocuments struct {
	ChannelID string
	Messages  []KickMessageDoc
	Channel   map[string]interface{}
}

func kickObject(value interface{}) map[string]interface{} {
	object, _ := value.(map[string]interface{})
	return object
}

// Kick's JSON numbers are decoded as float64, matching JavaScript Number and
// preserving numeric values in the event instead of converting IDs to strings.
func kickTruthy(value interface{}) bool {
	switch v := value.(type) {
	case nil:
		return false
	case bool:
		return v
	case string:
		return v != ""
	case float64:
		return v != 0
	default:
		return true
	}
}

func kickString(value interface{}) string {
	if number, ok := value.(float64); ok {
		return strconv.FormatFloat(number, 'f', -1, 64)
	}
	return fmt.Sprint(value)
}

func kickTimestamp(value interface{}) (time.Time, error) {
	text, ok := value.(string)
	if !ok {
		return time.Time{}, fmt.Errorf("kick: invalid timestamp %v", value)
	}
	at, err := time.Parse(time.RFC3339Nano, text)
	if err != nil {
		return time.Time{}, err
	}
	// Firebase's Timestamp.fromMillis(Date.parse(...)) has millisecond precision.
	return at.UTC().Truncate(time.Millisecond), nil
}

// KickToDocuments is pure: time.Time values are encoded by the Go Firestore
// client as timestamps; dates inside Event remain the original JSON strings.
// A nil result means the delivery has no broadcaster.
func KickToDocuments(delivery KickDelivery, now time.Time) (*KickDocuments, error) {
	event := kickObject(delivery.Event)
	broadcaster := kickObject(event["broadcaster"])
	if broadcaster["user_id"] == nil {
		return nil, nil
	}
	docs := &KickDocuments{
		ChannelID: "kick:" + kickString(broadcaster["user_id"]),
		Messages:  []KickMessageDoc{},
		Channel:   map[string]interface{}{},
	}
	id := "kick:" + delivery.MessageID
	messageType := "kick." + delivery.Type
	at := event["created_at"]
	switch delivery.Type {
	case "chat.message.sent":
		messageID, exists := event["message_id"]
		if !exists {
			id = "kick:undefined"
		} else if messageID == nil {
			id = "kick:null"
		} else {
			id = "kick:" + kickString(messageID)
		}
	case "livestream.status.updated":
		if kickTruthy(event["is_live"]) {
			messageType = "stream.online"
			at = event["started_at"]
			onlineAt, err := kickTimestamp(at)
			if err != nil {
				return nil, err
			}
			docs.Channel["onlineAt"] = onlineAt
		} else {
			messageType = "stream.offline"
			at = event["ended_at"]
			docs.Channel["onlineAt"] = nil
		}
		if kickTruthy(event["title"]) {
			docs.Channel["title"] = event["title"]
		}
	case "livestream.metadata.updated":
		metadata := kickObject(event["metadata"])
		category := kickObject(metadata["category"])
		docs.Channel["title"] = metadata["title"]
		docs.Channel["language"] = metadata["language"]
		docs.Channel["categoryId"] = category["id"]
		docs.Channel["categoryName"] = category["name"]
	case "channel.followed":
		at = nil // Follows use the delivery time and do not increment followerCount.
	case "channel.subscription.new", "channel.subscription.renewal", "channel.subscription.gifts", "kicks.gifted":
		// These events use created_at, as do unknown future events.
	case "moderation.banned":
		at = kickObject(event["metadata"])["created_at"]
	case "channel.reward.redemption.updated":
		at = event["redeemed_at"]
	}
	if delivery.Type != "livestream.metadata.updated" {
		if at == nil {
			at = delivery.Timestamp
		}
		timestamp, err := kickTimestamp(at)
		if err != nil {
			return nil, err
		}
		docs.Messages = append(docs.Messages, KickMessageDoc{ID: id, Data: map[string]interface{}{
			"channelId": docs.ChannelID,
			"type":      messageType,
			"timestamp": timestamp,
			"expiresAt": now.UTC().Truncate(time.Millisecond).Add(messageTTLFor(messageType)),
			"event":     delivery.Event,
		}})
	}
	if kickTruthy(broadcaster["channel_slug"]) {
		docs.Channel["login"] = broadcaster["channel_slug"]
		docs.Channel["displayName"] = broadcaster["username"]
	}
	return docs, nil
}

// VerifyKickSignature verifies RSA PKCS#1 v1.5/SHA-256 over the raw body, without
// decoding or re-encoding JSON. Invalid keys and signatures return false.
func VerifyKickSignature(publicKeyPEM, messageID, timestamp string, body []byte, signature string) bool {
	block, _ := pem.Decode([]byte(publicKeyPEM))
	if block == nil {
		return false
	}
	key, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		return false
	}
	publicKey, ok := key.(*rsa.PublicKey)
	if !ok {
		return false
	}
	signed, err := base64.StdEncoding.DecodeString(signature)
	if err != nil {
		return false
	}
	hash := sha256.New()
	hash.Write([]byte(messageID + "." + timestamp + "."))
	hash.Write(body)
	return rsa.VerifyPKCS1v15(publicKey, crypto.SHA256, hash.Sum(nil), signed) == nil
}

// KickStore isolates Firestore I/O so deliveries can be tested without GCP.
type KickStore interface {
	CreateMessage(context.Context, string, string, map[string]interface{}) error
	MergeChannel(context.Context, string, map[string]interface{}) error
}

type kickFirestoreStore struct{ client *firestore.Client }

func NewKickFirestoreStore(client *firestore.Client) KickStore {
	return &kickFirestoreStore{client: client}
}

func (s *kickFirestoreStore) CreateMessage(ctx context.Context, channelID, messageID string, data map[string]interface{}) error {
	_, err := s.client.Collection("channels").Doc(channelID).Collection("messages").Doc(messageID).Create(ctx, kickFirestoreData(data))
	return err
}

func (s *kickFirestoreStore) MergeChannel(ctx context.Context, channelID string, data map[string]interface{}) error {
	ref := s.client.Collection("channels").Doc(channelID)
	update := kickFirestoreData(data)
	return s.client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		doc, err := tx.Get(ref)
		if err != nil && status.Code(err) != codes.NotFound {
			return err
		}
		if err == nil {
			// Chat deliveries repeat the broadcaster's name on every message.
			// Avoid contending with metadata polls for an unchanged channel doc.
			current := doc.Data()
			unchanged := true
			for field, value := range update {
				existing, ok := current[field]
				if !ok || !reflect.DeepEqual(existing, value) {
					unchanged = false
					break
				}
			}
			if unchanged {
				return nil
			}
		}
		return tx.Set(ref, update, firestore.MergeAll)
	})
}

// The Node Firestore SDK encodes safe integer Numbers as integerValue. Go's
// JSON decoder produces float64, which Firestore otherwise encodes as doubles.
func kickFirestoreValue(value interface{}) interface{} {
	switch v := value.(type) {
	case float64:
		if math.Abs(v) <= 9007199254740991 && math.Trunc(v) == v && !(v == 0 && math.Signbit(v)) {
			return int64(v)
		}
	case map[string]interface{}:
		return kickFirestoreData(v)
	case []interface{}:
		result := make([]interface{}, len(v))
		for i, item := range v {
			result[i] = kickFirestoreValue(item)
		}
		return result
	}
	return value
}

func kickFirestoreData(data map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{}, len(data))
	for key, value := range data {
		result[key] = kickFirestoreValue(value)
	}
	return result
}

type KickHandler struct {
	store        KickStore
	client       *http.Client
	publicKeyURL string
	now          func() time.Time
	mu           sync.Mutex
	publicKey    string
	fetchedAt    time.Time
}

// kickKeyRefreshInterval limits refetching the public key after a signature
// mismatch, so forged requests can't hammer Kick's endpoint.
const kickKeyRefreshInterval = time.Minute

// kickMaxBodyBytes bounds a delivery's body; real events are a few KB.
const kickMaxBodyBytes = 1 << 20

const kickPersistenceTimeout = 10 * time.Second

// The public-key endpoint does not require the optional Kick client credentials.
func NewKickHandler(store KickStore) *KickHandler {
	return &KickHandler{store: store, client: &http.Client{Timeout: 10 * time.Second}, publicKeyURL: kickPublicKeyURL, now: time.Now}
}

func (h *KickHandler) getPublicKey(ctx context.Context, refresh bool) (string, error) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.publicKey != "" && (!refresh || h.now().Sub(h.fetchedAt) < kickKeyRefreshInterval) {
		return h.publicKey, nil
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, h.publicKeyURL, nil)
	if err != nil {
		return "", err
	}
	response, err := h.client.Do(req)
	if err != nil {
		return "", err
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		return "", fmt.Errorf("failed to fetch kick public key: %d", response.StatusCode)
	}
	var body struct {
		Data struct {
			PublicKey string `json:"public_key"`
		} `json:"data"`
	}
	if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
		return "", err
	}
	if body.Data.PublicKey == "" {
		return "", fmt.Errorf("kick public key response has no key")
	}
	h.publicKey = body.Data.PublicKey
	h.fetchedAt = h.now()
	return h.publicKey, nil
}

func (h *KickHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	delivery := KickDelivery{
		MessageID: r.Header.Get("kick-event-message-id"),
		Timestamp: r.Header.Get("kick-event-message-timestamp"),
		Type:      r.Header.Get("kick-event-type"),
		Version:   r.Header.Get("kick-event-version"),
	}
	signature := r.Header.Get("kick-event-signature")
	if delivery.MessageID == "" || delivery.Timestamp == "" || signature == "" {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, kickMaxBodyBytes))
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	verified := false
	for _, refresh := range []bool{false, true} {
		key, err := h.getPublicKey(r.Context(), refresh)
		if err != nil {
			h.fail(w, r, delivery, "fetch public key", err)
			return
		}
		if VerifyKickSignature(key, delivery.MessageID, delivery.Timestamp, body, signature) {
			verified = true
			break
		}
	}
	if !verified {
		zap.L().Warn("kick webhook signature mismatch", zap.String("messageId", delivery.MessageID))
		w.WriteHeader(http.StatusForbidden)
		return
	}
	if err := json.Unmarshal(body, &delivery.Event); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	docs, err := KickToDocuments(delivery, h.now())
	if err != nil {
		h.fail(w, r, delivery, "map event", err)
		return
	}
	if docs == nil {
		zap.L().Warn("kick webhook without broadcaster", zap.String("messageId", delivery.MessageID), zap.String("type", delivery.Type))
		w.WriteHeader(http.StatusOK)
		return
	}
	switch delivery.Type {
	case "chat.message.sent", "livestream.status.updated", "livestream.metadata.updated",
		"channel.followed", "channel.subscription.new", "channel.subscription.renewal",
		"channel.subscription.gifts", "kicks.gifted", "moderation.banned", "channel.reward.redemption.updated":
	default:
		zap.L().Info("unhandled kick event", zap.String("type", delivery.Type))
	}
	// Once a delivery is verified, finish its idempotent writes even if the
	// sender disconnects. Keep the work synchronous and bounded for shutdown.
	ctx, cancel := context.WithTimeout(context.WithoutCancel(r.Context()), kickPersistenceTimeout)
	defer cancel()
	for _, message := range docs.Messages {
		err := h.store.CreateMessage(ctx, docs.ChannelID, message.ID, message.Data)
		chatmetrics.Record("kick", kickKind(message.Data["type"].(string)), chatmetrics.OutcomeOf(err))
		if err != nil && status.Code(err) != codes.AlreadyExists {
			h.fail(w, r, delivery, "create message", err)
			return
		}
	}
	if len(docs.Channel) > 0 {
		if err := h.store.MergeChannel(ctx, docs.ChannelID, docs.Channel); err != nil {
			h.fail(w, r, delivery, "merge channel", err)
			return
		}
	}
	w.WriteHeader(http.StatusOK)
}

// kickKind labels chat events like the other providers: chat messages are
// "message", everything else keeps its document type.
func kickKind(documentType string) string {
	if documentType == "kick.chat.message.sent" {
		return "message"
	}
	return strings.TrimPrefix(documentType, "kick.")
}

func (h *KickHandler) fail(w http.ResponseWriter, r *http.Request, delivery KickDelivery, operation string, err error) {
	zap.L().Error("kick webhook "+operation+" failed",
		zap.Error(err),
		zap.String("method", r.Method),
		zap.String("path", r.URL.Path),
		zap.Int("status", http.StatusInternalServerError),
		zap.String("messageId", delivery.MessageID),
		zap.String("type", delivery.Type),
		zap.String("operation", operation),
		zap.Bool("request_canceled", r.Context().Err() != nil),
	)
	w.WriteHeader(http.StatusInternalServerError)
}
