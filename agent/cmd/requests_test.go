package main

import (
	"fmt"
	"io"
	"sync"
	"testing"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/agent"
	"github.com/muxable/rtchat/agent/internal/handler"
)

type closer struct {
	calls int
	err   error
}

func (c *closer) Close() error { c.calls++; return c.err }

func request(id string) *agent.Request { return (*agent.Request)(&firestore.DocumentRef{ID: id}) }

func TestClientsConcurrentAccess(t *testing.T) {
	m := newRequestManager(func(*agent.Request) (io.Closer, error) { return &closer{}, nil })
	var wg sync.WaitGroup
	for i := 0; i < 4; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			for j := 0; j < 20; j++ {
				m.apply(request(fmt.Sprintf("twitch:%d-%d", i, j)), firestore.DocumentAdded)
				m.count()
			}
		}(i)
	}
	wg.Wait()
	if m.count() != 80 {
		t.Fatal(m.count())
	}
}

func TestRemovedClosesClient(t *testing.T) {
	c := &closer{}
	m := newRequestManager(func(*agent.Request) (io.Closer, error) { return c, nil })
	r := request("twitch:room")
	m.apply(r, firestore.DocumentAdded)
	m.apply(r, firestore.DocumentRemoved)
	if c.calls != 1 || m.count() != 0 {
		t.Fatalf("close calls=%d count=%d", c.calls, m.count())
	}
}

func TestAuthenticatedClientUpgradesAreThrottled(t *testing.T) {
	calls := 0
	m := newRequestManager(func(*agent.Request) (io.Closer, error) { calls++; return &closer{}, nil })
	m.clients["twitch:room"] = &handler.AuthenticatedTwitchClient{}
	m.skipUpgrade = func() bool { return true }
	m.apply(request("twitch:room"), firestore.DocumentModified)
	if calls != 0 {
		t.Fatal("reconnected an authenticated client on a skipped update")
	}
}

func TestAnonymousClientsAreAlwaysUpgraded(t *testing.T) {
	calls := 0
	m := newRequestManager(func(*agent.Request) (io.Closer, error) { calls++; return &closer{}, nil })
	old := &closer{}
	m.clients["twitch:room"] = old
	m.skipUpgrade = func() bool { return true }
	m.apply(request("twitch:room"), firestore.DocumentModified)
	if calls != 1 || old.calls != 1 {
		t.Fatalf("calls = %d, closed = %d; want the client replaced", calls, old.calls)
	}
}

func TestSlowJoinDoesNotBlockOtherChannels(t *testing.T) {
	release := make(chan struct{})
	opened := make(chan string, 2)
	m := newRequestManager(func(r *agent.Request) (io.Closer, error) {
		if r.String() == "twitch:slow" {
			<-release
		}
		opened <- r.String()
		return &closer{}, nil
	})
	m.submit(request("twitch:slow"), firestore.DocumentAdded)
	m.submit(request("twitch:slow"), firestore.DocumentModified)
	m.submit(request("twitch:fast"), firestore.DocumentAdded)
	if got := <-opened; got != "twitch:fast" {
		t.Fatalf("opened %s first; the slow join blocked submit", got)
	}
	close(release)
	m.pending.Wait()
	if m.count() != 2 {
		t.Fatalf("count = %d, want 2", m.count())
	}
}

func TestKeyedMutexReleasesEntries(t *testing.T) {
	var m KeyedMutex
	for i := 0; i < 100; i++ {
		m.Lock(fmt.Sprint(i))()
	}
	n := 0
	m.mutexes.Range(func(_, _ interface{}) bool { n++; return true })
	if n != 0 {
		t.Fatalf("retained %d idle locks", n)
	}
}

func TestSnapshotChangesStayOrdered(t *testing.T) {
	m := newRequestManager(func(*agent.Request) (io.Closer, error) { return &closer{}, nil })
	for i := 0; i < 200; i++ {
		r := request(fmt.Sprintf("twitch:room%d", i))
		m.submit(r, firestore.DocumentAdded)
		m.submit(r, firestore.DocumentRemoved)
	}
	m.pending.Wait()
	if m.count() != 0 {
		t.Fatalf("%d removed channels resurrected by reordered goroutines", m.count())
	}
}

func TestReplacementPreservesOldClientOnFailure(t *testing.T) {
	want := fmt.Errorf("fake join failed")
	old := &closer{}
	m := newRequestManager(func(*agent.Request) (io.Closer, error) { return nil, want })
	m.clients["twitch:room"] = old
	m.apply(request("twitch:room"), firestore.DocumentModified)
	if old.calls != 0 || m.clients["twitch:room"] != old {
		t.Fatal("working client lost on failed replacement")
	}
}

func TestReplacementCloseErrorKeepsNewClient(t *testing.T) {
	old := &closer{err: fmt.Errorf("close failed")}
	next := &closer{}
	m := newRequestManager(func(*agent.Request) (io.Closer, error) { return next, nil })
	m.clients["twitch:room"] = old
	m.apply(request("twitch:room"), firestore.DocumentModified)
	if old.calls != 1 || m.clients["twitch:room"] != next {
		t.Fatal("bad replacement")
	}
	m.apply(request("twitch:room"), firestore.DocumentRemoved)
	if next.calls != 1 || m.count() != 0 {
		t.Fatal("bad removal")
	}
}

func TestKeyedMutexSerializesWaiters(t *testing.T) {
	var m KeyedMutex
	var wg sync.WaitGroup
	active := 0
	for i := 0; i < 12; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for j := 0; j < 100; j++ {
				unlock := m.Lock("same")
				active++
				if active != 1 {
					t.Error("overlapping critical sections")
				}
				active--
				unlock()
			}
		}()
	}
	wg.Wait()
	if _, ok := m.mutexes.Load("same"); ok {
		t.Fatal("idle entry retained")
	}
}

func TestYouTubeReaderIsKeptAcrossAssignmentUpdates(t *testing.T) {
	calls := 0
	m := newRequestManager(func(*agent.Request) (io.Closer, error) { calls++; return &closer{}, nil })
	m.apply(request("youtube:UCchannel"), firestore.DocumentAdded)
	m.apply(request("youtube:UCchannel"), firestore.DocumentModified)
	if calls != 1 {
		t.Fatalf("reader started %d times, want 1", calls)
	}
	m.apply(request("youtube:UCchannel"), firestore.DocumentRemoved)
	if m.count() != 0 {
		t.Fatal("removed youtube assignment kept its reader")
	}
}
