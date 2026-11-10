// Package subscriptionlock serializes provider subscription lifecycle work
// across callable requests, cleanup jobs, replicas, and spot replacements.
package subscriptionlock

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"slices"
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

// ErrBusy means another holder has the lease.
var ErrBusy = errors.New("subscription lease busy")

// With gives work a 45-second deadline and holds its distributed lease for
// 90 seconds. All provider requests must honor this context. Lease expiry lets
// another replica recover a dead instance; ownership guards stale releases.
func With(ctx context.Context, db *firestore.Client, key string, work func(context.Context) error) error {
	return with(ctx, db, key, true, 0, nil, work)
}

// TryWith is With without waiting: it returns ErrBusy while another holder has
// the lease, so a worker can move on to other keys.
func TryWith(ctx context.Context, db *firestore.Client, key string, work func(context.Context) error) error {
	return with(ctx, db, key, false, 0, nil, work)
}

// WithWaitLimit bounds only lease acquisition, returning ErrBusy when that
// budget expires. Once acquired, work retains the normal 45-second deadline.
func WithWaitLimit(ctx context.Context, db *firestore.Client, key string, limit time.Duration, work func(context.Context) error) error {
	return with(ctx, db, key, true, limit, nil, work)
}

// WithWaitLimitBeside is WithWaitLimit, except that while the lease is held
// for one of the beside jobs, work runs at once alongside that holder without
// taking the lease. Use it only for work that doesn't conflict with those
// jobs; leases held for any other job, or for none, still exclude it.
func WithWaitLimitBeside(ctx context.Context, db *firestore.Client, key string, limit time.Duration, beside []string, work func(context.Context) error) error {
	return with(ctx, db, key, true, limit, beside, work)
}

type jobKey struct{}

// Job labels the leases taken with ctx, so that work which doesn't conflict
// with job can run beside it (see WithWaitLimitBeside).
func Job(ctx context.Context, job string) context.Context {
	return context.WithValue(ctx, jobKey{}, job)
}

// JobOf returns the job that leases taken with ctx are labeled with.
func JobOf(ctx context.Context) string {
	job, _ := ctx.Value(jobKey{}).(string)
	return job
}

func with(ctx context.Context, db *firestore.Client, key string, wait bool, limit time.Duration, beside []string, work func(context.Context) error) error {
	acquire := ctx
	cancelAcquire := func() {}
	if limit > 0 {
		acquire, cancelAcquire = context.WithTimeout(ctx, limit)
	}
	defer cancelAcquire()
	var id [16]byte
	if _, err := rand.Read(id[:]); err != nil {
		return err
	}
	owner := hex.EncodeToString(id[:])
	ref := db.Collection("subscriptionLeases").Doc(key)
	lease := map[string]interface{}{"owner": owner, "until": time.Now().Add(90 * time.Second)}
	if job := JobOf(ctx); job != "" {
		lease["job"] = job
	}
	for {
		acquired, alongside := false, false
		err := db.RunTransaction(acquire, func(ctx context.Context, tx *firestore.Transaction) error {
			acquired, alongside = false, false
			doc, err := tx.Get(ref)
			if err != nil && status.Code(err) != codes.NotFound {
				return err
			}
			if err == nil {
				until, _ := doc.Data()["until"].(time.Time)
				if until.After(time.Now()) {
					job, _ := doc.Data()["job"].(string)
					alongside = job != "" && slices.Contains(beside, job)
					return nil
				}
			}
			lease["until"] = time.Now().Add(90 * time.Second)
			if err := tx.Set(ref, lease); err != nil {
				return err
			}
			acquired = true
			return nil
		})
		if err != nil {
			if ctx.Err() != nil {
				return ctx.Err()
			}
			if acquire.Err() != nil {
				return ErrBusy
			}
			return err
		}
		if alongside {
			cancelAcquire()
			bounded, cancel := context.WithTimeout(ctx, 45*time.Second)
			defer cancel()
			if err := work(bounded); err != nil {
				return err
			}
			return bounded.Err()
		}
		if acquired {
			break
		}
		if !wait {
			return ErrBusy
		}
		timer := time.NewTimer(200 * time.Millisecond)
		select {
		case <-acquire.Done():
			timer.Stop()
			if ctx.Err() != nil {
				return ctx.Err()
			}
			return ErrBusy
		case <-timer.C:
		}
	}
	cancelAcquire()
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
