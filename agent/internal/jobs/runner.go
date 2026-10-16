// Package jobs runs the former Cloud Scheduler jobs on agent replicas.
package jobs

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"time"
	_ "time/tzdata"

	"cloud.google.com/go/firestore"
	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type Lease struct {
	Owner         string    `firestore:"owner"`
	ExpiresAt     time.Time `firestore:"expiresAt"`
	CompletedSlot string    `firestore:"completedSlot"`
}

type LeaseStore interface {
	Acquire(context.Context, string, string, string, time.Time, time.Duration) (bool, error)
	Finish(context.Context, string, string, string, bool) error
}

type FirestoreLeases struct{ Client *firestore.Client }

func canAcquire(l Lease, slot string, now time.Time) bool {
	return l.CompletedSlot != slot && !l.ExpiresAt.After(now)
}

func (s FirestoreLeases) Acquire(ctx context.Context, name, owner, slot string, now time.Time, ttl time.Duration) (bool, error) {
	acquired := false
	ref := s.Client.Collection("jobLeases").Doc(name)
	err := s.Client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		acquired = false
		doc, err := tx.Get(ref)
		var lease Lease
		if status.Code(err) != codes.NotFound {
			if err != nil {
				return err
			}
			if err = doc.DataTo(&lease); err != nil {
				return err
			}
		}
		if !canAcquire(lease, slot, now) {
			return nil
		}
		lease.Owner = owner
		lease.ExpiresAt = now.Add(ttl)
		if err := tx.Set(ref, lease); err != nil {
			return err
		}
		acquired = true
		return nil
	})
	return acquired, err
}
func (s FirestoreLeases) Finish(ctx context.Context, name, owner, slot string, success bool) error {
	ref := s.Client.Collection("jobLeases").Doc(name)
	return s.Client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		doc, err := tx.Get(ref)
		if err != nil {
			return err
		}
		var lease Lease
		if err = doc.DataTo(&lease); err != nil {
			return err
		}
		if lease.Owner != owner {
			return fmt.Errorf("job lease ownership lost")
		}
		lease.ExpiresAt = time.Time{}
		if success {
			lease.CompletedSlot = slot
		}
		return tx.Set(ref, lease)
	})
}

type Job struct {
	Name    string
	Timeout time.Duration
	Daily   bool
	Run     func(context.Context) error
}
type Runner struct {
	Leases LeaseStore
	Jobs   []Job
}

var scheduleLocation = func() *time.Location {
	location, err := time.LoadLocation("America/Los_Angeles")
	if err != nil {
		panic(err)
	}
	return location
}()

// Slot preserves the deployed schedules' America/Los_Angeles timezone.
// A daily slot starts at 04:00 local time, including across DST changes.
func Slot(now time.Time, daily bool) string {
	if daily {
		local := now.In(scheduleLocation)
		if local.Hour() < 4 {
			local = local.AddDate(0, 0, -1)
		}
		return local.Format("2006-01-02")
	}
	return now.UTC().Truncate(4 * time.Minute).Format(time.RFC3339)
}

func (r Runner) Run(ctx context.Context) {
	// Each job has its own loop so slow cleanup cannot delay either refresh.
	done := make(chan struct{}, len(r.Jobs))
	for _, job := range r.Jobs {
		go func(job Job) {
			defer func() { done <- struct{}{} }()
			ticker := time.NewTicker(15 * time.Second)
			defer ticker.Stop()
			for {
				r.Once(ctx, job, time.Now())
				select {
				case <-ctx.Done():
					return
				case <-ticker.C:
				}
			}
		}(job)
	}
	for range r.Jobs {
		<-done
	}
}
func (r Runner) Once(ctx context.Context, job Job, now time.Time) {
	if ctx.Err() != nil {
		return
	}
	var id [16]byte
	if _, err := rand.Read(id[:]); err != nil {
		zap.L().Error("job owner creation failed", zap.Error(err))
		return
	}
	owner := hex.EncodeToString(id[:])
	slot := Slot(now, job.Daily)
	// Work expires before its lease. This leaves a safety window for canceled
	// HTTP/Firestore requests to stop before another replica can take over.
	leaseCtx, leaseCancel := context.WithTimeout(ctx, 15*time.Second)
	acquired, err := r.Leases.Acquire(leaseCtx, job.Name, owner, slot, now, job.Timeout+time.Minute)
	leaseCancel()
	if err != nil {
		zap.L().Error("job lease acquisition failed", zap.String("job", job.Name), zap.Error(err))
		return
	}
	if !acquired {
		return
	}
	started := time.Now()
	work, cancel := context.WithTimeout(ctx, job.Timeout)
	err = job.Run(work)
	if err == nil {
		err = work.Err()
	}
	cancel()
	finishCtx, finishCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer finishCancel()
	if finishErr := r.Leases.Finish(finishCtx, job.Name, owner, slot, err == nil); finishErr != nil {
		zap.L().Error("job lease completion failed", zap.String("job", job.Name), zap.Error(finishErr))
	}
	if err != nil {
		zap.L().Error("scheduled job failed", zap.String("job", job.Name), zap.String("slot", slot), zap.Duration("duration", time.Since(started)), zap.Error(err))
		return
	}
	zap.L().Info("scheduled job completed", zap.String("job", job.Name), zap.String("slot", slot), zap.Duration("duration", time.Since(started)))
}
