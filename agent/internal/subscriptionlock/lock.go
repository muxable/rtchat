// Package subscriptionlock serializes provider subscription lifecycle work
// across callable requests, cleanup jobs, replicas, and spot replacements.
package subscriptionlock

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"time"

	"cloud.google.com/go/firestore"
	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// UncertainError means a provider mutation may still finish remotely.
// Keep its lifecycle lease until expiry rather than admitting overlapping work.
type UncertainError struct{ Err error }

func (e *UncertainError) Error() string { return "provider mutation outcome uncertain" }
func (e *UncertainError) Unwrap() error { return e.Err }

// With gives work a 45-second deadline and holds its distributed lease for
// 90 seconds. All provider requests must honor this context. Lease expiry lets
// another replica recover a dead instance; ownership guards stale releases.
func With(ctx context.Context, db *firestore.Client, key string, work func(context.Context) error) error {
	var id [16]byte
	if _, err := rand.Read(id[:]); err != nil {
		return err
	}
	owner := hex.EncodeToString(id[:])
	ref := db.Collection("subscriptionLeases").Doc(key)
	for {
		acquired := false
		err := db.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
			acquired = false
			doc, err := tx.Get(ref)
			if err != nil && status.Code(err) != codes.NotFound {
				return err
			}
			if err == nil {
				until, _ := doc.Data()["until"].(time.Time)
				if until.After(time.Now()) {
					return nil
				}
			}
			if err := tx.Set(ref, map[string]interface{}{"owner": owner, "until": time.Now().Add(90 * time.Second)}); err != nil {
				return err
			}
			acquired = true
			return nil
		})
		if err != nil {
			return err
		}
		if acquired {
			break
		}
		timer := time.NewTimer(200 * time.Millisecond)
		select {
		case <-ctx.Done():
			timer.Stop()
			return ctx.Err()
		case <-timer.C:
		}
	}
	bounded, cancel := context.WithTimeout(ctx, 45*time.Second)
	var workErr error
	defer func() {
		var uncertain *UncertainError
		retain := bounded.Err() != nil || errors.As(workErr, &uncertain)
		cancel()
		if retain {
			return
		}
		release, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		// Failed release is safe: the lease remains exclusive until its expiry.
		err := db.RunTransaction(release, func(ctx context.Context, tx *firestore.Transaction) error {
			doc, err := tx.Get(ref)
			if err != nil {
				return err
			}
			if doc.Data()["owner"] != owner {
				return errors.New("subscription lease ownership lost")
			}
			return tx.Delete(ref)
		})
		if err != nil {
			zap.L().Warn("subscription lease release failed", zap.String("key", key), zap.Error(err))
		}
	}()
	workErr = work(bounded)
	if workErr == nil {
		return bounded.Err()
	}
	return workErr
}
