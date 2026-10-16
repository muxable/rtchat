package main

import (
	"context"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/muxable/rtchat/agent/internal/auth"
	"github.com/muxable/rtchat/agent/internal/jobs"
	"github.com/muxable/rtchat/agent/internal/provider"
	"go.uber.org/zap"
)

// The allowlist keeps old Cloud Scheduler jobs authoritative until cutover.
// Empty AGENT_SCHEDULED_JOBS leaves all replacement jobs disabled.
func startScheduledJobs(ctx context.Context, db *firestore.Client) func() {
	service := &jobs.Service{Client: db, API: &jobs.API{Tokens: provider.NewService(db, &http.Client{Timeout: 15 * time.Second}), TwitchClientID: auth.TwitchClientID()}}
	all := map[string]jobs.Job{
		"updateFollowerAndViewerCount": {Name: "updateFollowerAndViewerCount", Timeout: 3 * time.Minute, Run: service.Twitch},
		"updateKickChannelMetadata":    {Name: "updateKickChannelMetadata", Timeout: 3 * time.Minute, Run: service.Kick},
		"unsubscribe":                  {Name: "unsubscribe", Timeout: 30 * time.Minute, Daily: true, Run: service.Cleanup},
	}
	runner := jobs.Runner{Leases: jobs.FirestoreLeases{Client: db}}
	seen := map[string]bool{}
	for _, name := range strings.Split(os.Getenv("AGENT_SCHEDULED_JOBS"), ",") {
		name = strings.TrimSpace(name)
		if name == "" || seen[name] {
			continue
		}
		job, ok := all[name]
		if !ok {
			zap.L().Error("unknown scheduled job disabled", zap.String("job", name))
			continue
		}
		seen[name] = true
		runner.Jobs = append(runner.Jobs, job)
	}
	work, cancel := context.WithCancel(ctx)
	var wg sync.WaitGroup
	if len(runner.Jobs) > 0 {
		wg.Add(1)
		go func() { defer wg.Done(); runner.Run(work) }()
	}
	return func() { cancel(); wg.Wait() }
}
