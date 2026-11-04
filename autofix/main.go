// Command autofix turns production errors from the rtchat agent into draft
// pull requests. It runs on a schedule from .github/workflows/autofix-run.yml.
// Each run:
//
//  1. collects the output of finished Claude Managed Agents sessions, validates
//     each patch and opens a draft pull request from the bot's fork, and
//  2. starts a session for a new error group from Error Reporting.
//
// The sessions run in Anthropic's sandbox with no credentials and no network
// beyond the Go module proxy. This job holds the credentials, never runs code
// from a session, and treats every session output as untrusted.
package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"path"
	"strconv"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/anthropics/anthropic-sdk-go"
	"github.com/anthropics/anthropic-sdk-go/option"
	clouderrorreporting "google.golang.org/api/clouderrorreporting/v1beta1"
)

type Config struct {
	Project       string
	Service       string
	AgentID       string
	EnvironmentID string
	Upstream      string
	Fork          string
	BudgetCents   int
	MaxActive     int
	MaxNew        int
	MaxAge        time.Duration
}

func env(name, fallback string) string {
	if v := os.Getenv(name); v != "" {
		return v
	}
	return fallback
}

func envInt(name string, fallback int) int {
	if n, err := strconv.Atoi(os.Getenv(name)); err == nil && n > 0 {
		return n
	}
	return fallback
}

func main() {
	cfg := Config{
		Project:       env("GOOGLE_CLOUD_PROJECT", "rtchat-47692"),
		Service:       env("AUTOFIX_SERVICE", "rtchat-agent"),
		AgentID:       os.Getenv("AUTOFIX_AGENT_ID"),
		EnvironmentID: os.Getenv("AUTOFIX_ENVIRONMENT_ID"),
		Upstream:      env("AUTOFIX_UPSTREAM", "muxable/rtchat"),
		Fork:          os.Getenv("AUTOFIX_FORK"),
		BudgetCents:   envInt("AUTOFIX_BUDGET_CENTS", 1000),
		MaxActive:     envInt("AUTOFIX_MAX_ACTIVE", 2),
		MaxNew:        envInt("AUTOFIX_MAX_NEW", 1),
		MaxAge:        time.Duration(envInt("AUTOFIX_MAX_AGE_MINUTES", 180)) * time.Minute,
	}
	token := os.Getenv("GITHUB_TOKEN")
	if cfg.AgentID == "" || cfg.EnvironmentID == "" || cfg.Fork == "" || token == "" || os.Getenv("ANTHROPIC_API_KEY") == "" {
		slog.Error("AUTOFIX_AGENT_ID, AUTOFIX_ENVIRONMENT_ID, AUTOFIX_FORK, GITHUB_TOKEN and ANTHROPIC_API_KEY are required")
		os.Exit(2)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Minute)
	defer cancel()
	fs, err := firestore.NewClient(ctx, cfg.Project)
	if err != nil {
		slog.Error("firestore", "err", err)
		os.Exit(1)
	}
	defer fs.Close()
	reporting, err := clouderrorreporting.NewService(ctx)
	if err != nil {
		slog.Error("error reporting", "err", err)
		os.Exit(1)
	}
	j := &Job{
		cfg:       cfg,
		claude:    anthropic.NewClient(option.WithMaxRetries(3)),
		store:     &Store{fs: fs},
		reporting: reporting,
		github:    &GitHub{Token: token, Upstream: cfg.Upstream, Fork: cfg.Fork, Client: &http.Client{Timeout: time.Minute}},
	}
	finishErr := j.Finish(ctx)
	if finishErr != nil {
		slog.Error("finish sessions", "err", finishErr)
	}
	startErr := j.Start(ctx)
	if startErr != nil {
		slog.Error("start sessions", "err", startErr)
	}
	if finishErr != nil || startErr != nil {
		os.Exit(1)
	}
}

type Job struct {
	cfg       Config
	claude    anthropic.Client
	store     *Store
	reporting *clouderrorreporting.Service
	github    *GitHub
}

// Start opens sessions for new error groups, up to the configured limits.
func (j *Job) Start(ctx context.Context) error {
	active, err := j.store.InState(ctx, stateStarting, stateRunning, stateCollecting)
	if err != nil {
		return err
	}
	slots := min(j.cfg.MaxNew, j.cfg.MaxActive-len(active))
	if slots <= 0 {
		slog.Info("at the active session limit", "active", len(active))
		return nil
	}
	res, err := j.reporting.Projects.GroupStats.List("projects/" + j.cfg.Project).
		ServiceFilterService(j.cfg.Service).
		TimeRangePeriod("PERIOD_1_DAY").
		Order("COUNT_DESC").
		PageSize(20).
		Context(ctx).Do()
	if err != nil {
		return fmt.Errorf("list error groups: %w", err)
	}
	for _, stats := range res.ErrorGroupStats {
		if slots == 0 {
			break
		}
		if stats.Group == nil || stats.Group.ResolutionStatus != "OPEN" {
			continue
		}
		report, ok := NewReport(stats)
		if !ok || (report.Location == nil && len(report.Frames) == 0) {
			// nothing points at the agent's code, so there's nothing to fix.
			continue
		}
		claimed, err := j.store.Claim(ctx, report)
		if err != nil {
			return err
		}
		if !claimed {
			continue
		}
		slots--
		if err := j.startSession(ctx, report); err != nil {
			slog.Error("start session", "group", report.GroupID, "err", err)
			if err := j.store.Update(ctx, report.Key(), map[string]any{"state": stateFailed, "reason": err.Error()}); err != nil {
				return err
			}
		}
	}
	return nil
}

