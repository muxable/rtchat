package webhook

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"testing"
	"time"
)

func alchemyTestSignature(body, key string) string {
	mac := hmac.New(sha256.New, []byte(key))
	mac.Write([]byte(body))
	return hex.EncodeToString(mac.Sum(nil))
}

func TestAlchemySignature(t *testing.T) {
	body := "{\n  \"test\":true\n}"
	signature := alchemyTestSignature(body, "secret")
	for _, tc := range []struct {
		name, body, signature, key string
		valid                      bool
	}{
		{"valid", body, signature, "secret", true},
		{"changed whitespace", `{"test":true}`, signature, "secret", false},
		{"wrong key", body, signature, "other", false},
		{"missing", body, "", "secret", false},
		{"uppercase", body, strings.ToUpper(signature), "secret", false},
		{"malformed", body, "xyz", "secret", false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if got := validAlchemySignature([]byte(tc.body), tc.signature, tc.key); got != tc.valid {
				t.Fatalf("valid = %v", got)
			}
		})
	}
	// Independent HMAC-SHA256 vector.
	if !validAlchemySignature([]byte("The quick brown fox jumps over the lazy dog"), "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8", "key") {
		t.Fatal("HMAC vector failed")
	}
}

func alchemyTestInput(amount *big.Int, donor, message string) string {
	word := func(n *big.Int) string { return fmt.Sprintf("%064x", n) }
	stringArg := func(s string) string {
		encoded := hex.EncodeToString([]byte(s))
		return word(big.NewInt(int64(len([]byte(s))))) + encoded + strings.Repeat("0", (64-len(encoded)%64)%64)
	}
	donorArg := stringArg(donor)
	return "0x98701e4c" + strings.Repeat("0", 24) + strings.Repeat("ab", 20) + word(amount) + word(big.NewInt(128)) + word(big.NewInt(int64(128+len(donorArg)/2))) + donorArg + stringArg(message)
}

type alchemyFakeStore struct {
	calls    []string
	messages []map[string]interface{}
	failAt   string
	ids      map[string]bool
}

func (s *alchemyFakeStore) FindOne(_ context.Context, collection, field, value string) (string, error) {
	s.calls = append(s.calls, collection+" where "+field+" == "+value+" limit 1")
	if s.failAt == "query" {
		return "", errors.New("no recipient")
	}
	return "user", nil
}
func (s *alchemyFakeStore) Get(_ context.Context, path string) (map[string]interface{}, error) {
	s.calls = append(s.calls, path)
	if s.failAt == "profile" {
		return nil, errors.New("profile unavailable")
	}
	if s.failAt == "twitch" {
		return map[string]interface{}{}, nil
	}
	return map[string]interface{}{"twitch": map[string]interface{}{"id": "123"}}, nil
}
func (s *alchemyFakeStore) Create(_ context.Context, path, id string, data map[string]interface{}) error {
	s.calls = append(s.calls, path)
	if s.failAt == "write" {
		return errors.New("write unavailable")
	}
	if s.ids == nil {
		s.ids = map[string]bool{}
	}
	if s.ids[path+"/"+id] {
		return nil
	}
	s.ids[path+"/"+id] = true
	s.messages = append(s.messages, data)
	return nil
}

type alchemyFakeTransactions struct {
	input  string
	hashes []string
	err    error
}

func (tx *alchemyFakeTransactions) Input(_ context.Context, hash string) (string, error) {
	tx.hashes = append(tx.hashes, hash)
	return tx.input, tx.err
}

