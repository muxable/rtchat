package webhook

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"strings"
)

// alchemyDonationID uses chain activity identity instead of the notification ID:
// provider retries, new envelopes, reordered batches and duplicate subscriptions
// must resolve to the same Firestore document. A transaction can contain multiple
// distinct transfer logs/internal traces, which must remain separate messages.
func alchemyDonationID(network string, activity map[string]interface{}) string {
	if network == "" {
		network = "MATIC_MAINNET"
	} // The deployed legacy handler is Polygon-only.
	hash, _ := activity["hash"].(string)
	identity := map[string]interface{}{"network": strings.ToUpper(network), "hash": strings.ToLower(hash)}
	category, _ := activity["category"].(string)
	category = strings.ToLower(category)
	log, _ := activity["log"].(map[string]interface{})
	if index, ok := log["logIndex"]; ok && index != nil {
		identity["kind"] = "log"
		if text, ok := index.(string); ok {
			index = strings.ToLower(text)
		}
		identity["index"] = index
	} else if trace, ok := activity["typeTraceAddress"].(string); ok && trace != "" && trace != "external" && category != "external" {
		identity["kind"] = "trace"
		identity["trace"] = trace
	} else {
		// External transfers have one activity per transaction. Older token payloads
		// without a log index require transfer fields to distinguish their activities.
		identity["kind"] = category
		if category != "external" && category != "" {
			for _, key := range []string{"fromAddress", "toAddress", "erc721TokenId", "erc1155Metadata"} {
				value := activity[key]
				if text, ok := value.(string); ok {
					value = strings.ToLower(text)
				}
				identity[key] = value
			}
			contract, _ := activity["rawContract"].(map[string]interface{})
			address, _ := contract["address"].(string)
			identity["contract"] = strings.ToLower(address)
			raw := contract["rawValue"]
			if raw == nil {
				raw = contract["rawvalue"]
			}
			if raw != nil {
				identity["value"] = raw
			} else {
				identity["value"] = activity["value"]
			}
		}
	}
	// All values originated from valid JSON, so their selected primitives/maps
	// always marshal. Map keys are sorted by encoding/json for a stable digest.
	encoded, _ := json.Marshal(identity)
	digest := sha256.Sum256(encoded)
	return "alchemy-donation-" + hex.EncodeToString(digest[:])
}
