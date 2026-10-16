package publichttp

import (
	"context"
	"os"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
)

func TestMetadataFirestoreSchema(t *testing.T) {
	if os.Getenv("FIRESTORE_EMULATOR_HOST") == "" {
		t.Skip("requires Firestore emulator")
	}
	ctx := context.Background()
	client, err := firestore.NewClient(ctx, "demo-http-utilities")
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	store := FirestoreStore{Client: client}
	channel := "twitch:123"
	data := map[string]any{"key": "speed", "value": float64(0), "clientId": "reviewed", "name": "App"}
	if err := store.Metadata(ctx, channel, data); err != nil {
		t.Fatal(err)
	}
	docs, err := client.Collection("channels").Doc(channel).Collection("third-party").Where("clientId", "==", "reviewed").Documents(ctx).GetAll()
	if err != nil {
		t.Fatal(err)
	}
	if len(docs) == 0 {
		t.Fatal("missing metadata write")
	}
	for _, doc := range docs {
		defer doc.Ref.Delete(ctx)
		actual := doc.Data()
		if actual["key"] != "speed" || actual["value"] != float64(0) || actual["name"] != "App" {
			t.Fatalf("incorrect schema %+v", actual)
		}
		if timestamp, ok := actual["createdAt"].(time.Time); !ok || time.Since(timestamp) > time.Minute {
			t.Fatal("missing server timestamp")
		}
	}
}
