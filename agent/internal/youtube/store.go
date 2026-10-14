package youtube

import (
	"context"
	"time"

	"cloud.google.com/go/firestore"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// Store isolates message persistence and transactional reader ownership.
// Lease renewals use Acquire: absent, expired, or our own leases may be acquired.
type Store interface {
	Create(context.Context, string, string, map[string]interface{}) error
	SetOnline(context.Context, string, *time.Time) error
	Acquire(context.Context, string, string, time.Time, time.Time) (bool, error)
	Release(context.Context, string, string) error
}

type FirestoreStore struct{ Client *firestore.Client }

func (s *FirestoreStore) Create(ctx context.Context, channel, id string, data map[string]interface{}) error {
	_, err := s.Client.Collection("channels").Doc(channel).Collection("messages").Doc(id).Create(ctx, data)
	if status.Code(err) == codes.AlreadyExists {
		return nil
	}
	return err
}

func (s *FirestoreStore) SetOnline(ctx context.Context, channel string, at *time.Time) error {
	var value interface{}
	if at != nil {
		value = *at
	}
	_, err := s.Client.Collection("channels").Doc(channel).Set(ctx, map[string]interface{}{"onlineAt": value}, firestore.MergeAll)
	return err
}

func (s *FirestoreStore) Acquire(ctx context.Context, channel, owner string, now, expires time.Time) (bool, error) {
	ref := s.Client.Collection("youtube-readers").Doc(channel)
	acquired := false
	err := s.Client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		acquired = false // Firestore may retry the callback.
		doc, err := tx.Get(ref)
		if err != nil && status.Code(err) != codes.NotFound {
			return err
		}
		if err == nil {
			currentOwner, _ := doc.Data()["owner"].(string)
			expiry, _ := doc.Data()["expiresAt"].(time.Time)
			if !leaseAvailable(currentOwner, owner, expiry, now) {
				return nil
			}
		}
		if err := tx.Set(ref, map[string]interface{}{"owner": owner, "expiresAt": expires}); err != nil {
			return err
		}
		acquired = true
		return nil
	})
	return acquired, err
}

func (s *FirestoreStore) Release(ctx context.Context, channel, owner string) error {
	ref := s.Client.Collection("youtube-readers").Doc(channel)
	return s.Client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		doc, err := tx.Get(ref)
		if status.Code(err) == codes.NotFound {
			return nil
		}
		if err != nil {
			return err
		}
		if doc.Data()["owner"] != owner {
			return nil
		}
		return tx.Delete(ref)
	})
}

// leaseAvailable is shared by acquisition and renewal; foreign ownership only
// blocks readers until expiry. Release separately checks the current owner.
func leaseAvailable(current, owner string, expiry, now time.Time) bool {
	return current == owner || !expiry.After(now)
}
