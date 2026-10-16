package webhook

import (
	"context"
	"encoding/json"
	"errors"
	"math/big"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"
)

type atomicAlchemyStore struct {
	mu        sync.Mutex
	documents map[string]map[string]interface{}
	failHash  string
}

func (s *atomicAlchemyStore) FindOne(context.Context, string, string, string) (string, error) {
	return "user", nil
}
func (s *atomicAlchemyStore) Get(context.Context, string) (map[string]interface{}, error) {
	return map[string]interface{}{"twitch": map[string]interface{}{"id": "123"}}, nil
}
func (s *atomicAlchemyStore) Create(_ context.Context, path, id string, data map[string]interface{}) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.documents == nil {
		s.documents = map[string]map[string]interface{}{}
	}
	if s.failHash != "" && data["activity"].(map[string]interface{})["hash"] == s.failHash {
		s.failHash = ""
		return errors.New("transient write failure")
	}
	key := path + "/" + id
	if _, exists := s.documents[key]; !exists {
		s.documents[key] = data
	}
	return nil
}

type constantAlchemyTransaction string

func (tx constantAlchemyTransaction) Input(context.Context, string) (string, error) {
	return string(tx), nil
}

func TestAlchemyConcurrentReplicasDeduplicateActivities(t *testing.T) {
	body := `{"webhookId":"webhook","id":"notification","event":{"network":"MATIC_MAINNET","activity":[{"hash":"0xone","category":"token","log":{"logIndex":"0x1","removed":false},"value":9007199254740993,"rawContract":{"rawValue":"0x20000000000001"}},{"hash":"0xone","category":"token","log":{"logIndex":"0x2","removed":false}},{"hash":"0xone","category":"internal","typeTraceAddress":"call_0_1"},{"hash":"0xtwo","category":"external"}]}}`
	store := &atomicAlchemyStore{}
	input := constantAlchemyTransaction(alchemyTestInput(big.NewInt(1), "donor", "message"))
	var wg sync.WaitGroup
	for i := 0; i < 16; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			// Distinct handlers model independent replicas, without any process-local dedup map.
			h := NewAlchemyHandler(AlchemyConfig{Secrets: Secrets{AlchemySigningKey: "key"}}, store, input)
			req := httptest.NewRequest("POST", "/alchemy/webhook", strings.NewReader(body))
			req.Header.Set("X-Alchemy-Signature", alchemyTestSignature(body, "key"))
			w := httptest.NewRecorder()
			h.ServeHTTP(w, req)
			if w.Code != 200 {
				t.Errorf("replica %d: %d %s", i, w.Code, w.Body.String())
			}
		}(i)
	}
	wg.Wait()
	if len(store.documents) != 4 {
		t.Fatalf("got %d documents", len(store.documents))
	}
	for path, data := range store.documents {
		if !strings.HasPrefix(path, "channels/twitch:123/messages/alchemy-donation-") {
			t.Fatal(path)
		}
		activity := data["activity"].(map[string]interface{})
		if value, ok := activity["value"].(json.Number); ok && value.String() != "9007199254740993" {
			t.Fatal(value)
		}
	}
}
func TestAlchemyRetryAfterPartialBatchFailure(t *testing.T) {
	notification := alchemyNotification{WebhookID: "original", ID: "first-envelope"}
	notification.Event.Network = "MATIC_MAINNET"
	notification.Event.Activity = []map[string]interface{}{{"hash": "0xfirst", "category": "external", "value": json.Number("0.1234567890123456789")}, {"hash": "0xsecond", "category": "external"}}
	store := &atomicAlchemyStore{failHash: "0xsecond"}
	input := constantAlchemyTransaction(alchemyTestInput(big.NewInt(1), "donor", "message"))
	h := NewAlchemyHandler(AlchemyConfig{}, store, input)
	first := time.Date(2026, 10, 16, 0, 0, 0, 0, time.UTC)
	h.now = func() time.Time { return first }
	if err := h.process(context.Background(), notification); err == nil || len(store.documents) != 1 {
		t.Fatalf("expected partial failure; err=%v count=%d", err, len(store.documents))
	}
	notification.ID = "new-envelope"
	notification.WebhookID = "other-subscription"
	notification.CreatedAt = "changed"
	notification.Event.Activity[0], notification.Event.Activity[1] = notification.Event.Activity[1], notification.Event.Activity[0]
	h.now = func() time.Time { return first.Add(time.Hour) }
	if err := h.process(context.Background(), notification); err != nil {
		t.Fatal(err)
	}
	if len(store.documents) != 2 {
		t.Fatalf("retry created %d documents", len(store.documents))
	}
	for _, data := range store.documents {
		activity := data["activity"].(map[string]interface{})
		if activity["hash"] == "0xfirst" {
			if data["timestamp"] != first || data["expiresAt"] != first.Add(14*24*time.Hour) || data["id"] != "first-envelope" {
				t.Fatal("retry rewrote accepted document", data)
			}
			if activity["value"].(json.Number).String() != "0.1234567890123456789" {
				t.Fatal("decimal rounded")
			}
		}
	}
}
func TestAlchemyDonationIdentity(t *testing.T) {
	first := map[string]interface{}{"hash": "0xABC", "category": "token", "value": json.Number("123"), "log": map[string]interface{}{"logIndex": "0x1", "removed": false, "blockHash": "0xold"}}
	replay := map[string]interface{}{"hash": "0xabc", "category": "token", "value": json.Number("123.0"), "log": map[string]interface{}{"logIndex": "0x1", "removed": true, "blockHash": "0xnew"}}
	id := alchemyDonationID("MATIC_MAINNET", first)
	if id != alchemyDonationID("matic_mainnet", replay) {
		t.Fatal("mutable delivery fields changed identity")
	}
	if id == alchemyDonationID("ETH_MAINNET", first) {
		t.Fatal("different networks collided")
	}
	replay["log"].(map[string]interface{})["logIndex"] = "0x2"
	if id == alchemyDonationID("MATIC_MAINNET", replay) {
		t.Fatal("distinct logs collided")
	}
	for _, category := range []string{"external", "internal", "erc20"} {
		a := map[string]interface{}{"hash": "0xhash", "category": category, "typeTraceAddress": "call_0", "fromAddress": "0xfrom", "toAddress": "0xto", "rawContract": map[string]interface{}{"address": "0xtoken", "rawValue": "0x1"}}
		b := map[string]interface{}{"hash": "0xhash", "category": category, "typeTraceAddress": "call_1", "fromAddress": "0xfrom", "toAddress": "0xto", "rawContract": map[string]interface{}{"address": "0xtoken", "rawValue": "0x2"}}
		same := alchemyDonationID("MATIC_MAINNET", a) == alchemyDonationID("MATIC_MAINNET", b)
		if same != (category == "external") {
			t.Fatalf("%s identity comparison=%v", category, same)
		}
	}
}
