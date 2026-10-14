package webhook

import (
	"context"

	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
	"go.uber.org/zap"
)

type Secrets struct {
	KickClientID          string
	KickClientSecret      string
	TwitchEventSubSecret  string
	AlchemySigningKey     string
	AlchemyEthSigningKey  string
	AlchemyMaticWebhookID string
	AlchemyEthWebhookID   string
}

// SecretFetcher receives a full Secret Manager version resource name.
type SecretFetcher func(context.Context, string) (string, error)

// LoadSecrets reads every webhook credential from Secret Manager, which the
// deploy workflow controls. A nil fetcher uses one lazily created client.
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
		name string
		dest *string
	}{
		{"kick-client-id", &secrets.KickClientID},
		{"kick-client-secret", &secrets.KickClientSecret},
		{"twitch-eventsub-secret", &secrets.TwitchEventSubSecret},
		{"alchemy-signing-key", &secrets.AlchemySigningKey},
		{"alchemy-eth-signing-key", &secrets.AlchemyEthSigningKey},
		{"alchemy-matic-webhook-id", &secrets.AlchemyMaticWebhookID},
		{"alchemy-eth-webhook-id", &secrets.AlchemyEthWebhookID},
	} {
		value, err := fetch(ctx, "projects/rtchat-47692/secrets/"+entry.name+"/versions/latest")
		if err != nil {
			zap.L().Warn("failed to load webhook secret", zap.String("secret", entry.name), zap.Error(err))
			continue
		}
		*entry.dest = value
	}
	return secrets
}
