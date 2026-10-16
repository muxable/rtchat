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

// FirebaseAppCheckVerifier verifies App Check token signatures and project audience.
// Existing callable routes have no App Check enforcement; future enforced routes
// must configure this verifier and use RegisterWithOptions.
func FirebaseAppCheckVerifier(ctx context.Context, projectID string) (VerifyFunc, error) {
	app, err := firebase.NewApp(ctx, &firebase.Config{ProjectID: projectID})
	if err != nil {
		return nil, err
	}
	client, err := app.AppCheck(ctx)
	if err != nil {
		return nil, err
	}
	return func(ctx context.Context, token string) (string, error) {
		if err := ctx.Err(); err != nil {
			return "", err
		}
		verified, err := client.VerifyToken(token)
		if err != nil {
			return "", err
		}
		return verified.AppID, nil
	}, nil
}
