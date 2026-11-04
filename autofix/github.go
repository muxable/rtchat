package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

// GitHub talks to the upstream repository as the bot account. The bot's token
// can push to its own fork and open pull requests, but has no write access to
// upstream, so the worst it can do is propose a change for review.
type GitHub struct {
	Token    string
	Upstream string // owner/repo
	Fork     string // owner/repo
	Client   *http.Client
}

func (g *GitHub) do(ctx context.Context, method, path string, body, out any) error {
	var reader io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return err
		}
		reader = bytes.NewReader(b)
	}
	req, err := http.NewRequestWithContext(ctx, method, "https://api.github.com"+path, reader)
	if err != nil {
		return err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("Authorization", "Bearer "+g.Token)
	req.Header.Set("X-GitHub-Api-Version", "2022-11-28")
	res, err := g.Client.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	if res.StatusCode >= 300 {
		msg, _ := io.ReadAll(io.LimitReader(res.Body, 2048))
		return fmt.Errorf("github %s %s: %s: %s", method, path, res.Status, msg)
	}
	if out == nil {
		return nil
	}
	return json.NewDecoder(res.Body).Decode(out)
}

// HeadSHA returns the commit the upstream default branch points at.
func (g *GitHub) HeadSHA(ctx context.Context) (string, error) {
	var commit struct {
		SHA string `json:"sha"`
	}
	if err := g.do(ctx, "GET", "/repos/"+g.Upstream+"/commits/main", nil, &commit); err != nil {
		return "", err
	}
	if !versionPattern.MatchString(commit.SHA) || len(commit.SHA) != 40 {
		return "", fmt.Errorf("unexpected commit sha %q", commit.SHA)
	}
	return commit.SHA, nil
}

// Propose applies a validated patch on top of base, pushes it to a branch on
// the fork and opens a draft pull request against upstream. It never runs
// anything from the patch: git only applies it as text.
func (g *GitHub) Propose(ctx context.Context, base, branch, title, body string, patch []byte, stats *PatchStats) (string, error) {
	// the fork needs the base commit for a shallow push to succeed.
	if err := g.do(ctx, "POST", "/repos/"+g.Fork+"/merge-upstream", map[string]string{"branch": "main"}, nil); err != nil {
		return "", fmt.Errorf("sync fork: %w", err)
	}
	dir, err := os.MkdirTemp("", "autofix-")
	if err != nil {
		return "", err
	}
	defer os.RemoveAll(dir)
	patchFile := filepath.Join(dir, "patch.diff")
	if err := os.WriteFile(patchFile, patch, 0o600); err != nil {
		return "", err
	}
	repo := filepath.Join(dir, "repo")
	git := func(env []string, args ...string) ([]byte, error) {
		cmd := exec.CommandContext(ctx, "git", append([]string{"-c", "core.hooksPath=/dev/null", "-c", "core.symlinks=false"}, args...)...)
		cmd.Dir = repo
		// no system or global config, no prompts.
		cmd.Env = append([]string{"GIT_CONFIG_NOSYSTEM=1", "GIT_CONFIG_GLOBAL=/dev/null", "GIT_TERMINAL_PROMPT=0", "HOME=" + dir, "PATH=" + os.Getenv("PATH")}, env...)
		out, err := cmd.CombinedOutput()
		if err != nil {
			return out, fmt.Errorf("git %s: %w: %s", args[0], err, truncate(string(out), 500))
		}
		return out, nil
	}
	if err := os.Mkdir(repo, 0o700); err != nil {
		return "", err
	}
	if _, err := git(nil, "init", "-q"); err != nil {
		return "", err
	}
	if _, err := git(nil, "fetch", "-q", "--depth=1", "https://github.com/"+g.Upstream+".git", base); err != nil {
		return "", err
	}
	if _, err := git(nil, "checkout", "-q", "-b", branch, "FETCH_HEAD"); err != nil {
		return "", err
	}
	// cross-check our parser against git's own view of the patch.
	numstat, err := git(nil, "apply", "--numstat", "-z", patchFile)
	if err != nil {
		return "", err
	}
	touched, err := parseNumstat(numstat)
	if err != nil {
		return "", err
	}
	if strings.Join(touched, "\n") != strings.Join(stats.Files, "\n") {
		return "", fmt.Errorf("git sees different files than the validator: %q vs %q", touched, stats.Files)
	}
	if _, err := git(nil, "apply", "--index", "--whitespace=nowarn", patchFile); err != nil {
		return "", err
	}
	if _, err := git(nil, "-c", "user.name=rtchat-autofix", "-c", "user.email=autofix@rtchat.invalid",
		"commit", "-q", "--no-verify", "-m", title); err != nil {
		return "", err
	}
	auth := base64.StdEncoding.EncodeToString([]byte("x-access-token:" + g.Token))
	if _, err := git([]string{
		"GIT_CONFIG_COUNT=1",
		"GIT_CONFIG_KEY_0=http.https://github.com/.extraheader",
		"GIT_CONFIG_VALUE_0=Authorization: Basic " + auth,
	}, "push", "-q", "https://github.com/"+g.Fork+".git", "HEAD:refs/heads/"+branch); err != nil {
		return "", err
	}
	forkOwner, _, _ := strings.Cut(g.Fork, "/")
	var pr struct {
		HTMLURL string `json:"html_url"`
	}
	if err := g.do(ctx, "POST", "/repos/"+g.Upstream+"/pulls", map[string]any{
		"title": title,
		"head":  forkOwner + ":" + branch,
		"base":  "main",
		"body":  body,
		"draft": true,
	}, &pr); err != nil {
		return "", err
	}
	return pr.HTMLURL, nil
}

