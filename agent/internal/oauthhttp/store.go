package oauthhttp

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"firebase.google.com/go/v4/auth"
	"firebase.google.com/go/v4/db"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type FirebaseStore struct {
	Firestore *firestore.Client
	Auth      *auth.Client
	Database  *db.Client
}

func (s *FirebaseStore) SaveSession(ctx context.Context, id string, session Session) error {
	_, err := s.Firestore.Collection("oauth-http-sessions").Doc(id).Create(ctx, map[string]any{"session": session, "expiresAt": session.Expires})
	return err
}
func (s *FirebaseStore) ConsumeSession(ctx context.Context, id, provider, state string) (Session, error) {
	var result Session
	if id == "" || state == "" {
		return result, errors.New("missing session")
	}
	ref := s.Firestore.Collection("oauth-http-sessions").Doc(id)
	err := s.Firestore.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		doc, err := tx.Get(ref)
		if err != nil {
			return err
		}
		var data struct {
			Session Session `firestore:"session"`
		}
		if err := doc.DataTo(&data); err != nil {
			return err
		}
		session := data.Session
		if session.Provider != provider || !hmac.Equal([]byte(session.State), []byte(state)) || time.Now().After(session.Expires) {
			return errors.New("invalid session")
		}
		result = session
		return tx.Delete(ref)
	})
	return result, err
}
func (s *FirebaseStore) Allow(ctx context.Context, peer string) (bool, error) {
	// Shared fixed-window limiter: restarts and replica balancing cannot reset it.
	sum := sha256.Sum256([]byte(peer))
	ref := s.Firestore.Collection("oauth-http-ratelimits").Doc(hex.EncodeToString(sum[:]))
	allowed := false
	now := time.Now()
	err := s.Firestore.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		allowed = false
		doc, err := tx.Get(ref)
		if err != nil && status.Code(err) != codes.NotFound {
			return err
		}
		var data struct {
			Count   int       `firestore:"count"`
			Expires time.Time `firestore:"expiresAt"`
		}
		if err == nil {
			if err := doc.DataTo(&data); err != nil {
				return err
			}
		}
		if now.After(data.Expires) {
			data.Count = 0
			data.Expires = now.Add(time.Minute)
		}
		if data.Count >= 30 {
			return nil
		}
		data.Count++
		allowed = true
		return tx.Set(ref, map[string]any{"count": data.Count, "expiresAt": data.Expires})
	})
	return allowed, err
}
func (s *FirebaseStore) Verify(ctx context.Context, token string) (string, error) {
	v, e := s.Auth.VerifyIDToken(ctx, token)
	if e != nil {
		return "", e
	}
	return v.UID, nil
}
func (s *FirebaseStore) SignIn(ctx context.Context, provider string, profile map[string]any, token map[string]any, companion string) (string, error) {
	id := str(profile["id"])
	if id == "" || strings.ContainsAny(id, ".#$[]/") {
		return "", errors.New("invalid provider id")
	}
	ref := s.Database.NewRef("userIds/" + provider + "/" + id)
	var uid string
	if err := ref.Get(ctx, &uid); err != nil {
		return "", err
	}
	if uid == "" {
		// Pick a UID before the transaction so retrying cannot create more Firebase users.
		candidate := random()
		if err := ref.Transaction(ctx, func(node db.TransactionNode) (interface{}, error) {
			var current string
			if err := node.Unmarshal(&current); err != nil {
				return nil, err
			}
			if current != "" {
				return current, nil
			}
			return candidate, nil
		}); err != nil {
			return "", err
		}
		if err := ref.Get(ctx, &uid); err != nil {
			return "", err
		}
	}
	// A previously reserved mapping can be recovered after a process failure.
	if _, err := s.Auth.GetUser(ctx, uid); auth.IsUserNotFound(err) {
		if _, err := s.Auth.CreateUser(ctx, (&auth.UserToCreate{}).UID(uid)); err != nil && !auth.IsUIDAlreadyExists(err) {
			return "", err
		}
	} else if err != nil {
		return "", err
	}
	if err := s.persistToken(ctx, s.Firestore.Collection("tokens").Doc(uid), provider, token); err != nil {
		return "", err
	}
	if _, err := s.Firestore.Collection("profiles").Doc(uid).Set(ctx, map[string]any{provider: profile}, firestore.MergeAll); err != nil {
		return "", err
	}
	custom, err := s.Auth.CustomToken(ctx, uid)
	if err != nil {
		return "", err
	}
	if companion != "" {
		_, err = s.Firestore.Collection("companion-tokens").Doc(companion).Set(ctx, map[string]any{"token": custom}, firestore.MergeAll)
	}
	return custom, err
}
func (s *FirebaseStore) persistToken(ctx context.Context, ref *firestore.DocumentRef, field string, token map[string]any) error {
	return s.Firestore.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		doc, err := tx.Get(ref)
		if err != nil && status.Code(err) != codes.NotFound {
			return err
		}
		copyToken := map[string]any{}
		for k, v := range token {
			copyToken[k] = v
		}
		if err == nil && copyToken["refresh_token"] == nil {
			if encoded, ok := doc.Data()[field].(string); ok {
				var previous map[string]any
				if json.Unmarshal([]byte(encoded), &previous) == nil && previous["refresh_token"] != nil {
					copyToken["refresh_token"] = previous["refresh_token"]
				}
			}
		}
		encoded, err := json.Marshal(copyToken)
		if err != nil {
			return err
		}
		return tx.Set(ref, map[string]any{field: string(encoded)}, firestore.MergeAll)
	})
}
func (s *FirebaseStore) Link(ctx context.Context, uid, provider, linked string, token map[string]any) error {
	profile, err := s.Firestore.Collection("profiles").Doc(uid).Get(ctx)
	if err != nil {
		return err
	}
	id := str(object(profile.Data()[linked])["id"])
	if id == "" {
		return errors.New("provider not linked")
	}
	encoded, err := json.Marshal(token)
	if err != nil {
		return err
	}
	_, err = s.Firestore.Collection(provider).Doc(uid).Set(ctx, map[string]any{"channelId": linked + ":" + id, "token": string(encoded)}, firestore.MergeAll)
	return err
}
