package main

import (
	"io"
	"math/rand"
	"sync"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/handler"
	"go.uber.org/zap"
)

type requestManager struct {
	mu      sync.RWMutex
	clients map[string]io.Closer
	locks   KeyedMutex

	// per-channel work for submit: only the latest change per channel is
	// kept, and one worker per channel applies them in order.
	queueMu sync.Mutex
	queued  map[string]queuedChange
	running map[string]bool
	pending sync.WaitGroup

	newClient func(*agent.Request) (io.Closer, error)
	// every subscribe rewrites the assignment, so most updates to an already
	// authenticated channel are skipped instead of reconnecting it.
	skipUpgrade func() bool
}

type queuedChange struct {
	req  *agent.Request
	kind firestore.DocumentChangeKind
}

func newRequestManager(factory func(*agent.Request) (io.Closer, error)) *requestManager {
	return &requestManager{
		clients:     map[string]io.Closer{},
		queued:      map[string]queuedChange{},
		running:     map[string]bool{},
		newClient:   factory,
		skipUpgrade: func() bool { return rand.Intn(4) != 0 },
	}
}

func (m *requestManager) count() int {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return len(m.clients)
}

func (m *requestManager) apply(req *agent.Request, kind firestore.DocumentChangeKind) {
	unlock := m.locks.Lock(req.String())
	defer unlock()
	m.applyLocked(req, kind)
}

// submit never blocks the snapshot loop: a slow join on one channel must not
// stall every other channel (or fail the health check while it waits).
func (m *requestManager) submit(req *agent.Request, kind firestore.DocumentChangeKind) {
	key := req.String()
	m.queueMu.Lock()
	m.queued[key] = queuedChange{req: req, kind: kind}
	if m.running[key] {
		m.queueMu.Unlock()
		return
	}
	m.running[key] = true
	m.pending.Add(1)
	m.queueMu.Unlock()

	go func() {
		defer m.pending.Done()
		for {
			m.queueMu.Lock()
			change, ok := m.queued[key]
			if !ok {
				delete(m.running, key)
				m.queueMu.Unlock()
				return
			}
			delete(m.queued, key)
			m.queueMu.Unlock()
			m.apply(change.req, change.kind)
		}
	}()
}

func (m *requestManager) applyLocked(req *agent.Request, kind firestore.DocumentChangeKind) {
	m.mu.RLock()
	existing := m.clients[req.String()]
	m.mu.RUnlock()
	if kind == firestore.DocumentRemoved {
		m.mu.Lock()
		delete(m.clients, req.String())
		m.mu.Unlock()
		if existing != nil {
			if err := existing.Close(); err != nil {
				zap.L().Error("failed to close request", zap.Error(err))
			}
		}
		return
	}
	if req.Provider() != agent.ProviderTwitch {
		return
	}
	if _, ok := existing.(*handler.AuthenticatedTwitchClient); ok && m.skipUpgrade() {
		zap.L().Info("already authenticated", zap.String("id", req.String()))
		return
	}
	client, err := m.newClient(req)
	if err != nil {
		zap.L().Error("failed to open request", zap.Error(err))
		return
	}
	m.mu.Lock()
	m.clients[req.String()] = client
	m.mu.Unlock()
	if existing != nil {
		if err := existing.Close(); err != nil {
			zap.L().Error("failed to close request", zap.Error(err))
		}
	}
}
