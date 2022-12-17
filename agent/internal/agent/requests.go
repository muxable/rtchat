package agent

import (
	"context"
	"strings"

	"cloud.google.com/go/firestore"
)

type Provider string

const (
	ProviderTwitch Provider = "twitch"
)

type Request struct {
	*firestore.DocumentRef
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
	snapshotIter *firestore.QuerySnapshotIterator
	client       *firestore.Client
	ctx          context.Context
	reqCh        chan *Request
}

func NewRequestLock(ctx context.Context, client *firestore.Client) *RequestLock {
	r := &RequestLock{
		snapshotIter: client.Collection("assignments").Snapshots(ctx),
		client:       client,
		ctx:          ctx,
		reqCh:        make(chan *Request, 8192),
	}
	go func() {
		for {
			snapshot, err := r.snapshotIter.Next()
			if err != nil {
				return
			}
			for _, change := range snapshot.Changes {
				if change.Kind != firestore.DocumentRemoved {
					r.reqCh <- &Request{DocumentRef: change.Doc.Ref, client: r.client}
				}
			}
		}
	}()
	return r
}

func (r *RequestLock) Next() (*Request, error) {
	select {
	case req := <-r.reqCh:
		return req, nil
	case <-r.ctx.Done():
		return nil, r.ctx.Err()
	}
}
