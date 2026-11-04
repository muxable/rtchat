package main

import (
	"context"
	"time"

	"cloud.google.com/go/firestore"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const collection = "autofix"

// Attempt states. Each error group gets at most one attempt; delete its
// document to try again.
const (
	stateStarting   = "starting"
	stateRunning    = "running"
	stateCollecting = "collecting"
	stateProposed   = "proposed"
	stateNoFix      = "no_fix"
	stateRejected   = "rejected"
	stateFailed     = "failed"
)

type Attempt struct {
	GroupID   string    `firestore:"groupId"`
	State     string    `firestore:"state"`
	SessionID string    `firestore:"sessionId,omitempty"`
	BaseSHA   string    `firestore:"baseSha,omitempty"`
	Title     string    `firestore:"title"`
	Count     int64     `firestore:"count"`
	Location  *Frame    `firestore:"location,omitempty"`
	Reason    string    `firestore:"reason,omitempty"`
	PRURL     string    `firestore:"prUrl,omitempty"`
	CreatedAt time.Time `firestore:"createdAt"`
	UpdatedAt time.Time `firestore:"updatedAt"`
}

type Store struct{ fs *firestore.Client }

// Claim records a new attempt for the report. It returns false if the group
// was already attempted, so concurrent runs can't start duplicate sessions.
func (s *Store) Claim(ctx context.Context, r *Report) (bool, error) {
	now := time.Now()
	_, err := s.fs.Collection(collection).Doc(r.Key()).Create(ctx, Attempt{
		GroupID: r.GroupID, State: stateStarting, Title: r.Title(), Count: r.Count,
		Location: r.Location, CreatedAt: now, UpdatedAt: now,
	})
	if status.Code(err) == codes.AlreadyExists {
		return false, nil
	}
	return err == nil, err
}

func (s *Store) Update(ctx context.Context, key string, updates map[string]any) error {
	fields := []firestore.Update{{Path: "updatedAt", Value: time.Now()}}
	for k, v := range updates {
		fields = append(fields, firestore.Update{Path: k, Value: v})
	}
	_, err := s.fs.Collection(collection).Doc(key).Update(ctx, fields)
	return err
}

// Transition moves an attempt from one state to another, failing if another
// run already moved it.
func (s *Store) Transition(ctx context.Context, key, from, to string) (bool, error) {
	ref := s.fs.Collection(collection).Doc(key)
	moved := false
	err := s.fs.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		moved = false
		snap, err := tx.Get(ref)
		if err != nil {
			return err
		}
		if state, _ := snap.DataAt("state"); state != from {
			return nil
		}
		moved = true
		return tx.Update(ref, []firestore.Update{{Path: "state", Value: to}, {Path: "updatedAt", Value: time.Now()}})
	})
	return moved, err
}

type keyedAttempt struct {
	Key string
	Attempt
}

func (s *Store) InState(ctx context.Context, states ...string) ([]keyedAttempt, error) {
	docs, err := s.fs.Collection(collection).Where("state", "in", states).Documents(ctx).GetAll()
	if err != nil {
		return nil, err
	}
	out := make([]keyedAttempt, 0, len(docs))
	for _, doc := range docs {
		var a Attempt
		if err := doc.DataTo(&a); err != nil {
			return nil, err
		}
		out = append(out, keyedAttempt{Key: doc.Ref.ID, Attempt: a})
	}
	return out, nil
}