func TestAlchemyRoutes(t *testing.T) {
	amount := new(big.Int).Sub(new(big.Int).Lsh(big.NewInt(1), 256), big.NewInt(1))
	for _, tc := range []struct {
		name, path, network, category string
	}{
		{"polygon", "/alchemy/webhook", "MATIC_MAINNET", "external"},
		{"polygon erc20", "/alchemy/webhook", "MATIC_MAINNET", "erc20"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			body := fmt.Sprintf(`{"webhookId":"unfiltered-id","id":"notification","createdAt":"2023-05-01T00:00:00Z","type":"ADDRESS_ACTIVITY","event":{"network":%q,"activity":[{"category":%q,"fromAddress":"0xsender","toAddress":"0xcontract","blockNum":"0x10","value":0.1234567890123456789,"hash":"0xhash","typeTraceAddress":"external","asset":"TOKEN","rawContract":{"rawvalue":"0xffffffffffffffffffffffffffffffff","address":"0xtoken","decimal":18},"log":{"removed":true,"address":"0xtoken","data":"0x00","topics":["0x01"]}}]}}`, tc.network, tc.category)
			store := &alchemyFakeStore{}
			tx := &alchemyFakeTransactions{input: alchemyTestInput(amount, "Alice 🌍", "Thanks!")}
			secrets := Secrets{AlchemySigningKey: "matic-key"}
			h := NewAlchemyHandler(AlchemyConfig{Secrets: secrets, MaticWebhookID: "configured-matic"}, store, tx)
			now := time.Date(2023, 5, 1, 12, 0, 0, 123000000, time.UTC)
			h.now = func() time.Time { return now }
			server := NewServer(secrets)
			server.RegisterProvider("/alchemy/", h)
			req := httptest.NewRequest("POST", tc.path, strings.NewReader(body))
			req.Header.Set("X-Alchemy-Signature", alchemyTestSignature(body, "matic-key"))
			response := httptest.NewRecorder()
			server.Mux.ServeHTTP(response, req)
			if response.Code != 200 || response.Body.String() != "OK" {
				t.Fatalf("response %d %s", response.Code, response.Body)
			}
			if !reflect.DeepEqual(tx.hashes, []string{"0xhash"}) {
				t.Fatalf("RPC calls: %+v", tx)
			}
			expectedCalls := []string{"realtimecash where address == 0x" + strings.Repeat("ab", 20) + " limit 1", "profiles/user", "channels/twitch:123/messages"}
			if !reflect.DeepEqual(store.calls, expectedCalls) {
				t.Fatalf("calls: %v", store.calls)
			}
			var notification alchemyNotification
			decoder := json.NewDecoder(strings.NewReader(body))
			decoder.UseNumber()
			if err := decoder.Decode(&notification); err != nil {
				t.Fatal(err)
			}
			expected := map[string]interface{}{
				"channelId": "twitch:123", "webhookId": "unfiltered-id", "id": "notification", "createdAt": "2023-05-01T00:00:00Z",
				"type": "realtimecash.donation", "notificationType": "ADDRESS_ACTIVITY", "activity": notification.Event.Activity[0],
				"donor": "Alice 🌍", "message": "Thanks!", "timestamp": now, "expiresAt": now.Add(14 * 24 * time.Hour),
			}
			if len(store.messages) != 1 || !reflect.DeepEqual(store.messages[0], expected) {
				t.Fatalf("messages: %#v", store.messages)
			}
		})
	}
}

func TestAlchemyFailuresAndNonDonations(t *testing.T) {
	body := `{"event":{"activity":[{"hash":"0xhash"}]}}`
	for _, tc := range []struct {
		name, path, key, signature, body, input, failAt string
		rpcError                                        bool
		status, writes                                  int
	}{
		{name: "disabled polygon", path: "/alchemy/webhook", status: 503},
		{name: "removed eth route", path: "/alchemy/eth", key: "key", signature: "sign", body: body, status: 404},
		{name: "missing signature", path: "/alchemy/webhook", key: "key", body: body, status: 403},
		{name: "wrong signature", path: "/alchemy/webhook", key: "key", signature: "bad", body: body, status: 403},
		{name: "bad JSON", path: "/alchemy/webhook", key: "key", signature: "sign", body: `{`, status: 400},
		{name: "trailing JSON", path: "/alchemy/webhook", key: "key", signature: "sign", body: body + `{}`, status: 400},
		{name: "unknown route", path: "/alchemy/other", status: 404},
		{name: "empty", path: "/alchemy/webhook", key: "key", signature: "sign", body: `{"event":{"activity":[]}}`, status: 200},
		{name: "getBalance", path: "/alchemy/webhook", key: "key", signature: "sign", body: body, input: "0x12065fe0", status: 200},
		{name: "myAddress", path: "/alchemy/webhook", key: "key", signature: "sign", body: body, input: "0x26b85ee1", status: 200},
		{name: "unknown selector", path: "/alchemy/webhook", key: "key", signature: "sign", body: body, input: "0xdeadbeef", status: 500},
		{name: "RPC failure", path: "/alchemy/webhook", key: "key", signature: "sign", body: body, rpcError: true, status: 500},
		{name: "missing recipient", path: "/alchemy/webhook", key: "key", signature: "sign", body: body, failAt: "query", status: 500},
		{name: "missing profile", path: "/alchemy/webhook", key: "key", signature: "sign", body: body, failAt: "profile", status: 500},
		{name: "missing twitch", path: "/alchemy/webhook", key: "key", signature: "sign", body: body, failAt: "twitch", status: 500},
		{name: "write failure", path: "/alchemy/webhook", key: "key", signature: "sign", body: body, failAt: "write", status: 500},
	} {
		t.Run(tc.name, func(t *testing.T) {
			store := &alchemyFakeStore{failAt: tc.failAt}
			input := tc.input
			if input == "" {
				input = alchemyTestInput(big.NewInt(1), "donor", "message")
			}
			tx := &alchemyFakeTransactions{input: input}
			if tc.rpcError {
				tx.err = errors.New("RPC unavailable")
			}
			h := NewAlchemyHandler(AlchemyConfig{Secrets: Secrets{AlchemySigningKey: tc.key}}, store, tx)
			req := httptest.NewRequest("POST", tc.path, strings.NewReader(tc.body))
			signature := tc.signature
			if signature == "sign" {
				signature = alchemyTestSignature(tc.body, tc.key)
			}
			req.Header.Set("X-Alchemy-Signature", signature)
			response := httptest.NewRecorder()
			h.ServeHTTP(response, req)
			if response.Code != tc.status || len(store.messages) != tc.writes {
				t.Fatalf("response %d, writes %d", response.Code, len(store.messages))
			}
			if tc.status == 403 || tc.status == 404 || tc.status == 503 {
				if len(tx.hashes) != 0 || len(store.calls) != 0 {
					t.Fatal("I/O before authentication")
				}
			}
		})
	}
}

