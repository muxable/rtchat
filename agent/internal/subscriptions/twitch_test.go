package subscriptions

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"testing"
)

// TestReconcileTwitchRecognizesEmptyConditionFields lists the subscriptions as
// Twitch does, with every condition field of the type present and the unused
// ones empty, and expects reconcile to create nothing.
func TestReconcileTwitchRecognizesEmptyConditionFields(t *testing.T) {
	var data []json.RawMessage
	for i, wanted := range twitchConditions("123") {
		condition, _ := json.Marshal(wanted.Condition)
		switch {
		case wanted.Type == "channel.raid" && wanted.Condition["to_broadcaster_user_id"] != "":
			condition = []byte(`{"from_broadcaster_user_id":"","to_broadcaster_user_id":"123"}`)
		case wanted.Type == "channel.raid":
			condition = []byte(`{"from_broadcaster_user_id":"123","to_broadcaster_user_id":""}`)
		case wanted.Type == "channel.channel_points_custom_reward_redemption.add" || wanted.Type == "channel.channel_points_custom_reward_redemption.update":
			condition = []byte(`{"broadcaster_user_id":"123","reward_id":""}`)
		}
		data = append(data, json.RawMessage(fmt.Sprintf(`{"id":"sub-%d","status":"enabled","type":%q,"version":%q,"condition":%s,"created_at":"2026-10-24T05:16:30.137Z","transport":{"method":"webhook","callback":%q},"cost":0}`, i, wanted.Type, wanted.Version, condition, TwitchCallback)))
	}
	listing, _ := json.Marshal(map[string]interface{}{"total": len(data), "data": data, "max_total_cost": 10000, "total_cost": 0, "pagination": map[string]string{}})
	var requests []string
	call := func(_ context.Context, method string, q url.Values, body, out any) error {
		requests = append(requests, method)
		if method != http.MethodGet {
			return nil
		}
		return json.Unmarshal(listing, out)
	}
	service := &Service{TwitchSecret: "dedicated-secret"}
	result, err := service.reconcileTwitch(context.Background(), "123", call)
	if err != nil || result.created != 0 || len(requests) != 1 {
		t.Fatal(err, result, requests)
	}
}

func TestSameCondition(t *testing.T) {
	for _, c := range []struct {
		a, b map[string]string
		same bool
	}{
		{map[string]string{"to_broadcaster_user_id": "1", "from_broadcaster_user_id": ""}, map[string]string{"to_broadcaster_user_id": "1"}, true},
		{map[string]string{"to_broadcaster_user_id": "", "from_broadcaster_user_id": "1"}, map[string]string{"to_broadcaster_user_id": "1"}, false},
		{map[string]string{"broadcaster_user_id": "1", "reward_id": "r"}, map[string]string{"broadcaster_user_id": "1"}, false},
		{map[string]string{"broadcaster_user_id": "1"}, map[string]string{"broadcaster_user_id": "1", "moderator_user_id": "1"}, false},
	} {
		if sameCondition(c.a, c.b) != c.same || sameCondition(c.b, c.a) != c.same {
			t.Fatal(c)
		}
	}
}
