package eventsubmigration

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"time"
)

type Locker func(context.Context, string, func(context.Context) error) error
type Migrator struct {
	API           *API
	Snapshot      Snapshot
	Checkpoint    Checkpoint
	Save          func(Checkpoint) error
	Lock          Locker
	Secret        string
	VerifyTimeout time.Duration
	PollInterval  time.Duration
}

func active(status string) bool {
	return status == "enabled" || status == "webhook_callback_verification_pending"
}
func Eligible(sub Subscription) bool {
	return sub.Transport.Method == "webhook" && (sub.Transport.Callback == LegacyCallback || sub.Transport.Callback == AliasCallback) && active(sub.Status)
}
func (s Snapshot) Planned() []Subscription {
	var plan []Subscription
	for _, sub := range s.Subscriptions {
		if Eligible(sub) {
			plan = append(plan, sub)
		}
	}
	return plan
}
func canonical(condition json.RawMessage) []byte {
	var value interface{}
	decoder := json.NewDecoder(bytes.NewReader(condition))
	decoder.UseNumber()
	if decoder.Decode(&value) != nil {
		return nil
	}
	data, _ := json.Marshal(value)
	return data
}
func same(a, b Subscription) bool {
	return a.Type == b.Type && a.Version == b.Version && bytes.Equal(canonical(a.Condition), canonical(b.Condition))
}
func find(list []Subscription, wanted Subscription, callback string) *Subscription {
	var pending *Subscription
	for _, sub := range list {
		if sub.Transport.Method != "webhook" || sub.Transport.Callback != callback || !same(sub, wanted) {
			continue
		}
		if sub.Status == "enabled" {
			found := sub
			return &found
		}
		if sub.Status == "webhook_callback_verification_pending" {
			found := sub
			pending = &found
		}
	}
	return pending
}
func byID(list []Subscription, id string) *Subscription {
	for _, sub := range list {
		if sub.ID == id {
			found := sub
			return &found
		}
	}
	return nil
}
func conditionUser(sub Subscription) string {
	var condition map[string]json.RawMessage
	json.Unmarshal(sub.Condition, &condition)
	for _, key := range []string{"broadcaster_user_id", "to_broadcaster_user_id", "from_broadcaster_user_id", "user_id", "moderator_user_id"} {
		var id string
		if json.Unmarshal(condition[key], &id) == nil && id != "" {
			return id
		}
	}
	return ""
}
func query(sub Subscription) url.Values {
	if id := conditionUser(sub); id != "" {
		return url.Values{"user_id": {id}}
	}
	return url.Values{"type": {sub.Type}}
}
func (m *Migrator) originalID(id string) bool {
	for _, sub := range m.Snapshot.Subscriptions {
		if sub.ID == id {
			return true
		}
	}
	return false
}
func (m *Migrator) save(id string, progress Progress) error {
	m.Checkpoint.Entries[id] = progress
	return m.Save(m.Checkpoint)
}
func (m *Migrator) Run(ctx context.Context, limit int, rollback bool) (int, error) {
	if err := m.Snapshot.Validate(m.API.ClientID); err != nil {
		return 0, err
	}
	if !rollback {
		for _, sub := range m.Snapshot.Subscriptions {
			if sub.Transport.Method == "webhook" && sub.Transport.Callback == TargetCallback && active(sub.Status) {
				return 0, fmt.Errorf("snapshot contains preexisting destinations with unknown signing-secret compatibility; source subscriptions retained")
			}
		}
	}
	if m.Checkpoint.SnapshotHash != m.Snapshot.hash() || m.Checkpoint.Entries == nil || m.Save == nil || m.Lock == nil {
		return 0, fmt.Errorf("durable checkpoint and distributed lock are required")
	}
	if len(m.Secret) < 10 || len(m.Secret) > 100 {
		return 0, fmt.Errorf("callback signing secret must contain 10 to 100 bytes")
	}
	if limit < 1 {
		return 0, fmt.Errorf("batch limit must be positive")
	}
	processed := 0
	for _, source := range m.Snapshot.Planned() {
		progress := m.Checkpoint.Entries[source.ID]
		if rollback && progress.RolledBack {
			continue
		}
		if !rollback && progress.DeletedOld && !progress.RolledBack {
			continue
		}
		if !rollback && progress.RolledBack {
			return processed, fmt.Errorf("snapshot has rolled-back entries; take a new snapshot before another forward migration")
		}
		if processed >= limit {
			break
		}
		key := "twitch:" + conditionUser(source)
		if key == "twitch:" {
			key = "twitch-eventsub-" + source.ID
		}
		err := m.Lock(ctx, key, func(ctx context.Context) error {
			if rollback {
				return m.rollback(ctx, source)
			}
			return m.forward(ctx, source)
		})
		if err != nil {
			return processed, fmt.Errorf("subscription %s (%s v%s): %w", source.ID, source.Type, source.Version, err)
		}
		processed++
	}
	return processed, nil
}
func (m *Migrator) replacement(ctx context.Context, source Subscription, callback string, listing Listing) (Subscription, bool, error) {
	if existing := find(listing.Data, source, callback); existing != nil {
		return *existing, false, nil
	}
	duplicates := 0
	for _, sub := range listing.Data {
		if sub.Type == source.Type && bytes.Equal(canonical(sub.Condition), canonical(source.Condition)) && active(sub.Status) {
			duplicates++
		}
	}
	if duplicates >= 3 {
		return Subscription{}, false, fmt.Errorf("three-per-type/condition limit has no temporary slot; source retained")
	}
	if listing.MaxTotalCost > 0 && listing.TotalCost+source.Cost > listing.MaxTotalCost {
		return Subscription{}, false, fmt.Errorf("insufficient temporary cost headroom (%d + %d > %d); source retained", listing.TotalCost, source.Cost, listing.MaxTotalCost)
	}
	created, err := m.API.Create(ctx, source, callback, m.Secret)
	if err != nil {
		var response *HTTPError
		if errors.As(err, &response) && response.Status == 409 {
			// A 409 proves a duplicate exists, not that it uses our callback or is
			// enabled. Never interpret the conflict as permission to delete source.
			current, listErr := m.API.List(ctx, query(source))
			if listErr != nil {
				return Subscription{}, false, listErr
			}
			if target := find(current.Data, source, callback); target != nil {
				return *target, false, nil
			}
			return Subscription{}, false, fmt.Errorf("409 without matching destination subscription; source retained")
		}
		return Subscription{}, false, err
	}
	if created.ID == "" || !same(created, source) || created.Transport.Method != "webhook" || created.Transport.Callback != callback || !active(created.Status) {
		return Subscription{}, false, fmt.Errorf("creation response does not match intended replacement; source retained")
	}
	return created, true, nil
}
func (m *Migrator) enabled(ctx context.Context, wanted Subscription, callback string) error {
	timeout := m.VerifyTimeout
	if timeout <= 0 {
		timeout = 30 * time.Second
	}
	interval := m.PollInterval
	if interval <= 0 {
		interval = time.Second
	}
	verify, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	for {
		listing, err := m.API.List(verify, url.Values{"subscription_id": {wanted.ID}})
		if err != nil {
			return fmt.Errorf("replacement verification failed; source retained: %w", err)
		}
		if current := byID(listing.Data, wanted.ID); current != nil {
			if !same(*current, wanted) || current.Transport.Method != "webhook" || current.Transport.Callback != callback {
				return fmt.Errorf("replacement identity changed; source retained")
			}
			if current.Status == "enabled" {
				return nil
			}
			if !active(current.Status) {
				return fmt.Errorf("replacement status %s; source retained", current.Status)
			}
		}
		if err = m.API.sleep(verify, interval); err != nil {
			return fmt.Errorf("replacement did not become enabled; source retained: %w", err)
		}
	}
}
func (m *Migrator) forward(ctx context.Context, source Subscription) error {
	listing, err := m.API.List(ctx, query(source))
	if err != nil {
		return err
	}
	current := byID(listing.Data, source.ID)
	if current != nil && (!same(*current, source) || current.Transport.Method != "webhook" || current.Transport.Callback != source.Transport.Callback) {
		return fmt.Errorf("source no longer matches backed-up descriptor")
	}
	target, created, err := m.replacement(ctx, source, TargetCallback, listing)
	if err != nil {
		return err
	}
	// Twitch omits signing secrets from GET responses. A destination that
	// predates the snapshot may still be signed with the legacy OAuth secret;
	// its enabled status cannot prove compatibility with the agent verifier.
	if m.originalID(target.ID) {
		return fmt.Errorf("destination predates migration; signing-secret compatibility is unknown; source retained")
	}
	progress := m.Checkpoint.Entries[source.ID]
	progress.TargetID = target.ID
	progress.Created = progress.Created || created || !m.originalID(target.ID)
	if err = m.save(source.ID, progress); err != nil {
		return fmt.Errorf("replacement exists but checkpoint failed; source retained: %w", err)
	}
	if err = m.enabled(ctx, target, TargetCallback); err != nil {
		return err
	}
	// Re-read source identity immediately before deletion; IDs and descriptors
	// are checked, so neither unrelated callbacks nor new IDs are deleted.
	live, err := m.API.List(ctx, url.Values{"subscription_id": {source.ID}})
	if err != nil {
		return err
	}
	if current = byID(live.Data, source.ID); current != nil {
		if !same(*current, source) || current.Transport.Method != "webhook" || current.Transport.Callback != source.Transport.Callback {
			return fmt.Errorf("source changed before deletion")
		}
		if err = m.API.Delete(ctx, source.ID); err != nil {
			return err
		}
	}
	progress.DeletedOld = true
	return m.save(source.ID, progress)
}
func (m *Migrator) rollback(ctx context.Context, source Subscription) error {
	listing, err := m.API.List(ctx, query(source))
	if err != nil {
		return err
	}
	progress := m.Checkpoint.Entries[source.ID]
	ownedReplacement := false
	for _, sub := range listing.Data {
		if sub.Transport.Method == "webhook" && sub.Transport.Callback == TargetCallback && same(sub, source) && !m.originalID(sub.ID) {
			ownedReplacement = true
			break
		}
	}
	if !progress.Created && !progress.DeletedOld && !ownedReplacement {
		// No evidence that this migration touched the descriptor. Do not resurrect
		// an original that disappeared independently after the backup.
		progress.RolledBack = true
		return m.save(source.ID, progress)
	}
	destination, _, err := m.replacement(ctx, source, source.Transport.Callback, listing)
	if err != nil {
		return err
	}
	if err = m.enabled(ctx, destination, source.Transport.Callback); err != nil {
		return err
	}
	// Only replacements absent from the original backup are rollback-owned.
	// A destination that predated this migration must be preserved.
	for _, sub := range listing.Data {
		if sub.Transport.Method != "webhook" || sub.Transport.Callback != TargetCallback || !same(sub, source) || m.originalID(sub.ID) {
			continue
		}
		live, err := m.API.List(ctx, url.Values{"subscription_id": {sub.ID}})
		if err != nil {
			return err
		}
		current := byID(live.Data, sub.ID)
		if current == nil {
			continue
		}
		if !same(*current, source) || current.Transport.Method != "webhook" || current.Transport.Callback != TargetCallback {
			return fmt.Errorf("rollback source identity changed")
		}
		if err = m.API.Delete(ctx, sub.ID); err != nil {
			return err
		}
	}
	progress = m.Checkpoint.Entries[source.ID]
	progress.RolledBack = true
	return m.save(source.ID, progress)
}

// VerifyCompleted audits every checkpointed destination against live state.
// A completed checkpoint never substitutes for provider health verification.
func (m *Migrator) VerifyCompleted(live []Subscription) error {
	for _, source := range m.Snapshot.Planned() {
		progress := m.Checkpoint.Entries[source.ID]
		if !progress.DeletedOld || progress.RolledBack {
			continue
		}
		target := byID(live, progress.TargetID)
		if target == nil || !same(*target, source) || target.Transport.Method != "webhook" || target.Transport.Callback != TargetCallback || target.Status != "enabled" {
			return fmt.Errorf("completed destination %s is missing, changed, or not enabled; do not retire legacy receiver", progress.TargetID)
		}
	}
	return nil
}