func TestAlchemyABI(t *testing.T) {
	maximum := new(big.Int).Sub(new(big.Int).Lsh(big.NewInt(1), 256), big.NewInt(1))
	for _, amount := range []*big.Int{big.NewInt(0), big.NewInt(1000000000000000000), maximum} {
		donation, err := decodeAlchemyDonation(alchemyTestInput(amount, "", "中文"))
		if err != nil || donation.Amount.Cmp(amount) != 0 || donation.Donor != "" || donation.Message != "中文" {
			t.Fatalf("decode: %+v %v", donation, err)
		}
	}
	valid := alchemyTestInput(maximum, "donor", "message")
	for _, input := range []string{"0x", "0xzzzzzzzz", "0x98701e4c", valid[:len(valid)-64], valid[:138] + strings.Repeat("f", 64) + valid[202:]} {
		if _, err := decodeAlchemyDonation(input); err == nil {
			t.Fatalf("accepted malformed input %s", input)
		}
	}
}

type alchemyRoundTripper func(*http.Request) (*http.Response, error)

func (f alchemyRoundTripper) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func TestAlchemyRPC(t *testing.T) {
	for _, tc := range []struct {
		name, body string
		status     int
		wantError  bool
	}{
		{"success", `{"jsonrpc":"2.0","id":1,"result":{"input":"0x98701e4c"}}`, 200, false},
		{"not found", `{"result":null}`, 200, true},
		{"RPC error", `{"error":{"code":-32000,"message":"unavailable"}}`, 200, true},
		{"HTTP error", `unavailable`, 503, true},
		{"bad JSON", `{`, 200, true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var paths []string
			client := &http.Client{Transport: alchemyRoundTripper(func(r *http.Request) (*http.Response, error) {
				paths = append(paths, r.URL.Path)
				var request struct {
					JSONRPC string   `json:"jsonrpc"`
					ID      int      `json:"id"`
					Method  string   `json:"method"`
					Params  []string `json:"params"`
				}
				if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
					t.Error(err)
				}
				if r.Method != "POST" || r.Header.Get("Content-Type") != "application/json" || request.JSONRPC != "2.0" || request.ID != 1 || request.Method != "eth_getTransactionByHash" || !reflect.DeepEqual(request.Params, []string{"0xhash"}) {
					t.Errorf("request: %+v", request)
				}
				return &http.Response{StatusCode: tc.status, Body: io.NopCloser(strings.NewReader(tc.body)), Header: make(http.Header)}, nil
			})}
			rpc := &AlchemyRPC{Client: client, PolygonURL: "https://infura.test/polygon"}
			input, err := rpc.Input(context.Background(), "0xhash")
			if (err != nil) != tc.wantError || (!tc.wantError && input != "0x98701e4c") {
				t.Fatalf("input %q, error %v", input, err)
			}
			if !reflect.DeepEqual(paths, []string{"/polygon"}) {
				t.Fatalf("paths: %v", paths)
			}
		})
	}
}

func TestAlchemyFirestoreNumbers(t *testing.T) {
	for _, tc := range []struct {
		input    string
		expected interface{}
	}{
		{"18", int64(18)}, {"1e3", int64(1000)}, {"1.0000000000000001", int64(1)}, {"9007199254740991", int64(9007199254740991)},
		{"0.125", 0.125}, {"9007199254740993", float64(9007199254740992)},
	} {
		t.Run(tc.input, func(t *testing.T) {
			value, err := alchemyFirestoreValue(map[string]interface{}{"nested": []interface{}{json.Number(tc.input), "0xffff", nil}})
			expected := map[string]interface{}{"nested": []interface{}{tc.expected, "0xffff", nil}}
			if err != nil || !reflect.DeepEqual(value, expected) {
				t.Fatalf("value %#v, err %v", value, err)
			}
		})
	}
}

func TestAlchemyMultipleActivitiesAndRetries(t *testing.T) {
	notification := alchemyNotification{WebhookID: "webhook", ID: "notification"}
	notification.Event.Activity = []map[string]interface{}{{"hash": "0xfirst"}, {"hash": "0xsecond"}}
	store := &alchemyFakeStore{}
	tx := &alchemyFakeTransactions{input: alchemyTestInput(big.NewInt(1), "donor", "message")}
	h := NewAlchemyHandler(AlchemyConfig{}, store, tx)
	// The managed handler preserves each distinct activity exactly once across retries.
	for i := 0; i < 2; i++ {
		if err := h.process(context.Background(), notification); err != nil {
			t.Fatal(err)
		}
	}
	if len(store.messages) != 2 || !reflect.DeepEqual(tx.hashes, []string{"0xfirst", "0xsecond", "0xfirst", "0xsecond"}) {
		t.Fatalf("writes %d, hashes %v", len(store.messages), tx.hashes)
	}
}
