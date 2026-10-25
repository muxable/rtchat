package jobs

import (
	"strings"
	"sync"
	"time"

	"cloud.google.com/go/firestore"
)

// Assignments mirrors the assignments collection from the listener main
// already runs, so the metadata job does not re-read every document per run.
type Assignments struct {
	mu    sync.Mutex
	ids   map[string]struct{}
	ready bool
}

// Apply records one snapshot's changes. The first call marks the set ready.
func (a *Assignments) Apply(changes []firestore.DocumentChange) {
	a.mu.Lock()
	defer a.mu.Unlock()
	if a.ids == nil {
		a.ids = map[string]struct{}{}
	}
	for _, change := range changes {
		if change.Kind == firestore.DocumentRemoved {
			delete(a.ids, change.Doc.Ref.ID)
		} else {
			a.ids[change.Doc.Ref.ID] = struct{}{}
		}
	}
	a.ready = true
}

// Logins returns the assigned channel names with prefix, or false before the
// first snapshot arrives.
func (a *Assignments) Logins(prefix string) ([]string, bool) {
	if a == nil {
		return nil, false
	}
	a.mu.Lock()
	defer a.mu.Unlock()
	if !a.ready {
		return nil, false
	}
	var logins []string
	for id := range a.ids {
		if strings.HasPrefix(id, prefix) {
			logins = append(logins, strings.TrimPrefix(id, prefix))
		}
	}
	return logins, true
}

// cacheTTL bounds how long a channel can go without a transactional check,
// in case another writer changed it to a value the poll no longer reports.
const cacheTTL = 30 * time.Minute

type cachedChannel struct {
	data    map[string]interface{}
	checked time.Time
}

// channelCache remembers each channel doc as of this replica's last
// transaction, so polls that report the same values skip the transaction.
type channelCache struct {
	mu       sync.Mutex
	channels map[string]cachedChannel
	// completed is the last slot this replica's run of the job succeeded in.
	completed string
}

// begin clears the cache unless this replica completed the slot just before
// slot. Otherwise another replica may have run it and written values this
// replica has not seen.
func (c *channelCache) begin(slot string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if slot == "" || c.completed == "" || c.completed != previousSlot(slot) {
		c.channels = nil
	}
	c.completed = ""
}

// end keeps the cache for the next slot only if the runner recorded this run
// as a success, since a failed run may be retried by another replica.
func (c *channelCache) end(slot string, success bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if !success || slot == "" {
		c.channels = nil
		c.completed = ""
		return
	}
	c.completed = slot
	now := time.Now()
	for id, channel := range c.channels {
		if now.Sub(channel.checked) > cacheTTL {
			delete(c.channels, id)
		}
	}
}

// previousSlot returns the 4-minute slot before slot, or "" if slot is not one.
func previousSlot(slot string) string {
	at, err := time.Parse(time.RFC3339, slot)
	if err != nil {
		return ""
	}
	return Slot(at.Add(-slotLength), false)
}

func (c *channelCache) fresh(id string, data map[string]interface{}, now time.Time) bool {
	if c == nil {
		return false
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	channel, ok := c.channels[id]
	return ok && now.Sub(channel.checked) <= cacheTTL && unchanged(channel.data, data)
}

func (c *channelCache) store(id string, data map[string]interface{}, checked time.Time) {
	if c == nil {
		return
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	if data == nil {
		delete(c.channels, id)
		return
	}
	if c.channels == nil {
		c.channels = map[string]cachedChannel{}
	}
	c.channels[id] = cachedChannel{data, checked}
}
