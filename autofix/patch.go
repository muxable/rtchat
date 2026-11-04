package main

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

const (
	maxPatchBytes   = 100_000
	maxPatchFiles   = 10
	maxChangedLines = 300
)

var (
	hunkHeaderPattern = regexp.MustCompile(`^@@ -\d+(?:,(\d+))? \+\d+(?:,(\d+))? @@`)
	indexPattern      = regexp.MustCompile(`^index [0-9a-f]+\.\.[0-9a-f]+(?: 100644)?$`)
)

// PatchStats summarizes a patch that passed ValidatePatch.
type PatchStats struct {
	Files   []string
	Changed int
}

// ValidatePatch checks the agent's patch before anything trusted touches it.
// The agent may be acting on an attacker's instructions, so the patch may only
// edit or add regular Go files under agent/ (not agent/monitoring), with no
// renames, mode changes, symlinks or binary content, and must stay small
// enough for a person to review.
func ValidatePatch(patch []byte) (*PatchStats, error) {
	if len(patch) == 0 {
		return nil, fmt.Errorf("empty patch")
	}
	if len(patch) > maxPatchBytes {
		return nil, fmt.Errorf("patch is %d bytes, over the %d byte limit", len(patch), maxPatchBytes)
	}
	text := string(patch)
	if strings.ContainsRune(text, 0) || strings.Contains(text, "\r") {
		return nil, fmt.Errorf("patch contains NUL or carriage return bytes")
	}
	lines := strings.Split(strings.TrimSuffix(text, "\n"), "\n")
	stats := &PatchStats{}
	var path string          // the file the current section edits
	var oldLeft, newLeft int // lines remaining in the current hunk
	for i := 0; i < len(lines); i++ {
		line := lines[i]
		if oldLeft > 0 || newLeft > 0 {
			switch {
			case strings.HasPrefix(line, " "):
				oldLeft--
				newLeft--
			case strings.HasPrefix(line, "-"):
				oldLeft--
				stats.Changed++
			case strings.HasPrefix(line, "+"):
				newLeft--
				stats.Changed++
			case line == `\ No newline at end of file`:
			default:
				return nil, fmt.Errorf("line %d: unexpected line inside hunk", i+1)
			}
			if oldLeft < 0 || newLeft < 0 {
				return nil, fmt.Errorf("line %d: hunk is longer than its header", i+1)
			}
			continue
		}
		if line == `\ No newline at end of file` {
			continue
		}
		switch {
		case strings.HasPrefix(line, "diff --git "):
			p, err := diffGitPath(line)
			if err != nil {
				return nil, fmt.Errorf("line %d: %w", i+1, err)
			}
			for _, seen := range stats.Files {
				if seen == p {
					return nil, fmt.Errorf("line %d: %s appears twice", i+1, p)
				}
			}
			path = p
			stats.Files = append(stats.Files, p)
		case path == "":
			return nil, fmt.Errorf("line %d: content before the first diff --git header", i+1)
		case indexPattern.MatchString(line), line == "new file mode 100644":
		case strings.HasPrefix(line, "--- "):
			if p := strings.TrimPrefix(line, "--- "); p != "/dev/null" && p != "a/"+path {
				return nil, fmt.Errorf("line %d: --- header does not match %s", i+1, path)
			}
		case strings.HasPrefix(line, "+++ "):
			if p := strings.TrimPrefix(line, "+++ "); p != "b/"+path {
				return nil, fmt.Errorf("line %d: +++ header does not match %s", i+1, path)
			}
		case strings.HasPrefix(line, "@@ "):
			m := hunkHeaderPattern.FindStringSubmatch(line)
			if m == nil {
				return nil, fmt.Errorf("line %d: malformed hunk header", i+1)
			}
			oldLeft, newLeft = hunkCount(m[1]), hunkCount(m[2])
		default:
			// renames, copies, deletions, mode changes, binary patches, etc.
			return nil, fmt.Errorf("line %d: unsupported patch line %q", i+1, truncate(line, 80))
		}
	}
	if oldLeft > 0 || newLeft > 0 {
		return nil, fmt.Errorf("patch ends inside a hunk")
	}
	if len(stats.Files) == 0 {
		return nil, fmt.Errorf("patch changes no files")
	}
	if len(stats.Files) > maxPatchFiles {
		return nil, fmt.Errorf("patch changes %d files, over the %d file limit", len(stats.Files), maxPatchFiles)
	}
	if stats.Changed == 0 {
		return nil, fmt.Errorf("patch changes no lines")
	}
	if stats.Changed > maxChangedLines {
		return nil, fmt.Errorf("patch changes %d lines, over the %d line limit", stats.Changed, maxChangedLines)
	}
	return stats, nil
}

func diffGitPath(line string) (string, error) {
	a, b, ok := strings.Cut(strings.TrimPrefix(line, "diff --git "), " ")
	if !ok || !strings.HasPrefix(a, "a/") || !strings.HasPrefix(b, "b/") || a[2:] != b[2:] {
		return "", fmt.Errorf("malformed or renaming diff --git header")
	}
	if err := AllowedPath(a[2:]); err != nil {
		return "", err
	}
	return a[2:], nil
}

// AllowedPath reports whether the agent may change path.
func AllowedPath(path string) error {
	if !repoFilePattern.MatchString(path) || strings.Contains(path, "..") || strings.Contains(path, "//") {
		return fmt.Errorf("%q is outside the files autofix may change", truncate(path, 80))
	}
	if strings.HasPrefix(path, "agent/monitoring/") {
		return fmt.Errorf("%q is outside the files autofix may change", path)
	}
	return nil
}

func hunkCount(s string) int {
	if s == "" {
		return 1
	}
	n, err := strconv.Atoi(s)
	if err != nil {
		return 0
	}
	return n
}

func truncate(s string, n int) string {
	if len(s) > n {
		return s[:n] + "..."
	}
	return s
}
