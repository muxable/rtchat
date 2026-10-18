package callable

import (
	"context"
	firebase "firebase.google.com/go/v4"
)

// FirebaseVerifier verifies signature, expiry, issuer and audience using Admin SDK.
// Initialization uses ADC and does not contact Firebase Auth until a request arrives.
func FirebaseVerifier(ctx context.Context, projectID string) (VerifyFunc, error) {
	app, err := firebase.NewApp(ctx, &firebase.Config{ProjectID: projectID})
	if err != nil {
		return nil, err
	}
	client, err := app.Auth(ctx)
	if err != nil {
		return nil, err
	}
	return func(ctx context.Context, token string) (string, error) {
		verified, err := client.VerifyIDToken(ctx, token)
		if err != nil {
			return "", err
		}
		return verified.UID, nil
	}, nil
}
