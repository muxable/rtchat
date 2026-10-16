package provider

import (
	"cloud.google.com/go/firestore"
	"context"
	"crypto/rand"
	"encoding/hex"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"time"
)

// FirestoreStore serializes rotating refresh tokens across all managed instances.
// Lease metadata is a sibling field so legacy functions still read the same JSON strings.
type FirestoreStore struct{ DB *firestore.Client }

func newLeaseID() string {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		panic(err)
	}
	return hex.EncodeToString(b[:])
}
func (s FirestoreStore) Load(ctx context.Context, uid, p string) (string, error) {
	doc, err := s.DB.Collection("tokens").Doc(uid).Get(ctx)
	if status.Code(err) == codes.NotFound {
		return "", ErrNoToken
	}
	if err != nil {
		return "", err
	}
	encoded, ok := doc.Data()[p].(string)
	if !ok || encoded == "" {
		return "", ErrNoToken
	}
	return encoded, nil
}
func (s FirestoreStore) Acquire(ctx context.Context, uid, p, encoded, owner string, until time.Time) (bool, error) {
	acquired := false
	err := s.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		acquired = false
		ref := s.DB.Collection("tokens").Doc(uid)
		doc, err := tx.Get(ref)
		if err != nil {
			return err
		}
		if doc.Data()[p] != encoded {
			return nil
		}
		lease, _ := doc.Data()["_refresh_"+p].(map[string]any)
		if expiry, ok := lease["until"].(time.Time); ok && time.Now().Before(expiry) {
			return nil
		}
		acquired = true
		return tx.Set(ref, map[string]any{"_refresh_" + p: map[string]any{"owner": owner, "until": until}}, firestore.MergeAll)
	})
	return acquired, err
}
func (s FirestoreStore) Finish(ctx context.Context, uid, p, encoded, owner string, next *string, revoked bool) error {
	return s.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		ref := s.DB.Collection("tokens").Doc(uid)
		doc, err := tx.Get(ref)
		if err != nil {
			return err
		}
		lease, _ := doc.Data()["_refresh_"+p].(map[string]any)
		if lease["owner"] != owner {
			return ErrRefreshBusy
		}
		updates := []firestore.Update{{Path: "_refresh_" + p, Value: firestore.Delete}}
		if doc.Data()[p] == encoded {
			if next != nil {
				updates = append(updates, firestore.Update{Path: p, Value: *next})
			}
			if revoked {
				// Read the profile before any writes, as required by Firestore transactions.
				profile := s.DB.Collection("profiles").Doc(uid)
				snap, err := tx.Get(profile)
				if err != nil && status.Code(err) != codes.NotFound {
					return err
				}
				if err == nil && snap.Exists() {
					if err := tx.Update(profile, []firestore.Update{{Path: p, Value: firestore.Delete}}); err != nil {
						return err
					}
				}
				updates = append(updates, firestore.Update{Path: p, Value: firestore.Delete})
			}
		}
		return tx.Update(ref, updates)
	})
}
