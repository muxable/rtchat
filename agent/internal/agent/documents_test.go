package agent

import (
	"errors"
	"testing"

	"cloud.google.com/go/firestore"
)

type fakeIterator struct {
	stopped bool
	err     error
}

func (i *fakeIterator) Next() (*firestore.DocumentSnapshot, error) { return nil, i.err }

func (i *fakeIterator) Stop() { i.stopped = true }

func TestFirstDocumentStopsIterator(t *testing.T) {
	for _, err := range []error{nil, errors.New("query failed")} {
		i := &fakeIterator{err: err}
		_, got := FirstDocument(i)
		if !errors.Is(got, err) || !i.stopped {
			t.Fatalf("err=%v stopped=%v", got, i.stopped)
		}
	}
}
