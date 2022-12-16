package agent

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync/atomic"

	"cloud.google.com/go/firestore"
	"go.uber.org/zap"
	"golang.org/x/exp/slices"
	"google.golang.org/api/iterator"
)

type Provider string

const (
	ProviderTwitch Provider = "twitch"
)

type Request struct {
	*firestore.DocumentRef
	AgentID
	client *firestore.Client
}

func (r *Request) Provider() Provider {
	return Provider(r.ID[:strings.Index(r.ID, ":")])
}

func (r *Request) Channel() string {
	return r.ID[strings.Index(r.ID, ":")+1:]
}

func (r *Request) String() string {
	return r.ID
}

type RequestLock struct {
	bootstrapIter *firestore.DocumentIterator
	snapshotIter  *firestore.QuerySnapshotIterator
	agentID       AgentID
	client        *firestore.Client
	ctx           context.Context

	buf []*Request
}

func NewRequestLock(ctx context.Context, agentID AgentID, client *firestore.Client) *RequestLock {
	return &RequestLock{
		bootstrapIter: client.Collection("assignments").Documents(ctx),
		snapshotIter:  client.Collection("assignments").Where("agentCount", "<", 1).Snapshots(ctx),
		agentID:       agentID,
		client:        client,
		ctx:           ctx,
	}
}

func (r *RequestLock) Next() (*Request, error) {
	if r.ctx.Err() != nil {
		return nil, r.ctx.Err()
	}

	// this is done in a separate goroutine to allow for preemption racing.
	for {
		assignment, err := r.bootstrapIter.Next()
		if err != nil {
			if errors.Is(err, iterator.Done) {
				break
			}
			return nil, err
		}
		agentIDs := append(AgentIDsForDocument(assignment.Data()), r.agentID)
		if len(agentIDs) > 1 && agentIDs.CanonicalAgentIDFor(assignment.Ref.ID) == r.agentID {
			// we would win election so join the assignment
			return &Request{DocumentRef: assignment.Ref, AgentID: r.agentID, client: r.client}, nil
		}
	}

	// listen for changes to requests
	for {
		if len(r.buf) > 0 {
			req := r.buf[0]
			r.buf = r.buf[1:]
			return req, nil
		}

		snapshot, err := r.snapshotIter.Next()
		if err != nil {
			if errors.Is(err, iterator.Done) {
				break
			}
			return nil, err
		}
		docs, err := snapshot.Documents.GetAll()
		if err != nil {
			return nil, err
		}
		for _, doc := range docs {
			if len(AgentIDsForDocument(doc.Data())) == 0 {
				r.buf = append(r.buf, &Request{DocumentRef: doc.Ref, AgentID: r.agentID, client: r.client})
			}
		}
	}
	return nil, context.Canceled
}

type Claim struct {
	*Request

	unlocked *atomic.Bool
}

func LockClaim(req *Request) (*Claim, error) {
	// increment agentCount and add agentID to agentIDs
	zap.L().Info("locking claim", zap.String("request", req.String()))

	if err := req.client.RunTransaction(context.Background(), func(ctx context.Context, tx *firestore.Transaction) error {
		doc, err := tx.Get(req.DocumentRef)
		if err != nil {
			return err
		}
		agentIDs := AgentIDsForDocument(doc.Data())

		// if we are already in the set of agentIDs, return an error.
		if slices.Contains(agentIDs, req.AgentID) {
			return fmt.Errorf("agent %s already has claim %s", req.AgentID, req.ID)
		}
		// increment the agent count and add our agentID to the set of agentIDs
		return tx.Update(req.DocumentRef, []firestore.Update{
			{Path: "agentCount", Value: firestore.Increment(1)},
			{Path: "agentIds", Value: append(agentIDs, req.AgentID)},
		})
	}); err != nil {
		return nil, fmt.Errorf("failed to lock claim: %w", err)
	}

	return &Claim{Request: req, unlocked: &atomic.Bool{}}, nil
}

func (c *Claim) Wait() error {
	snapshots := c.Snapshots(context.Background())
	for {
		snapshot, err := snapshots.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return err
		}
		if !snapshot.Exists() {
			return nil
		}
		agentIDs := AgentIDsForDocument(snapshot.Data())
		if len(agentIDs) == 0 {
			continue
		}
		canonical := agentIDs.CanonicalAgentIDFor(c.ID)
		zap.L().Info("assignment changed", zap.String("id", snapshot.Ref.ID), zap.Any("data", snapshot.Data()), zap.String("canonical", string(canonical)))
		if canonical != c.AgentID {
			break
		}
	}
	return nil
}

func (c *Claim) Unlock() error {
	if !c.unlocked.CompareAndSwap(false, true) {
		return nil
	}

	zap.L().Info("unlocking claim", zap.String("request", c.String()))

	if err := c.client.RunTransaction(context.Background(), func(ctx context.Context, tx *firestore.Transaction) error {
		doc, err := tx.Get(c.DocumentRef)
		if err != nil {
			return err
		}
		agentIDs := AgentIDsForDocument(doc.Data())
		if !slices.Contains(agentIDs, c.AgentID) {
			return fmt.Errorf("agent %s does not have claim %s", c.AgentID, c.ID)
		}
		return tx.Update(c.DocumentRef, []firestore.Update{
			{Path: "agentCount", Value: firestore.Increment(-1)},
			{Path: "agentIds", Value: firestore.ArrayRemove(c.AgentID)},
		})
	}); err != nil {
		return fmt.Errorf("failed to unlock claim: %w", err)
	}
	return nil
}
