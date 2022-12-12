package auth

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"time"

	"cloud.google.com/go/firestore"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/clientcredentials"
	"golang.org/x/oauth2/twitch"
)

type TwitchAuthProvider struct {
	firestore        *firestore.Client
	tokenSource      oauth2.TokenSource
	userID, username string
}

func TwitchUserIDFromUsername(firestore *firestore.Client, clientID, clientSecret, username string) (string, error) {
	userDoc, err := firestore.Collection("profiles").Where("twitch.login", "==", username).Documents(context.Background()).Next()
	if err == nil {
		return userDoc.Ref.ID, nil
	}
	// try fetching it from twitch.
	req := &http.Request{
		Method: "GET",
		URL: &url.URL{
			Scheme:   "https",
			Host:     "api.twitch.tv",
			Path:     "/helix/users",
			RawQuery: fmt.Sprintf("login=%s", username),
		},
	}
	cfg := &clientcredentials.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		TokenURL:     twitch.Endpoint.TokenURL,
	}
	resp, err := cfg.Client(context.Background()).Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to fetch user: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("failed to fetch user: %s", resp.Status)
	}

	var data struct {
		Data []struct {
			ID string `json:"id"`
		} `json:"data"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}
	if len(data.Data) == 0 {
		return "", fmt.Errorf("user not found: %s", username)
	}
	return data.Data[0].ID, nil
}

func NewFirestoreTwitchTokenSource(firestore *firestore.Client, clientID, clientSecret, userID string) (*TwitchAuthProvider, error) {
	// get the user's token
	tokenDoc, err := firestore.Collection("tokens").Doc(userID).Get(context.Background())
	if err != nil {
		return nil, err
	}
	iToken, err := tokenDoc.DataAt("twitch")
	if err != nil {
		return nil, err
	}
	strToken, ok := iToken.(string)
	if !ok {
		return nil, errors.New("invalid token")
	}
	var token struct {
		AccessToken  string `json:"access_token"`
		RefreshToken string `json:"refresh_token"`
		ExpiresAt    string `json:"expires_at"`
	}
	if err := json.Unmarshal([]byte(strToken), &token); err != nil {
		return nil, err
	}
	// get the user's username
	usernameDoc, err := firestore.Collection("profiles").Doc(userID).Get(context.Background())
	if err != nil {
		return nil, err
	}
	iUsername, err := usernameDoc.DataAt("twitch.login")
	if err != nil {
		return nil, err
	}
	username, ok := iUsername.(string)
	if !ok {
		return nil, errors.New("invalid username")
	}

	cfg := &oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		Endpoint:     twitch.Endpoint,
	}
	expiry, err := time.Parse(time.RFC3339Nano, token.ExpiresAt)
	if err != nil {
		return nil, err
	}
	source := cfg.TokenSource(context.Background(), &oauth2.Token{
		AccessToken:  token.AccessToken,
		RefreshToken: token.RefreshToken,
		Expiry:       expiry,
	})
	return &TwitchAuthProvider{
		firestore:   firestore,
		tokenSource: source,
		userID:      userID,
		username:    username,
	}, nil
}

func (p *TwitchAuthProvider) Token() (*oauth2.Token, error) {
	token, err := p.tokenSource.Token()
	if err != nil {
		return nil, err
	}
	// validate the token
	req := &http.Request{
		Method: "GET",
		URL: &url.URL{
			Scheme: "https",
			Host:   "id.twitch.tv",
			Path:   "/oauth2/validate",
		},
		Header: http.Header{
			"Authorization": []string{"OAuth " + token.AccessToken},
		},
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode == http.StatusUnauthorized {
		return nil, errors.New("invalid token")
	}
	// graft it into firestore
	return token, p.firestore.RunTransaction(context.Background(), func(ctx context.Context, tx *firestore.Transaction) error {
		tokenDoc, err := tx.Get(p.firestore.Collection("tokens").Doc(p.userID))
		if err != nil {
			return err
		}
		iToken, err := tokenDoc.DataAt("twitch")
		if err != nil {
			return err
		}
		strToken, ok := iToken.(string)
		if !ok {
			return errors.New("invalid token")
		}
		var mapToken map[string]interface{}
		if err := json.Unmarshal([]byte(strToken), &mapToken); err != nil {
			return err
		}
		mapToken["access_token"] = token.AccessToken
		mapToken["refresh_token"] = token.RefreshToken
		mapToken["expires_at"] = token.Expiry.Format(time.RFC3339Nano)
		bToken, err := json.Marshal(mapToken)
		if err != nil {
			return err
		}
		return tx.Set(p.firestore.Collection("tokens").Doc(p.userID), map[string]interface{}{
			"twitch": string(bToken),
		}, firestore.MergeAll)
	})
}
