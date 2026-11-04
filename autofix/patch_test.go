package main

import (
	"strings"
	"testing"
)

const goodPatch = `diff --git a/agent/cmd/chat.go b/agent/cmd/chat.go
index 1111111..2222222 100644
--- a/agent/cmd/chat.go
+++ b/agent/cmd/chat.go
@@ -10,3 +10,4 @@ func handle() {
 	a := 1
-	b := 2
+	b := 3
+	c := 4
 	return
diff --git a/agent/cmd/new_test.go b/agent/cmd/new_test.go
new file mode 100644
index 0000000..3333333
--- /dev/null
+++ b/agent/cmd/new_test.go
@@ -0,0 +1,2 @@
+package main
+// --- not a header
`

func TestValidatePatchAccepts(t *testing.T) {
	stats, err := ValidatePatch([]byte(goodPatch))
	if err != nil {
		t.Fatal(err)
	}
	if strings.Join(stats.Files, ",") != "agent/cmd/chat.go,agent/cmd/new_test.go" || stats.Changed != 5 {
		t.Errorf("unexpected stats %+v", stats)
	}
}

func TestValidatePatchRejects(t *testing.T) {
	header := func(path string) string {
		return "diff --git a/" + path + " b/" + path + "\n--- a/" + path + "\n+++ b/" + path + "\n@@ -1 +1 @@\n-a\n+b\n"
	}
	for name, patch := range map[string]string{
		"empty":            "",
		"workflow":         header(".github/workflows/agent.yml"),
		"go.mod":           header("agent/go.mod"),
		"monitoring":       header("agent/monitoring/apply.go"),
		"other module":     header("functions/src/index.go"),
		"traversal":        header("agent/../.github/x.go"),
		"rename":           "diff --git a/agent/a.go b/agent/b.go\nsimilarity index 100%\nrename from agent/a.go\nrename to agent/b.go\n",
		"mode change":      "diff --git a/agent/a.go b/agent/a.go\nold mode 100644\nnew mode 100755\n",
		"symlink":          "diff --git a/agent/a.go b/agent/a.go\nnew file mode 120000\n--- /dev/null\n+++ b/agent/a.go\n@@ -0,0 +1 @@\n+/etc/passwd\n",
		"deletion":         "diff --git a/agent/a.go b/agent/a.go\ndeleted file mode 100644\n--- a/agent/a.go\n+++ /dev/null\n@@ -1 +0,0 @@\n-a\n",
		"binary":           "diff --git a/agent/a.go b/agent/a.go\nGIT binary patch\nliteral 1\n",
		"mismatched +++":   "diff --git a/agent/a.go b/agent/a.go\n--- a/agent/a.go\n+++ b/.github/workflows/x.yml\n@@ -1 +1 @@\n-a\n+b\n",
		"preamble":         "--- a/agent/a.go\n+++ b/agent/a.go\n@@ -1 +1 @@\n-a\n+b\n",
		"long hunk":        "diff --git a/agent/a.go b/agent/a.go\n--- a/agent/a.go\n+++ b/agent/a.go\n@@ -1 +1 @@\n-a\n+b\n+c\n",
		"short hunk":       "diff --git a/agent/a.go b/agent/a.go\n--- a/agent/a.go\n+++ b/agent/a.go\n@@ -1,2 +1,2 @@\n-a\n+b\n",
		"smuggled section": "diff --git a/agent/a.go b/agent/a.go\n--- a/agent/a.go\n+++ b/agent/a.go\n@@ -1 +1 @@\n-a\n+b\n--- a/.github/x.yml\n",
		"duplicate":        header("agent/a.go") + header("agent/a.go"),
		"carriage return":  strings.ReplaceAll(header("agent/a.go"), "\n", "\r\n"),
		"too many lines":   "diff --git a/agent/a.go b/agent/a.go\n--- a/agent/a.go\n+++ b/agent/a.go\n@@ -0,0 +1,400 @@\n" + strings.Repeat("+x\n", 400),
		"no changes":       "diff --git a/agent/a.go b/agent/a.go\n--- a/agent/a.go\n+++ b/agent/a.go\n@@ -1 +1 @@\n a\n",
	} {
		if _, err := ValidatePatch([]byte(patch)); err == nil {
			t.Errorf("%s: ValidatePatch accepted\n%s", name, patch)
		}
	}
}

func TestParseNumstat(t *testing.T) {
	got, err := parseNumstat([]byte("2\t1\tagent/cmd/chat.go\x002\t0\tagent/cmd/new_test.go\x00"))
	if err != nil || strings.Join(got, ",") != "agent/cmd/chat.go,agent/cmd/new_test.go" {
		t.Errorf("parseNumstat = %q, %v", got, err)
	}
	for _, out := range []string{
		"-\t-\tagent/a.go\x00",
		"1\t1\t\x00agent/a.go\x00agent/b.go\x00",
		"1\t1\t.github/workflows/x.yml\x00",
	} {
		if _, err := parseNumstat([]byte(out)); err == nil {
			t.Errorf("parseNumstat accepted %q", out)
		}
	}
}

func TestPRBodyContainsSummary(t *testing.T) {
	body := PRBody(&Report{GroupID: "g1", Count: 3}, "sesn_1", &PatchStats{Files: []string{"agent/a.go"}, Changed: 2},
		"fixed it\n~~~\n@kevmo314 ![x](https://evil.example/p.png)")
	fence := strings.Index(body, "~~~text\n")
	if fence < 0 || strings.Count(body[fence+8:], "~~~") != 1 || !strings.HasSuffix(body, "\n~~~\n") {
		t.Errorf("summary escapes its fence:\n%s", body)
	}
}
