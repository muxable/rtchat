package agent

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"cloud.google.com/go/firestore"
	"go.uber.org/zap"
	"google.golang.org/api/compute/v1"
	"google.golang.org/api/iterator"
)

func RunWatchdog(ctx context.Context, agentID AgentID, client *firestore.Client) {
	gcp, err := compute.NewService(context.Background())
	if err != nil {
		zap.L().Error("failed to create compute client", zap.Error(err))
		return
	}

	// register ourselves as an agent
	agentRef := client.Collection("agents").Doc(string(agentID))
	
	agentRef.Set(context.Background(), map[string]interface{}{"createdAt": firestore.ServerTimestamp})

	lock := &sync.Mutex{}
	knownAgents := make(map[string]struct{})

	go func() {
		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()
		for range ticker.C {
			if ctx.Err() != nil {
				return
			}
			resp, err := gcp.Instances.AggregatedList("rtchat-47692").Do()
			if err != nil {
				zap.L().Error("failed to query for instance", zap.Error(err))
				continue
			}
			lock.Lock()
			for foreignAgentID := range knownAgents {
				found := false
				for _, items := range resp.Items {
					for _, instance := range items.Instances {
						if fmt.Sprintf("%d", instance.Id) == foreignAgentID {
							found = true
							break
						}
					}
					if found {
						break
					}
				}
				if !found {
					zap.L().Info("agent is not running according to GCP", zap.String("agentID", foreignAgentID))
					delete(knownAgents, foreignAgentID)
					// delete the agent
					if _, err := client.Collection("agents").Doc(foreignAgentID).Delete(context.Background()); err != nil {
						zap.L().Error("failed to delete agent", zap.Error(err))
					}
					// delete all assignments
					assignments, err := client.Collection("assignments").Where("agentIds", "array-contains", foreignAgentID).Documents(context.Background()).GetAll()
					if err != nil {
						zap.L().Error("failed to query for assignments", zap.Error(err))
						continue
					}
					for _, assignment := range assignments {
						if _, err := assignment.Ref.Update(context.Background(), []firestore.Update{
							{Path: "agentIds", Value: firestore.ArrayRemove(foreignAgentID)},
						}); err != nil {
							zap.L().Error("failed to update assignment", zap.Error(err))
						}
					}
				}
			}
			lock.Unlock()
		}
	}()

	// query for all agents
	snapshots := client.Collection("agents").Snapshots(ctx)
	for {
		snapshot, err := snapshots.Next()
		if err != nil {
			if errors.Is(err, iterator.Done) {
				break
			}
			zap.L().Error("failed to query for agents", zap.Error(err))
			return
		}
		docs, err := snapshot.Documents.GetAll()
		if err != nil {
			zap.L().Error("failed to get all documents", zap.Error(err))
			continue
		}
		
		for _, doc := range docs {
			if doc.Ref.ID == string(agentID) || strings.HasPrefix(doc.Ref.ID, "pseudo:") {
				continue
			}

			lock.Lock()
			knownAgents[doc.Ref.ID] = struct{}{}
			lock.Unlock()
		}
	}

	// unregister ourselves as an agent
	if _, err := agentRef.Delete(context.Background()); err != nil {
		zap.L().Error("failed to delete agent", zap.Error(err))
	}
}