package webhook

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"math/big"
	"net/http"
	"time"

	"cloud.google.com/go/firestore"
)

// AlchemyFirestore implements the original query, profile read, and auto-ID add.
type AlchemyFirestore struct{ Client *firestore.Client }

func (s AlchemyFirestore) FindOne(ctx context.Context, collection, field, value string) (string, error) {
	iter := s.Client.Collection(collection).Where(field, "==", value).Limit(1).Documents(ctx)
	defer iter.Stop()
	doc, err := iter.Next()
	if err != nil {
		return "", fmt.Errorf("find recipient %s: %w", value, err)
	}
	return doc.Ref.ID, nil
}

func (s AlchemyFirestore) Get(ctx context.Context, path string) (map[string]interface{}, error) {
	doc, err := s.Client.Doc(path).Get(ctx)
	if err != nil {
		return nil, err
	}
	return doc.Data(), nil
}

func (s AlchemyFirestore) Add(ctx context.Context, path string, data map[string]interface{}) error {
	value, err := alchemyFirestoreValue(data)
	if err != nil {
		return err
	}
	_, _, err = s.Client.Collection(path).Add(ctx, value)
	return err
}

// Firestore has only int64 and IEEE-754 double numeric fields. Keep JSON numbers
// exact until this serialization boundary, then match the Node SDK's safe integer
// vs double encoding. No token/wei arithmetic uses floating point.
func alchemyFirestoreValue(value interface{}) (interface{}, error) {
	switch value := value.(type) {
	case json.Number:
		number, ok := new(big.Rat).SetString(string(value))
		if !ok {
			return nil, fmt.Errorf("invalid JSON number %q", value)
		}
		encoded, _ := number.Float64()
		// JSON.parse in Node rounds to double before Firestore selects a field type.
		rounded := new(big.Rat).SetFloat64(encoded)
		if rounded != nil && rounded.IsInt() && rounded.Num().IsInt64() {
			integer := rounded.Num().Int64()
			if integer >= -9007199254740991 && integer <= 9007199254740991 {
				return integer, nil
			}
		}
		return encoded, nil
	case map[string]interface{}:
		result := make(map[string]interface{}, len(value))
		for key, entry := range value {
			converted, err := alchemyFirestoreValue(entry)
			if err != nil {
				return nil, err
			}
			result[key] = converted
		}
		return result, nil
	case []interface{}:
		result := make([]interface{}, len(value))
		for i, entry := range value {
			converted, err := alchemyFirestoreValue(entry)
			if err != nil {
				return nil, err
			}
			result[i] = converted
		}
		return result, nil
	default:
		return value, nil
	}
}

const alchemyPolygonRPC = "https://polygon-mainnet.infura.io/v3/44f12a91c4c146ae83472b2656b4fff6"

// AlchemyRPC uses the same Infura endpoint as the TypeScript functions.
type AlchemyRPC struct {
	Client     *http.Client
	PolygonURL string
}

func NewAlchemyRPC() *AlchemyRPC {
	return &AlchemyRPC{Client: &http.Client{Timeout: 30 * time.Second}, PolygonURL: alchemyPolygonRPC}
}

func (rpc *AlchemyRPC) Input(ctx context.Context, hash string) (string, error) {
	body, err := json.Marshal(struct {
		JSONRPC string   `json:"jsonrpc"`
		ID      int      `json:"id"`
		Method  string   `json:"method"`
		Params  []string `json:"params"`
	}{"2.0", 1, "eth_getTransactionByHash", []string{hash}})
	if err != nil {
		return "", err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, rpc.PolygonURL, bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	response, err := rpc.Client.Do(req)
	if err != nil {
		return "", err
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return "", fmt.Errorf("Infura HTTP status %d", response.StatusCode)
	}
	var result struct {
		Result *struct {
			Input string `json:"input"`
		} `json:"result"`
		Error *struct {
			Code    int    `json:"code"`
			Message string `json:"message"`
		} `json:"error"`
	}
	if err := json.NewDecoder(response.Body).Decode(&result); err != nil {
		return "", err
	}
	if result.Error != nil {
		return "", fmt.Errorf("Infura RPC error %d: %s", result.Error.Code, result.Error.Message)
	}
	if result.Result == nil {
		return "", fmt.Errorf("transaction %s not found", hash)
	}
	return result.Result.Input, nil
}
