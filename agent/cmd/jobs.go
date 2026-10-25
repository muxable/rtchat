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

// AGENT_SCHEDULED_JOBS is a comma-separated allowlist. Unset runs every job;
// leases keep each to one replica. Set but empty disables them all.
func startScheduledJobs(ctx context.Context, db *firestore.Client, assignments *jobs.Assignments) func() {
	// One client for every job request, so connections are reused.
	httpClient := &http.Client{Timeout: 15 * time.Second}
	service := &jobs.Service{Client: db, API: &jobs.API{Tokens: provider.NewService(db, httpClient), Client: httpClient, TwitchClientID: auth.TwitchClientID()}, Assignments: assignments}
	all := map[string]jobs.Job{
		"updateFollowerAndViewerCount": {Name: "updateFollowerAndViewerCount", Timeout: 3 * time.Minute, Run: service.Twitch, Finished: service.TwitchFinished},
		"updateKickChannelMetadata":    {Name: "updateKickChannelMetadata", Timeout: 3 * time.Minute, Run: service.Kick, Finished: service.KickFinished},
		"unsubscribe":                  {Name: "unsubscribe", Timeout: 30 * time.Minute, Daily: true, Run: service.Cleanup},
	}
	runner := jobs.Runner{Leases: jobs.FirestoreLeases{Client: db}}
	if names, ok := os.LookupEnv("AGENT_SCHEDULED_JOBS"); ok {
		seen := map[string]bool{}
		for _, name := range strings.Split(names, ",") {
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
	} else {
		for _, job := range all {
			runner.Jobs = append(runner.Jobs, job)
		}
	}
	work, cancel := context.WithCancel(ctx)
	var wg sync.WaitGroup
	if len(runner.Jobs) > 0 {
		wg.Add(1)
		go func() { defer wg.Done(); runner.Run(work) }()
	}
	return func() { cancel(); wg.Wait() }
}
