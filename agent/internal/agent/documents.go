package agent

import "cloud.google.com/go/firestore"

type DocumentIterator interface {
	Next() (*firestore.DocumentSnapshot, error)
	Stop()
}

func FirstDocument(iter DocumentIterator) (*firestore.DocumentSnapshot, error) {
	defer iter.Stop()
	return iter.Next()
}
