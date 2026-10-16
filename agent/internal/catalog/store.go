package catalog

import (
	"context"
	"net/url"
	"sync"
	"time"

	"cloud.google.com/go/firestore"
	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
	"github.com/muxable/rtchat/agent/internal/auth"
	"github.com/muxable/rtchat/agent/internal/callable"
	"github.com/muxable/rtchat/agent/internal/provider"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type FirestoreStore struct {
	Client *firestore.Client
	Now    func() time.Time
}

func (s FirestoreStore) Profile(ctx context.Context, uid, provider string) (map[string]any, error) {
	doc, err := s.Client.Collection("profiles").Doc(uid).Get(ctx)
	if status.Code(err) == codes.NotFound {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return object(doc.Data()[provider]), nil
}
func (s FirestoreStore) BroadcasterUID(ctx context.Context, channel string) (string, error) {
	docs, err := s.Client.Collection("profiles").Where("twitch.id", "==", channel).Limit(1).Documents(ctx).GetAll()
	if err != nil {
		return "", err
	}
	if len(docs) == 0 {
		return "", nil
	}
	return docs[0].Ref.ID, nil
}
func (s FirestoreStore) CachedYouTube(ctx context.Context, key string) ([]map[string]any, bool, error) {
	doc, err := s.Client.Collection("youtube-lookups").Doc(url.QueryEscape(key)).Get(ctx)
	if status.Code(err) == codes.NotFound {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, err
	}
	var cached struct {
		Results  []map[string]any `firestore:"results"`
		CachedAt time.Time        `firestore:"cachedAt"`
	}
	if err := doc.DataTo(&cached); err != nil {
		return nil, false, err
	}
	now := time.Now()
	if s.Now != nil {
		now = s.Now()
	}
	if cached.CachedAt.IsZero() || now.Sub(cached.CachedAt) > 24*time.Hour {
		return nil, false, nil
	}
	if cached.Results == nil {
		cached.Results = []map[string]any{}
	}
	return cached.Results, true, nil
}
func (s FirestoreStore) CacheYouTube(ctx context.Context, key string, results []map[string]any) error {
	_, err := s.Client.Collection("youtube-lookups").Doc(url.QueryEscape(key)).Set(ctx, map[string]any{"results": results, "cachedAt": firestore.ServerTimestamp})
	return err
}

// Register shares refresh-token persistence and credentials with the callable API.
func Register(api *callable.Server, db *firestore.Client, tokens *provider.Service) {
	var mu sync.Mutex
	var apiKey string
	key := func(ctx context.Context) (string, error) {
		mu.Lock()
		defer mu.Unlock()
		if apiKey != "" {
			return apiKey, nil
		}
		ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
		defer cancel()
		client, err := secretmanager.NewClient(ctx)
		if err != nil {
			return "", err
		}
		defer client.Close()
		value, err := client.AccessSecretVersion(ctx, &secretmanagerpb.AccessSecretVersionRequest{Name: "projects/rtchat-47692/secrets/youtube-api-key/versions/latest"})
		if err != nil {
			return "", err
		}
		apiKey = string(value.GetPayload().GetData())
		return apiKey, nil
	}
	(&Server{Tokens: tokens, Store: FirestoreStore{Client: db}, TwitchClientID: auth.TwitchClientID(), YouTubeAPIKey: key}).Register(api)
}
