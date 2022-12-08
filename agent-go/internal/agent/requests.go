package agent

import (
	"context"
	"strings"
	"sync"

	"cloud.google.com/go/firestore"
	"github.com/google/uuid"
	"go.uber.org/zap"
	"google.golang.org/api/iterator"
)

type Provider string

const (
	ProviderTwitch Provider = "twitch"
)

type Request firestore.DocumentSnapshot

func (r *Request) Provider() Provider {
	return Provider(r.Ref.ID[:strings.Index(r.Ref.ID, ":")])
}

func (r *Request) Channel() string {
	return r.Ref.ID[strings.Index(r.Ref.ID, ":")+1:]
}

func (r *Request) String() string {
	return r.Ref.ID
}

type RequestLock struct {
	ctx       context.Context
	client    *firestore.Client
	AgentID   AgentID
	onRequest func(*Request)
}

func NewRequestLock(ctx context.Context, client *firestore.Client) *RequestLock {
	return &RequestLock{
		ctx:     ctx,
		client:  client,
		AgentID: AgentID(uuid.New().String()),
	}
}

func (r *RequestLock) OnRequest(cb func(*Request)) {
	r.onRequest = cb
}

func (r *RequestLock) LockClaim(req *Request, abort context.Context) error {
	// increment agentCount and add agentID to agentIDs
	zap.L().Info("locking claim", zap.String("request", req.String()))
	if _, err := req.Ref.Update(r.ctx, []firestore.Update{
		{Path: "agentCount", Value: firestore.Increment(1)},
		{Path: "agentIDs", Value: firestore.ArrayUnion(r.AgentID)},
	}); err != nil {
		return err
	}

	zap.L().Info("waiting for claim to be unlocked", zap.String("request", req.String()))

	defer req.Ref.Update(context.Background(), []firestore.Update{
		{Path: "agentCount", Value: firestore.Increment(-1)},
		{Path: "agentIDs", Value: firestore.ArrayRemove(r.AgentID)},
	})

	merged, cancel := context.WithCancel(context.Background())
	go func() {
		select {
		case <-abort.Done():
			break
		case <-r.ctx.Done():
			break
		}
		cancel()
	}()

	// listen for changes and loop forever until we are no longer the canonical agent.
	snapshots := req.Ref.Snapshots(merged)
	for {
		snapshot, err := snapshots.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return err
		}
		zap.L().Info("assignment changed", zap.String("id", snapshot.Ref.ID), zap.Any("data", snapshot.Data()))
		if !snapshot.Exists() {
			return nil
		}
		agentIDs := AgentIDsForDocument(snapshot.Data())
		if len(agentIDs) > 0 && agentIDs.CanonicalAgentIDFor(req.Ref.ID) != r.AgentID {
			break
		}
	}
	return nil
}

func (r *RequestLock) ListenForRequests() error {
	var wg sync.WaitGroup
	defer wg.Wait()

	// fetch all existing assignments and see if we are the canonical agent
	assignments := r.client.Collection("assignments").Documents(r.ctx)
	for {
		assignment, err := assignments.Next()
		if err != nil {
			if err == iterator.Done {
				break
			}
			return err
		}
		agentIDs := append(AgentIDsForDocument(assignment.Data()), r.AgentID)
		if len(agentIDs) > 1 && agentIDs.CanonicalAgentIDFor(assignment.Ref.ID) == r.AgentID {
			// we would win election so join the assignment
			wg.Add(1)
			go func() {
				r.onRequest((*Request)(assignment))
				wg.Done()
			}()
		}
	}

	// listen for changes to requests
	snapshots := r.client.Collection("assignments").Where("agentCount", "<", 1).Snapshots(r.ctx)
	for {
		snapshot, err := snapshots.Next()
		if err != nil {
			if err == iterator.Done {
				break
			}
			return err
		}
		for _, change := range snapshot.Changes {
			if change.Kind == firestore.DocumentAdded {
				tokens := strings.Split(change.Doc.Ref.ID, ":")
				if len(tokens) != 2 {
					zap.L().Error("invalid assignment id", zap.String("id", change.Doc.Ref.ID))
					continue
				}
				wg.Add(1)
				go func() {
					r.onRequest((*Request)(change.Doc))
					wg.Done()
				}()
			}
		}
	}
	return nil
}
