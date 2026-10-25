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

const (
	// cacheTTL bounds how long a channel can go without a transactional
	// check, in case another writer changed it to a value the poll no longer
	// reports.
	cacheTTL = 30 * time.Minute
	// cacheGap is the longest gap between this replica's runs for which the
	// cache stays valid. A longer gap means another replica may have run a
	// slot and written values this replica has not seen.
	cacheGap = 6 * time.Minute
)

type cachedChannel struct {
	data    map[string]interface{}
	checked time.Time
}

// channelCache remembers each channel doc as of this replica's last
// transaction, so polls that report the same values skip the transaction.
type channelCache struct {
	mu       sync.Mutex
	channels map[string]cachedChannel
	lastRun  time.Time
}

// begin clears the cache unless this replica also ran the previous slot.
func (c *channelCache) begin(started time.Time) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.lastRun.IsZero() || started.Sub(c.lastRun) > cacheGap {
		c.channels = nil
	}
	c.lastRun = time.Time{}
}

// end keeps the cache for the next run only if this one succeeded, since a
// failed run may have been taken over by another replica.
func (c *channelCache) end(started time.Time, err error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if err != nil {
		c.channels = nil
		return
	}
	c.lastRun = started
	for id, channel := range c.channels {
		if started.Sub(channel.checked) > cacheTTL {
			delete(c.channels, id)
		}
	}
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
