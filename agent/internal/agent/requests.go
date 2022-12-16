package agent

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"cloud.google.com/go/firestore"
	"go.uber.org/zap"
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
	snapshotIter  *firestore.QuerySnapshotIterator
	agentID       AgentID
	client        *firestore.Client
	ctx           context.Context

	buf []*Request
}

func NewRequestLock(ctx context.Context, agentID AgentID, client *firestore.Client) *RequestLock {
	return &RequestLock{
		snapshotIter:  client.Collection("assignments").Snapshots(ctx),
		agentID:       agentID,
		client:        client,
		ctx:           ctx,
	}
}

func (r *RequestLock) Next() (*Request, error) {
	if r.ctx.Err() != nil {
		return nil, r.ctx.Err()
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
		for _, change := range snapshot.Changes {
			if change.Doc.Exists() && len(AgentIDsForDocument(change.Doc.Data())) == 0 {
				r.buf = append(r.buf, &Request{DocumentRef: change.Doc.Ref, AgentID: r.agentID, client: r.client})
			}
		}
	}
	return nil, context.Canceled
}

type Claim struct {
	*Request
}

func LockClaim(req *Request) (*Claim, error) {
	zap.L().Info("locking claim", zap.String("request", req.String()))

	if _, err := req.DocumentRef.Update(context.Background(), []firestore.Update{
		{Path: "agentIds", Value: firestore.ArrayUnion(string(req.AgentID))},
	}); err != nil {
		return nil, fmt.Errorf("failed to lock claim: %w", err)
	}

	return &Claim{Request: req}, nil
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
	zap.L().Info("unlocking claim", zap.String("request", c.String()))

	if _, err := c.DocumentRef.Update(context.Background(), []firestore.Update{
		{Path: "agentIds", Value: firestore.ArrayRemove(string(c.AgentID))},
	}); err != nil {
		return fmt.Errorf("failed to unlock claim: %w", err)
	}
	return nil
}
