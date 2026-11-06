// Package jobs runs the former Cloud Scheduler jobs on agent replicas.
package jobs

import (
	"context"
	"time"
	_ "time/tzdata"

	"cloud.google.com/go/firestore"
	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// Lease lets one replica run a job's slot. Work stops a minute before the
// lease expires, so the holder always finishes while no one else can hold it.
type Lease struct {
	ExpiresAt     time.Time `firestore:"expiresAt"`
	CompletedSlot string    `firestore:"completedSlot"`
}

// LeaseStore never fails: a lease that couldn't be confirmed isn't held, and
// the next tick tries again; a finish that isn't recorded lets the lease expire.
type LeaseStore interface {
	Acquire(ctx context.Context, name, slot string, now time.Time, ttl time.Duration) bool
	Finish(ctx context.Context, name, slot string, success bool)
}

type FirestoreLeases struct{ Client *firestore.Client }

func canAcquire(l Lease, slot string, now time.Time) bool {
	return l.CompletedSlot != slot && !l.ExpiresAt.After(now)
}

func (s FirestoreLeases) Acquire(ctx context.Context, name, slot string, now time.Time, ttl time.Duration) bool {
	acquired := false
	ref := s.Client.Collection("jobLeases").Doc(name)
	err := s.Client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		acquired = false
		doc, err := tx.Get(ref)
		var lease Lease
		if err == nil {
			err = doc.DataTo(&lease)
		}
		if err != nil && status.Code(err) != codes.NotFound {
			return err
		}
		if !canAcquire(lease, slot, now) {
			return nil
		}
		acquired = true
		return tx.Set(ref, Lease{ExpiresAt: now.Add(ttl), CompletedSlot: lease.CompletedSlot})
	})
	return acquired && err == nil
}

// Finish runs while the caller's lease is live, so it needs no ownership check.
func (s FirestoreLeases) Finish(ctx context.Context, name, slot string, success bool) {
	update := map[string]interface{}{"expiresAt": time.Time{}}
	if success {
		update["completedSlot"] = slot
	}
	s.Client.Collection("jobLeases").Doc(name).Set(ctx, update, firestore.MergeAll)
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
	slot := Slot(now, job.Daily)
	// Work expires before its lease. This leaves a safety window for canceled
	// HTTP/Firestore requests, and Finish, to stop before another replica can take over.
	leaseCtx, leaseCancel := context.WithTimeout(ctx, 15*time.Second)
	acquired := r.Leases.Acquire(leaseCtx, job.Name, slot, now, job.Timeout+time.Minute)
	leaseCancel()
	if !acquired {
		return
	}
	started := time.Now()
	work, cancel := context.WithTimeout(ctx, job.Timeout)
	err := job.Run(work)
	if err == nil {
		err = work.Err()
	}
	cancel()
	finishCtx, finishCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer finishCancel()
	r.Leases.Finish(finishCtx, job.Name, slot, err == nil)
	if err != nil {
		zap.L().Error("scheduled job failed", zap.String("job", job.Name), zap.String("slot", slot), zap.Duration("duration", time.Since(started)), zap.Error(err))
		return
	}
	zap.L().Info("scheduled job completed", zap.String("job", job.Name), zap.String("slot", slot), zap.Duration("duration", time.Since(started)))
}