func (j *Job) startSession(ctx context.Context, r *Report) error {
	base, err := j.github.HeadSHA(ctx)
	if err != nil {
		return err
	}
	session, err := j.claude.Beta.Sessions.New(ctx, anthropic.BetaSessionNewParams{
		Agent:         anthropic.BetaSessionNewParamsAgentUnion{OfString: anthropic.String(j.cfg.AgentID)},
		EnvironmentID: j.cfg.EnvironmentID,
		Title:         anthropic.String(r.Title()),
		Metadata:      map[string]string{"autofix_key": r.Key()},
		Budget: anthropic.BetaManagedAgentsBudgetLimitParam{
			Type: anthropic.BetaManagedAgentsBudgetLimitTypeLimit,
			MaxListCost: anthropic.BetaMonetaryAmountParam{
				Amount:   strconv.Itoa(j.cfg.BudgetCents),
				Currency: anthropic.BetaCurrencyUSD,
			},
		},
		// a public repository mounted without a token: the sandbox can read
		// it, but has no credential to push anything back.
		Resources: []anthropic.BetaSessionNewParamsResourceUnion{{
			OfGitHubRepository: &anthropic.BetaManagedAgentsGitHubRepositoryResourceParams{
				Type:      anthropic.BetaManagedAgentsGitHubRepositoryResourceParamsTypeGitHubRepository,
				URL:       "https://github.com/" + j.cfg.Upstream,
				MountPath: anthropic.String("/workspace/rtchat"),
				Checkout: anthropic.BetaManagedAgentsGitHubRepositoryResourceParamsCheckoutUnion{
					OfCommit: &anthropic.BetaManagedAgentsCommitCheckoutParam{
						Type: anthropic.BetaManagedAgentsCommitCheckoutTypeCommit,
						Sha:  base,
					},
				},
			},
		}},
		InitialEvents: []anthropic.BetaSessionNewParamsInitialEventUnion{{
			OfUserMessage: &anthropic.BetaManagedAgentsUserMessageEventParams{
				Type: anthropic.BetaManagedAgentsUserMessageEventParamsTypeUserMessage,
				Content: []anthropic.BetaManagedAgentsUserMessageEventParamsContentUnion{{
					OfText: &anthropic.BetaManagedAgentsTextBlockParam{
						Type: anthropic.BetaManagedAgentsTextBlockTypeText,
						Text: r.Prompt(),
					},
				}},
			},
		}},
	})
	if err != nil {
		return err
	}
	slog.Info("started session", "group", r.GroupID, "session", session.ID, "base", base)
	return j.store.Update(ctx, r.Key(), map[string]any{"state": stateRunning, "sessionId": session.ID, "baseSha": base})
}

// Finish collects the output of sessions that have stopped.
func (j *Job) Finish(ctx context.Context) error {
	attempts, err := j.store.InState(ctx, stateStarting, stateRunning, stateCollecting)
	if err != nil {
		return err
	}
	var errs []error
	for _, a := range attempts {
		if a.State != stateRunning {
			// a previous run died partway through starting or collecting.
			if time.Since(a.UpdatedAt) > 15*time.Minute {
				errs = append(errs, j.store.Update(ctx, a.Key, map[string]any{"state": stateFailed, "reason": "job stopped while " + a.State}))
			}
			continue
		}
		if err := j.finish(ctx, a); err != nil {
			if errors.Is(err, errRetry) {
				errs = append(errs, err)
				continue
			}
			// failures can quote the patch or git's output about it, which
			// shouldn't reach the public Actions log, so the reason only goes
			// to Firestore.
			slog.Error("session failed", "key", a.Key, "session", a.SessionID)
			errs = append(errs, j.store.Update(ctx, a.Key, map[string]any{"state": stateFailed, "reason": truncate(err.Error(), 1000)}))
		}
	}
	return errors.Join(errs...)
}

var (
	errNotDone = errors.New("session still running")
	// errRetry marks failures that leave the attempt for the next run.
	errRetry = errors.New("will retry")
)

