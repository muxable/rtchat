# autofix

Turns open error groups from the agent's Error Reporting into draft pull
requests, using a [Claude Managed Agents](https://platform.claude.com/docs/en/managed-agents/overview)
session to write the fix.

## How it stays safe

Error text can contain chat messages, usernames and third-party responses, so
assume a session can be fully hijacked by prompt injection. The design limits
what a hijacked session can do:

| Stage | Runs | Holds | Trusts session output? |
| --- | --- | --- | --- |
| `autofix-run.yml` (GitHub Actions, `main` only) | our code | Anthropic API key, bot GitHub token, GCP access through Workload Identity | no |
| Session (Anthropic sandbox) | Claude, plus whatever it runs | nothing | n/a |

- **The report is normalized before the agent sees it.** Only validated stack
  frames that point into `agent/` are kept. Quoted strings, URLs, long tokens
  and unusual characters are stripped from the message, which is also capped
  at 500 characters (`report.go`).
- **The sandbox has nothing to steal.** The repository is public and mounted
  without a token, so there is no credential to push with. Network access is
  limited to `proxy.golang.org` and `sum.golang.org`
  (`environments/rtchat-autofix.yaml`), and web search and fetch are off.
- **Each session has a hard spend cap** (`AUTOFIX_BUDGET_CENTS`, default
  $10), and each error group gets one attempt.
- **The patch is treated as data.** It may only edit or add `.go` files under
  `agent/` (not `agent/monitoring/`): no renames, deletions, mode changes,
  symlinks or binary content, at most 10 files and 300 changed lines
  (`patch.go`). `git apply --numstat` must agree with the validator. Git runs
  with hooks and global config disabled, and nothing from the patch is
  executed.
- **PRs come from the bot's fork as drafts.** Fork PRs get no repository
  secrets (`firebase-hosting-pull-request.yml` skips them) and a read-only
  token. The title is built from validated fields. The agent's summary is
  shown in a fenced block so its links, images and mentions don't render.
- **The workflow is isolated.** It sets `permissions: {}` (no `GITHUB_TOKEN`
  access), its secrets live in an `autofix` environment that only `main` can
  use, it writes no Actions cache, and it logs only IDs and outcomes because
  Actions logs are public. Failure reasons go to Firestore.
- **A person reviews every change.** The bot has no write access to
  `muxable/rtchat`.

What remains is a plausible-looking patch with a subtle flaw. Review these PRs
as if a stranger wrote them.

## Setup

1. **Bot account.** Create a GitHub account (e.g. `rtchat-autofix`), fork
   `muxable/rtchat` into it, and create a classic token with `public_repo`
   scope. A fine-grained token can't open PRs on a repository the bot doesn't
   own. Don't add the bot as a collaborator on `muxable/rtchat`. In the repo
   settings, set Actions → "Fork pull request workflows from outside
   collaborators" to require approval for all outside collaborators.

2. **Agent and environment.** With `ant` 1.30+ and an API key from a
   dedicated workspace, from this directory:

   ```sh
   ant apply --dry-run -v agents/rtchat-autofix.md environments/rtchat-autofix.yaml
   ant apply agents/rtchat-autofix.md environments/rtchat-autofix.yaml
   git add claude-lock.json   # commit it: the workflow reads the IDs from it
   ```

   Re-run `ant apply` after editing either file.

3. **GCP service account.** Only this workflow, running in the `autofix`
   environment, can use it:

   ```sh
   gcloud iam service-accounts create autofix --project=rtchat-47692
   SA=autofix@rtchat-47692.iam.gserviceaccount.com
   gcloud projects add-iam-policy-binding rtchat-47692 --member=serviceAccount:$SA --role=roles/errorreporting.viewer
   gcloud projects add-iam-policy-binding rtchat-47692 --member=serviceAccount:$SA --role=roles/datastore.user
   gcloud iam service-accounts add-iam-policy-binding $SA --project=rtchat-47692 \
     --role=roles/iam.workloadIdentityUser \
     --member=principal://iam.googleapis.com/projects/832669896677/locations/global/workloadIdentityPools/github-actions/subject/repo:muxable/rtchat:environment:autofix
   ```

4. **GitHub environment.** In the repo settings, create an environment named
   `autofix`, and set its deployment branches to `main` only. Add:
   - secret `ANTHROPIC_API_KEY`: the key from step 2's workspace
   - secret `AUTOFIX_GITHUB_TOKEN`: the bot token from step 1
   - variable `AUTOFIX_FORK`: the fork, e.g. `rtchat-autofix/rtchat`

5. **Try it.** Run the "Autofix run" workflow from the Actions tab. After
   that it runs every 15 minutes.

## Configuration

Limits can be overridden with environment variables in `autofix-run.yml`:

| Variable | Default | |
| --- | --- | --- |
| `AUTOFIX_BUDGET_CENTS` | `1000` | hard cap per session |
| `AUTOFIX_MAX_ACTIVE` | `2` | sessions in flight at once |
| `AUTOFIX_MAX_NEW` | `1` | sessions started per run |
| `AUTOFIX_MAX_AGE_MINUTES` | `180` | sessions still running after this are interrupted |

## Operating

Attempts are recorded in the Firestore `autofix` collection, one document per
error group, with a `state` of `proposed`, `no_fix`, `rejected` (the validator
refused the patch, with the reason) or `failed`. Delete a group's document to
let autofix try it again. Session transcripts are in the Claude Console.
