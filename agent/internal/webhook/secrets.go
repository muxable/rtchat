package webhook

import (
	"context"
	"os"

	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
	"go.uber.org/zap"
)

type Secrets struct {
	KickClientID         string
	KickClientSecret     string
	TwitchEventSubSecret string
	AlchemySigningKey    string
	AlchemyEthSigningKey string
}

// SecretFetcher receives a full Secret Manager version resource name.
type SecretFetcher func(context.Context, string) (string, error)

// LoadSecrets prefers environment overrides (including explicitly empty ones).
// A nil fetcher uses one lazily created Secret Manager client for all reads.
// Failures leave the affected credentials empty so startup can continue.
func LoadSecrets(ctx context.Context, fetch SecretFetcher) Secrets {
	var client *secretmanager.Client
	var clientErr error
	var attempted bool
	if fetch == nil {
		fetch = func(ctx context.Context, name string) (string, error) {
			if !attempted {
				attempted = true
				client, clientErr = secretmanager.NewClient(ctx)
			}
			if clientErr != nil {
				return "", clientErr
			}
			result, err := client.AccessSecretVersion(ctx, &secretmanagerpb.AccessSecretVersionRequest{Name: name})
			if err != nil {
				return "", err
			}
			return string(result.GetPayload().GetData()), nil
		}
		defer func() {
			if client != nil {
				client.Close()
			}
		}()
	}

	var secrets Secrets
	for _, entry := range []struct {
		env  string
		name string
		dest *string
	}{
		{"KICK_CLIENT_ID", "kick-client-id", &secrets.KickClientID},
		{"KICK_CLIENT_SECRET", "kick-client-secret", &secrets.KickClientSecret},
		{"TWITCH_EVENTSUB_SECRET", "twitch-eventsub-secret", &secrets.TwitchEventSubSecret},
		{"ALCHEMY_SIGNING_KEY", "alchemy-signing-key", &secrets.AlchemySigningKey},
		{"ALCHEMY_ETH_SIGNING_KEY", "alchemy-eth-signing-key", &secrets.AlchemyEthSigningKey},
	} {
		if value, ok := os.LookupEnv(entry.env); ok {
			*entry.dest = value
			continue
		}
		value, err := fetch(ctx, "projects/rtchat-47692/secrets/"+entry.name+"/versions/latest")
		if err != nil {
			zap.L().Warn("failed to load webhook secret", zap.String("secret", entry.name), zap.Error(err))
			continue
		}
		*entry.dest = value
	}
	return secrets
}