// parseNumstat reads `git apply --numstat -z` output and rejects binary files
// and renames.
func parseNumstat(out []byte) ([]string, error) {
	var paths []string
	for _, entry := range strings.Split(strings.TrimSuffix(string(out), "\x00"), "\x00") {
		fields := strings.SplitN(entry, "\t", 3)
		if len(fields) != 3 || fields[2] == "" {
			// a rename prints an empty path followed by two more entries.
			return nil, fmt.Errorf("unexpected numstat entry %q", truncate(entry, 80))
		}
		if _, err := strconv.Atoi(fields[0]); err != nil {
			return nil, fmt.Errorf("binary change to %q", truncate(fields[2], 80))
		}
		if err := AllowedPath(fields[2]); err != nil {
			return nil, err
		}
		paths = append(paths, fields[2])
	}
	return paths, nil
}

const maxSummaryLen = 3000

// PRBody renders the pull request description. The agent's summary is shown
// inside a fenced block so its links, images and @mentions don't render or
// notify anyone, and its text can't pose as part of the trusted description.
func PRBody(r *Report, sessionID string, stats *PatchStats, summary string) string {
	summary = strings.ToValidUTF8(summary, "")
	if len(summary) > maxSummaryLen {
		summary = summary[:maxSummaryLen] + "\n[truncated]"
	}
	// no line of the summary may close the fence.
	summary = strings.ReplaceAll(summary, "~~~", "~ ~ ~")
	var b strings.Builder
	b.WriteString("> [!WARNING]\n")
	b.WriteString("> Generated by autofix from a production error report. The report can contain attacker-controlled text, ")
	b.WriteString("so review this change as if a stranger wrote it.\n\n")
	fmt.Fprintf(&b, "- Error group: `%s` (%d occurrences)\n", r.GroupID, r.Count)
	if r.Location != nil {
		fmt.Fprintf(&b, "- Reported at: `%s:%d`\n", r.Location.File, r.Location.Line)
	}
	fmt.Fprintf(&b, "- Files: %d, lines changed: %d\n", len(stats.Files), stats.Changed)
	fmt.Fprintf(&b, "- Session: `%s`\n\n", sessionID)
	b.WriteString("Agent's summary (untrusted):\n\n~~~text\n")
	b.WriteString(summary)
	b.WriteString("\n~~~\n")
	return b.String()
}
