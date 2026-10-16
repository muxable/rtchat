package publichttp

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"os"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/auth"
	"github.com/muxable/rtchat/agent/internal/provider"
)

type FirestoreStore struct{ Client *firestore.Client }

func (s FirestoreStore) Metadata(ctx context.Context, channel string, data map[string]any) error {
	data["createdAt"] = firestore.ServerTimestamp
	_, _, err := s.Client.Collection("channels").Doc(channel).Collection("third-party").Add(ctx, data)
	return err
}

// Register uses the same Secret Manager credentials and cached app tokens as
// the callable API. Metadata remains disabled until client ownership is reviewed.
func Register(mux *http.ServeMux, db *firestore.Client, tokens *provider.Service) error {
	clients, err := ParseMetadataClients(os.Getenv("METADATA_CLIENT_IDS"))
	if err != nil {
		return err
	}
	(&Server{Store: FirestoreStore{Client: db}, TwitchClientID: auth.TwitchClientID(), AppToken: tokens.AppAccessToken, MetadataClients: clients}).Register(mux)
	return nil
}
func ParseMetadataClients(raw string) (map[string]string, error) {
	clients := map[string]string{}
	if raw == "" {
		return clients, nil
	}
	if err := json.Unmarshal([]byte(raw), &clients); err != nil {
		return nil, errors.New("METADATA_CLIENT_IDS must be a JSON object of client IDs to reviewed names")
	}
	if clients == nil {
		return nil, errors.New("metadata clients must be an object")
	}
	for id, name := range clients {
		if id == "" || name == "" {
			return nil, errors.New("metadata client ID and name must be nonempty")
		}
	}
	return clients, nil
}
