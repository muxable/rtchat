// migrate-eventsub defaults to a read-only plan plus an immutable descriptor
// backup. Provider mutations require --apply; a saved plan uses --resume.
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"cloud.google.com/go/firestore"
	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
	"github.com/muxable/rtchat/agent/internal/eventsubmigration"
	"github.com/muxable/rtchat/agent/internal/provider"
	"github.com/muxable/rtchat/agent/internal/subscriptionlock"
)

type options struct {
	project, backup                             string
	apply, resume, rollback, verify, retry, all bool
	limit, rate, reserve, maxAttempts           int
	timeout                                     time.Duration
}

func parse(args []string) (options, error) {
	var o options
	flags := flag.NewFlagSet("migrate-eventsub", flag.ContinueOnError)
	flags.StringVar(&o.project, "project", "rtchat-47692", "Google Cloud project for OAuth/signing secrets and lifecycle leases")
	flags.StringVar(&o.backup, "backup", "eventsub-migration.json", "immutable descriptor backup; checkpoint is <backup>.state.json plus <backup>.journal.jsonl")
	flags.BoolVar(&o.apply, "apply", false, "create replacements, verify enabled, then delete allowlisted sources")
	flags.BoolVar(&o.resume, "resume", false, "resume the existing backup/checkpoint instead of taking a new backup")
	flags.BoolVar(&o.rollback, "rollback", false, "restore snapshot legacy callback, then remove migration-created replacements; requires --resume")
	flags.IntVar(&o.limit, "limit", 20, "maximum subscriptions to attempt in this invocation; 0 means no limit")
	flags.BoolVar(&o.all, "all", false, "no limit: attempt every remaining subscription (same as --limit 0)")
	flags.IntVar(&o.rate, "rate", 150, "Helix requests per minute, applied to every request including listings")
	flags.IntVar(&o.reserve, "reserve", 200, "pause until Ratelimit-Reset when fewer app-token points remain")
	flags.IntVar(&o.maxAttempts, "max-attempts", 3, "skip subscriptions that already failed this many times")
	flags.BoolVar(&o.retry, "retry-failed", false, "also retry subscriptions that reached --max-attempts")
	flags.BoolVar(&o.verify, "verify", false, "after the run, list every subscription (~1,800 requests) to audit completed destinations and count legacy ones")
	flags.DurationVar(&o.timeout, "timeout", 30*time.Minute, "overall invocation deadline (up to 168h)")
	if err := flags.Parse(args); err != nil {
		return o, err
	}
	if o.all {
		o.limit = 0
	}
	if flags.NArg() != 0 || o.backup == "" || o.project == "" || o.limit < 0 || o.timeout <= 0 || o.timeout > 168*time.Hour || o.rate < 1 || o.rate > 800 || o.reserve < 0 || o.maxAttempts < 1 {
		return o, fmt.Errorf("invalid arguments")
	}
	if o.project != "rtchat-47692" {
		return o, fmt.Errorf("shared provider credentials are scoped to rtchat-47692; refusing another project")
	}
	if o.rollback && !o.resume {
		return o, fmt.Errorf("--rollback requires --resume and the original backup")
	}
	return o, nil
}
func signingSecret(ctx context.Context, project string) (string, error) {
	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		return "", err
	}
	defer client.Close()
	result, err := client.AccessSecretVersion(ctx, &secretmanagerpb.AccessSecretVersionRequest{Name: "projects/" + project + "/secrets/twitch-eventsub-secret/versions/latest"})
	if err != nil {
		return "", err
	}
	return string(result.GetPayload().GetData()), nil
}

// lastActive reads channels/twitch:<id>.lastActiveAt for each broadcaster.
func lastActive(ctx context.Context, db *firestore.Client, ids []string) (map[string]time.Time, error) {
	activity := map[string]time.Time{}
	for start := 0; start < len(ids); start += 300 {
		end := min(start+300, len(ids))
		refs := make([]*firestore.DocumentRef, 0, end-start)
		for _, id := range ids[start:end] {
			refs = append(refs, db.Collection("channels").Doc("twitch:"+id))
		}
		docs, err := db.GetAll(ctx, refs)
		if err != nil {
			return nil, err
		}
		for i, doc := range docs {
			if !doc.Exists() {
				continue
			}
			if at, ok := doc.Data()["lastActiveAt"].(time.Time); ok {
				activity[ids[start+i]] = at
			}
		}
	}
	return activity, nil
}

type runtime struct {
	LoadAPI       func(context.Context) (*eventsubmigration.API, string, error)
	SigningSecret func(context.Context) (string, error)
	Lock          func(context.Context) (eventsubmigration.Locker, func(), error)
	Activity      func(context.Context, []string) (map[string]time.Time, error)
}

