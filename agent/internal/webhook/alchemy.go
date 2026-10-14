package webhook

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"go.uber.org/zap"
)

// AlchemyConfig is loaded at startup. Webhook IDs belong to address registration;
// the notification handlers, like their TypeScript counterparts, do not filter IDs.
type AlchemyConfig struct {
	Secrets        Secrets
	MaticWebhookID string
}

// AlchemyStore captures the three Firestore operations used by the webhooks.
type AlchemyStore interface {
	FindOne(context.Context, string, string, string) (string, error)
	Get(context.Context, string) (map[string]interface{}, error)
	Add(context.Context, string, map[string]interface{}) error
}

// AlchemyTransactions fetches transaction calldata on Polygon.
type AlchemyTransactions interface {
	Input(context.Context, string) (string, error)
}

type AlchemyHandler struct {
	config       AlchemyConfig
	store        AlchemyStore
	transactions AlchemyTransactions
	now          func() time.Time
}

func NewAlchemyHandler(config AlchemyConfig, store AlchemyStore, transactions AlchemyTransactions) *AlchemyHandler {
	return &AlchemyHandler{config: config, store: store, transactions: transactions, now: time.Now}
}

func validAlchemySignature(body []byte, signature, key string) bool {
	mac := hmac.New(sha256.New, []byte(key))
	mac.Write(body)
	// Compare the lowercase hex text to preserve the TS signature format exactly.
	return hmac.Equal([]byte(signature), []byte(hex.EncodeToString(mac.Sum(nil))))
}

type alchemyNotification struct {
	WebhookID string `json:"webhookId"`
	ID        string `json:"id"`
	CreatedAt string `json:"createdAt"`
	Type      string `json:"type"`
	Event     struct {
		Activity []map[string]interface{} `json:"activity"`
	} `json:"event"`
}

func (h *AlchemyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/alchemy/webhook" {
		http.NotFound(w, r)
		return
	}
	key := h.config.Secrets.AlchemySigningKey
	if key == "" {
		http.Error(w, "Alchemy signing key unavailable", http.StatusServiceUnavailable)
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 1<<20))
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if !validAlchemySignature(body, r.Header.Get("X-Alchemy-Signature"), key) {
		w.WriteHeader(http.StatusForbidden)
		io.WriteString(w, "Fail to validate signature")
		return
	}
	var notification alchemyNotification
	decoder := json.NewDecoder(bytes.NewReader(body))
	decoder.UseNumber() // Preserve decimal text, including amounts larger than 2^53.
	if err := decoder.Decode(&notification); err != nil || notification.Event.Activity == nil {
		http.Error(w, "Invalid notification", http.StatusBadRequest)
		return
	}
	var extra interface{}
	if err := decoder.Decode(&extra); err != io.EOF {
		http.Error(w, "Invalid notification", http.StatusBadRequest)
		return
	}
	if err := h.process(r.Context(), notification); err != nil {
		zap.L().Error("alchemy webhook failed", zap.Error(err))
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}
	io.WriteString(w, "OK")
}

func (h *AlchemyHandler) process(ctx context.Context, notification alchemyNotification) error {
	for _, activity := range notification.Event.Activity {
		hash, ok := activity["hash"].(string)
		if !ok {
			return fmt.Errorf("activity missing transaction hash")
		}
		input, err := h.transactions.Input(ctx, hash)
		if err != nil {
			return err
		}
		donation, err := decodeAlchemyDonation(input)
		if err != nil {
			return err
		}
		if donation == nil {
			continue
		}
		userID, err := h.store.FindOne(ctx, "realtimecash", "address", donation.To)
		if err != nil {
			return err
		}
		profile, err := h.store.Get(ctx, "profiles/"+userID)
		if err != nil {
			return err
		}
		twitch, ok := profile["twitch"].(map[string]interface{})
		if !ok {
			return fmt.Errorf("profile %s missing twitch", userID)
		}
		id, ok := twitch["id"].(string)
		if !ok {
			return fmt.Errorf("profile %s missing twitch.id", userID)
		}
		channelID := "twitch:" + id
		now := h.now().Truncate(time.Millisecond)
		message := map[string]interface{}{
			"channelId": channelID, "webhookId": notification.WebhookID,
			"id": notification.ID, "createdAt": notification.CreatedAt,
			"type": "realtimecash.donation", "notificationType": notification.Type,
			"activity": activity, "donor": donation.Donor, "message": donation.Message,
			"timestamp": now, "expiresAt": h.now().Truncate(time.Millisecond).Add(14 * 24 * time.Hour),
		}
		if err := h.store.Add(ctx, "channels/"+channelID+"/messages", message); err != nil {
			return err
		}
	}
	return nil
}
