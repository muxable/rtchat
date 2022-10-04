package agent

import (
	"crypto/sha1"
	"sort"
)

type AgentID string

type AgentIDs []AgentID

func cmp(a, b [20]byte) int {
	for i := 0; i < len(a); i++ {
		if a[i] < b[i] {
			return -1
		} else if a[i] > b[i] {
			return 1
		}
	}
	return 0
}

func (a AgentID) Hash() [20]byte {
	return sha1.Sum([]byte(a))
}

func (a AgentIDs) CanonicalAgentIDFor(key string) AgentID {
	// The canonical agent id is defined as the agent id whose sha1 hash
	// exceeds the sha1 hash of the key. If no such agent id exists, the
	// lowest agent id is returned.
	keyHash := sha1.Sum([]byte(key))
	sort.Slice(a, func(i, j int) bool {
		return cmp(a[i].Hash(), a[j].Hash()) < 0
	})
	for _, id := range a {
		if cmp(id.Hash(), keyHash) > 0 {
			return id
		}
	}
	return a[0]
}

func AgentIDsForDocument(doc map[string]interface{}) AgentIDs {
	if doc["agentIDs"] == nil {
		return nil
	}
	agentIDs := doc["agentIDs"].([]interface{})
	ids := make(AgentIDs, len(agentIDs))
	for i, id := range agentIDs {
		ids[i] = AgentID(id.(string))
	}
	return ids
}