func run(ctx context.Context, args []string, output io.Writer) error {
	client := &http.Client{Timeout: 10 * time.Second}
	tokens := provider.NewService(nil, client)
	return runWith(ctx, args, output, runtime{
		LoadAPI: func(ctx context.Context) (*eventsubmigration.API, string, error) {
			credentials, err := tokens.Credentials(ctx, "twitch")
			if err != nil {
				return nil, "", fmt.Errorf("load Twitch credentials: %w", err)
			}
			token, err := tokens.AppAccessToken(ctx, "twitch")
			if err != nil {
				return nil, "", fmt.Errorf("obtain Twitch app token: %w", err)
			}
			return &eventsubmigration.API{Client: client, ClientID: credentials.ClientID, Token: token}, credentials.ClientSecret, nil
		},
		SigningSecret: func(ctx context.Context) (string, error) { return signingSecret(ctx, "rtchat-47692") },
		Lock: func(ctx context.Context) (eventsubmigration.Locker, func(), error) {
			db, err := firestore.NewClient(ctx, "rtchat-47692")
			if err != nil {
				return nil, nil, err
			}
			return func(ctx context.Context, key string, work func(context.Context) error) error {
				return subscriptionlock.With(ctx, db, key, work)
			}, func() { db.Close() }, nil
		},
		Activity: func(ctx context.Context, ids []string) (map[string]time.Time, error) {
			db, err := firestore.NewClient(ctx, "rtchat-47692")
			if err != nil {
				return nil, err
			}
			defer db.Close()
			return lastActive(ctx, db, ids)
		},
	})
}
func runWith(ctx context.Context, args []string, output io.Writer, deps runtime) error {
	o, err := parse(args)
	if err != nil {
		return err
	}
	ctx, cancel := context.WithTimeout(ctx, o.timeout)
	defer cancel()
	api, legacySecret, err := deps.LoadAPI(ctx)
	if err != nil {
		return err
	}
	if api.Pacer == nil {
		api.Pacer = eventsubmigration.NewPacer(o.rate, o.reserve)
	}

	var snapshot eventsubmigration.Snapshot
	if o.resume {
		snapshot, err = eventsubmigration.ReadSnapshot(o.backup)
		if err != nil {
			return err
		}
	} else {
		listed, err := api.List(ctx, nil)
		if err != nil {
			return err
		}
		snapshot = eventsubmigration.Snapshot{Schema: 1, CreatedAt: time.Now().UTC(), ClientID: api.ClientID, LegacyCallbacks: [2]string{eventsubmigration.LegacyCallback, eventsubmigration.AliasCallback}, TargetCallback: eventsubmigration.TargetCallback, TotalCost: listed.TotalCost, MaxTotalCost: listed.MaxTotalCost, Subscriptions: listed.Data}
		if err = eventsubmigration.WriteSnapshot(o.backup, snapshot); err != nil {
			return fmt.Errorf("write immutable backup (use --resume for an existing snapshot): %w", err)
		}
	}
	if err = snapshot.Validate(api.ClientID); err != nil {
		return err
	}
	statePath, journalPath := o.backup+".state.json", o.backup+".journal.jsonl"
	if o.apply {
		release, err := lockCheckpoint(o.backup + ".lock")
		if err != nil {
			return err
		}
		defer release()
	}
	checkpoint, err := eventsubmigration.LoadCheckpoint(statePath, journalPath, snapshot)
	if err != nil {
		return err
	}
	var activity map[string]time.Time
	if deps.Activity != nil {
		seen := map[string]bool{}
		var ids []string
		for _, group := range snapshot.Order(nil) {
			if group.Broadcaster != "" && !seen[group.Broadcaster] {
				seen[group.Broadcaster] = true
				ids = append(ids, group.Broadcaster)
			}
		}
		if activity, err = deps.Activity(ctx, ids); err != nil {
			return fmt.Errorf("read broadcaster activity for ordering: %w", err)
		}
	}
	planned := snapshot.Planned()
	paid, preexisting := 0, 0
	for _, sub := range planned {
		if sub.Cost > 0 {
			paid++
		}
	}
	for _, sub := range snapshot.Subscriptions {
		if sub.Transport.Method == "webhook" && sub.Transport.Callback == eventsubmigration.TargetCallback && (sub.Status == "enabled" || sub.Status == "webhook_callback_verification_pending") {
			preexisting++
		}
	}
	fmt.Fprintf(output, "Backup: %s; allowlisted active/pending legacy subscriptions: %d (%d cost 1); captured cost: %d/%d; destinations already at %s: %d\n", o.backup, len(planned), paid, snapshot.TotalCost, snapshot.MaxTotalCost, eventsubmigration.TargetCallback, preexisting)
	if snapshot.MaxTotalCost > 0 && snapshot.TotalCost > snapshot.MaxTotalCost {
		fmt.Fprintf(output, "NOTE: total_cost %d exceeds max_total_cost %d. Cost-1 subscriptions without an existing destination are left in place (reported as blocked by cost cap) until total_cost <= max_total_cost; deleting one would not make room for its replacement.\n", snapshot.TotalCost, snapshot.MaxTotalCost)
	}
	limitText := "no limit"
	if o.limit > 0 {
		limitText = fmt.Sprintf("limit %d", o.limit)
	}
	if !o.apply {
		mode := "forward"
		if o.rollback {
			mode = "rollback"
		}
		fmt.Fprintf(output, "DRY RUN (%s): no subscription POST/DELETE requests; %s; %d requests/min.\n", mode, limitText, o.rate)
		listed, done, failed := 0, 0, 0
		for _, group := range snapshot.Order(activity) {
			for _, sub := range group.Subscriptions {
				progress := checkpoint.Entries[sub.ID]
				if (o.rollback && progress.RolledBack) || (!o.rollback && progress.DeletedOld) {
					done++
					continue
				}
				if progress.Attempts >= o.maxAttempts && !o.retry {
					failed++
					continue
				}
				if o.limit == 0 || listed < o.limit {
					listed++
					fmt.Fprintf(output, "%s %s v%s cost=%d broadcaster=%s lastActiveAt=%s condition=%s\n", sub.ID, sub.Type, sub.Version, sub.Cost, group.Broadcaster, formatTime(group.LastActive), sub.Condition)
				}
			}
		}
		fmt.Fprintf(output, "Checkpoint: %d complete; %d skipped after %d failed attempts; %d listed above.\n", done, failed, o.maxAttempts, listed)
		return nil
	}
	dedicated, err := deps.SigningSecret(ctx)
	if err != nil {
		return fmt.Errorf("load dedicated EventSub signing secret: %w", err)
	}
	// Forward migration creates at the agent with the dedicated secret and, if a
	// break-before-make replacement fails, recreates the legacy subscription
	// with the legacy secret. Rollback is the mirror image.
	secret, restoreSecret := dedicated, legacySecret
	if o.rollback {
		secret, restoreSecret = legacySecret, dedicated
	}
	lock, closeLock, err := deps.Lock(ctx)
	if err != nil {
		return err
	}
	defer closeLock()
	if err = eventsubmigration.CompactCheckpoint(statePath, journalPath, checkpoint); err != nil {
		return err
	}
	journal, err := eventsubmigration.OpenJournal(journalPath, checkpoint)
	if err != nil {
		return err
	}
	defer journal.Close()
	migrator := &eventsubmigration.Migrator{API: api, Snapshot: snapshot, Checkpoint: checkpoint, Secret: secret, RestoreSecret: restoreSecret, Save: journal.Append, Lock: lock, Activity: activity, MaxAttempts: o.maxAttempts, RetryFailed: o.retry, Log: func(format string, args ...interface{}) {
		fmt.Fprintf(output, time.Now().UTC().Format(time.RFC3339)+" "+format+"\n", args...)
	}}

	summary, err := migrator.Run(ctx, o.limit, o.rollback)
	fmt.Fprintf(output, "Summary: %s; checkpoint: %s + %s\n", summary, statePath, journalPath)
	if err != nil {
		return err
	}
	if !o.verify {
		fmt.Fprintf(output, "Each replacement was verified enabled before its source was deleted. Run with --verify for a full audit (lists every subscription).\n")
		return nil
	}
	current, err := api.List(ctx, nil)
	if err != nil {
		return err
	}
	if !o.rollback {
		if err = migrator.VerifyCompleted(current.Data); err != nil {
			return err
		}
	}
	remaining := 0
	for _, sub := range current.Data {
		if eventsubmigration.Eligible(sub) {
			remaining++
		}
	}
	if o.rollback {
		fmt.Fprintf(output, "Rollback batch finished; current active/pending legacy callback subscriptions: %d. Verify legacy event delivery.\n", remaining)
	} else {
		fmt.Fprintf(output, "Audit passed; current active/pending legacy callback subscriptions: %d; total_cost %d/%d. Verify actual event delivery before retirement.\n", remaining, current.TotalCost, current.MaxTotalCost)
	}
	return nil
}
func formatTime(at time.Time) string {
	if at.IsZero() {
		return "unknown"
	}
	return at.UTC().Format(time.RFC3339)
}
func lockCheckpoint(path string) (func(), error) {
	file, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return nil, err
	}
	if err = syscall.Flock(int(file.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		file.Close()
		return nil, fmt.Errorf("another process is using this migration checkpoint")
	}
	return func() { syscall.Flock(int(file.Fd()), syscall.LOCK_UN); file.Close() }, nil
}

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()
	if err := run(ctx, os.Args[1:], os.Stdout); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return
		}
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
