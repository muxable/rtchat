// Package ircauth spaces IRC authentication attempts across agent replicas.
package ircauth

import (
	"context"
	"sync"
	"time"

	"cloud.google.com/go/firestore"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// Gate serializes local waiters per account and claims a shared slot immediately
// before connecting. One attempt per second leaves headroom under Twitch's
// account-wide limit of 20 authentications per 10 seconds during rolling deploys.
type Gate struct {
	reserve func(context.Context, string) (time.Duration, error)
	locks   sync.Map
}

func NewFirestoreGate(db *firestore.Client) *Gate {
	return &Gate{reserve: func(ctx context.Context, login string) (time.Duration, error) {
		ref := db.Collection("ircAuthLimits").Doc(login)
		var wait time.Duration
		err := db.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
			wait = 0
			doc, err := tx.Get(ref)
			if err != nil && status.Code(err) != codes.NotFound {
				return err
			}
			now := time.Now()
			if err == nil {
				// Use the committed server time. A client timestamp captured
				// before a contended commit can already be stale when it returns.
				next := doc.UpdateTime.Add(time.Second)
				if next.After(now) {
					wait = next.Sub(now)
					return nil
				}
			}
			return tx.Set(ref, map[string]any{"claimedAt": firestore.ServerTimestamp})
		})
		return wait, err
	}}
}

func (g *Gate) Wait(ctx context.Context, login string) error {
	value, _ := g.locks.LoadOrStore(login, make(chan struct{}, 1))
	lock := value.(chan struct{})
	select {
	case lock <- struct{}{}:
	case <-ctx.Done():
		return ctx.Err()
	}
	defer func() { <-lock }()
	for {
		if err := ctx.Err(); err != nil {
			return err
		}
		wait, err := g.reserve(ctx, login)
		if err != nil {
			return err
		}
		if wait <= 0 {
			return nil
		}
		timer := time.NewTimer(wait)
		select {
		case <-timer.C:
		case <-ctx.Done():
			timer.Stop()
			return ctx.Err()
		}
	}
}