func (j *Job) finish(ctx context.Context, a keyedAttempt) error {
	session, err := j.claude.Beta.Sessions.Get(ctx, a.SessionID, anthropic.BetaSessionGetParams{})
	if err != nil {
		return fmt.Errorf("%w: %w", errRetry, err)
	}
	stop, err := j.stopReason(ctx, session)
	if errors.Is(err, errNotDone) {
		if time.Since(a.CreatedAt) > j.cfg.MaxAge {
			j.interrupt(ctx, a.SessionID)
			return fmt.Errorf("session ran longer than %s", j.cfg.MaxAge)
		}
		return nil
	}
	if err != nil {
		return fmt.Errorf("%w: %w", errRetry, err)
	}
	if moved, err := j.store.Transition(ctx, a.Key, stateRunning, stateCollecting); err != nil {
		return fmt.Errorf("%w: %w", errRetry, err)
	} else if !moved {
		return nil
	}
	if stop != "end_turn" {
		return j.store.Update(ctx, a.Key, map[string]any{"state": stateFailed, "reason": "session stopped: " + stop})
	}
	outputs, err := j.outputs(ctx, a.SessionID)
	if err != nil {
		return err
	}
	patch, ok := outputs["patch.diff"]
	if !ok {
		reason := "agent found no safe fix"
		if note, ok := outputs["no-fix.md"]; ok {
			reason += ": " + truncate(strings.ToValidUTF8(string(note), ""), 1000)
		}
		return j.store.Update(ctx, a.Key, map[string]any{"state": stateNoFix, "reason": reason})
	}
	stats, err := ValidatePatch(patch)
	if err != nil {
		slog.Warn("rejected patch", "key", a.Key, "session", a.SessionID)
		return j.store.Update(ctx, a.Key, map[string]any{"state": stateRejected, "reason": err.Error()})
	}
	report := &Report{GroupID: a.GroupID, Count: a.Count, Location: a.Location}
	body := PRBody(report, a.SessionID, stats, string(outputs["summary.md"]))
	url, err := j.github.Propose(ctx, a.BaseSHA, "autofix/"+a.Key, a.Title, body, patch, stats)
	if err != nil {
		return err
	}
	slog.Info("opened pull request", "session", a.SessionID, "url", url)
	return j.store.Update(ctx, a.Key, map[string]any{"state": stateProposed, "prUrl": url})
}

// stopReason returns why an idle or terminated session stopped, or errNotDone.
func (j *Job) stopReason(ctx context.Context, session *anthropic.BetaManagedAgentsSession) (string, error) {
	switch session.Status {
	case anthropic.BetaManagedAgentsSessionStatusTerminated:
		return "terminated", nil
	case anthropic.BetaManagedAgentsSessionStatusIdle:
	default:
		return "", errNotDone
	}
	page, err := j.claude.Beta.Sessions.Events.List(ctx, session.ID, anthropic.BetaSessionEventListParams{
		Order: anthropic.BetaSessionEventListParamsOrderDesc,
		Types: []anthropic.BetaManagedAgentsSessionEventType{anthropic.BetaManagedAgentsSessionEventTypeSessionStatusIdle},
		Limit: anthropic.Int(1),
	})
	if err != nil {
		return "", err
	}
	if len(page.Data) == 0 {
		return "", errNotDone
	}
	return page.Data[0].AsSessionStatusIdle().StopReason.Type, nil
}

func (j *Job) interrupt(ctx context.Context, sessionID string) {
	_, err := j.claude.Beta.Sessions.Events.Send(ctx, sessionID, anthropic.BetaSessionEventSendParams{
		Events: []anthropic.BetaManagedAgentsEventParamsUnion{{
			OfUserInterrupt: &anthropic.BetaManagedAgentsUserInterruptEventParams{
				Type: anthropic.BetaManagedAgentsUserInterruptEventParamsTypeUserInterrupt,
			},
		}},
	})
	if err != nil {
		slog.Warn("interrupt session", "session", sessionID, "err", err)
	}
}

const maxOutputBytes = 1 << 20

// outputs downloads the files the agent wrote to /mnt/session/outputs/.
func (j *Job) outputs(ctx context.Context, sessionID string) (map[string][]byte, error) {
	files := map[string][]byte{}
	// outputs show up in the listing a few seconds after the session idles.
	for attempt := 0; attempt < 3 && len(files) == 0; attempt++ {
		if attempt > 0 {
			time.Sleep(3 * time.Second)
		}
		iter := j.claude.Beta.Files.ListAutoPaging(ctx, anthropic.BetaFileListParams{
			ScopeID: anthropic.String(sessionID),
			Betas:   []anthropic.AnthropicBeta{anthropic.AnthropicBetaManagedAgents2026_04_01},
		})
		for iter.Next() {
			meta := iter.Current()
			name := path.Base(meta.Filename)
			if name != "patch.diff" && name != "summary.md" && name != "no-fix.md" {
				continue
			}
			if meta.SizeBytes > maxOutputBytes {
				return nil, fmt.Errorf("%s is %d bytes", name, meta.SizeBytes)
			}
			res, err := j.claude.Beta.Files.Download(ctx, meta.ID, anthropic.BetaFileDownloadParams{})
			if err != nil {
				return nil, err
			}
			body, err := io.ReadAll(io.LimitReader(res.Body, maxOutputBytes+1))
			res.Body.Close()
			if err != nil {
				return nil, err
			}
			if len(body) > maxOutputBytes {
				return nil, fmt.Errorf("%s is over %d bytes", name, maxOutputBytes)
			}
			files[name] = body
		}
		if err := iter.Err(); err != nil {
			return nil, err
		}
	}
	return files, nil
}
