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
	project, backup         string
	apply, resume, rollback bool
	limit                   int
	timeout                 time.Duration
}

func parse(args []string) (options, error) {
	var o options
	flags := flag.NewFlagSet("migrate-eventsub", flag.ContinueOnError)
	flags.StringVar(&o.project, "project", "rtchat-47692", "Google Cloud project for OAuth/signing secrets and lifecycle leases")
	flags.StringVar(&o.backup, "backup", "eventsub-migration.json", "immutable descriptor backup; checkpoint is <backup>.state.json")
	flags.BoolVar(&o.apply, "apply", false, "create replacements, verify enabled, then delete allowlisted sources")
	flags.BoolVar(&o.resume, "resume", false, "resume the existing backup/checkpoint instead of taking a new backup")
	flags.BoolVar(&o.rollback, "rollback", false, "restore snapshot legacy callback, then remove migration-created replacements; requires --resume")
	flags.IntVar(&o.limit, "limit", 20, "maximum subscriptions to process in this invocation")
	flags.DurationVar(&o.timeout, "timeout", 30*time.Minute, "overall invocation deadline")
	if err := flags.Parse(args); err != nil {
		return o, err
	}
	if flags.NArg() != 0 || o.backup == "" || o.project == "" || o.limit < 1 || o.timeout <= 0 {
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

type runtime struct {
	LoadAPI       func(context.Context) (*eventsubmigration.API, string, error)
	SigningSecret func(context.Context) (string, error)
	Lock          func(context.Context) (eventsubmigration.Locker, func(), error)
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
	statePath := o.backup + ".state.json"
	if o.apply {
		release, err := lockCheckpoint(o.backup + ".lock")
		if err != nil {
			return err
		}
		defer release()
	}
	checkpoint, err := eventsubmigration.ReadCheckpoint(statePath, snapshot)
	if err != nil {
		return err
	}
	fmt.Fprintf(output, "Backup: %s; allowlisted active/pending legacy subscriptions: %d; captured cost: %d/%d\n", o.backup, len(snapshot.Planned()), snapshot.TotalCost, snapshot.MaxTotalCost)
	if !o.apply {
		mode := "forward"
		if o.rollback {
			mode = "rollback"
		}
		fmt.Fprintf(output, "DRY RUN (%s): no subscription POST/DELETE requests; batch limit %d.\n", mode, o.limit)
		for _, existing := range snapshot.Subscriptions {
			if existing.Transport.Method == "webhook" && existing.Transport.Callback == eventsubmigration.TargetCallback && (existing.Status == "enabled" || existing.Status == "webhook_callback_verification_pending") {
				fmt.Fprintf(output, "BLOCKER: preexisting destination %s has an undisclosed signing secret; forward apply will refuse this snapshot.\n", existing.ID)
			}
		}
		for _, sub := range snapshot.Planned() {
			fmt.Fprintf(output, "%s %s v%s condition=%s\n", sub.ID, sub.Type, sub.Version, sub.Condition)
		}
		return nil
	}
	secret := ""
	if o.rollback {
		secret = legacySecret
	} else {
		secret, err = deps.SigningSecret(ctx)
		if err != nil {
			return fmt.Errorf("load dedicated EventSub signing secret: %w", err)
		}
	}
	lock, closeLock, err := deps.Lock(ctx)
	if err != nil {
		return err
	}
	defer closeLock()
	migrator := &eventsubmigration.Migrator{API: api, Snapshot: snapshot, Checkpoint: checkpoint, Secret: secret, Save: func(state eventsubmigration.Checkpoint) error {
		return eventsubmigration.WriteCheckpoint(statePath, state)
	}, Lock: lock}

	processed, err := migrator.Run(ctx, o.limit, o.rollback)
	fmt.Fprintf(output, "Processed: %d; checkpoint: %s\n", processed, statePath)
	if err != nil {
		return err
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
		fmt.Fprintf(output, "Current active/pending legacy callback subscriptions: %d. Resume batches until complete; verify actual event delivery before retirement.\n", remaining)
	}
	return nil
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
