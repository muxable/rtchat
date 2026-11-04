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
| This job (Cloud Run job) | our code | Anthropic API key, bot GitHub token, GCP service account | no |
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
   git add claude-lock.json   # commit it, so later applies update in place
   ```

   Re-run `ant apply` after editing either file.

3. **Secrets.** Store the Anthropic API key and the bot token in Secret
   Manager as `autofix-anthropic-api-key` and `autofix-github-token`.

4. **Service account.** Create `autofix@rtchat-47692.iam.gserviceaccount.com`
   with `roles/errorreporting.viewer`, `roles/datastore.user`, and
   `roles/secretmanager.secretAccessor` on the two secrets.

5. **Job and schedule.**

   ```sh
   gcloud run jobs deploy autofix --project=rtchat-47692 --region=us-west1 \
     --source=. --service-account=autofix@rtchat-47692.iam.gserviceaccount.com \
     --task-timeout=20m --max-retries=0 \
     --set-secrets=ANTHROPIC_API_KEY=autofix-anthropic-api-key:latest,GITHUB_TOKEN=autofix-github-token:latest \
     --set-env-vars=AUTOFIX_AGENT_ID=$(jq -r '.resources["./agents/rtchat-autofix.md"].id' claude-lock.json),AUTOFIX_ENVIRONMENT_ID=$(jq -r '.resources["./environments/rtchat-autofix.yaml"].id' claude-lock.json),AUTOFIX_FORK=rtchat-autofix/rtchat

   gcloud scheduler jobs create http autofix --project=rtchat-47692 --location=us-west1 \
     --schedule="*/15 * * * *" --http-method=POST \
     --uri=https://run.googleapis.com/v2/projects/rtchat-47692/locations/us-west1/jobs/autofix:run \
     --oauth-service-account-email=autofix@rtchat-47692.iam.gserviceaccount.com
   ```

   The scheduler's service account also needs `roles/run.invoker` on the job.

## Configuration

| Variable | Default | |
| --- | --- | --- |
| `AUTOFIX_AGENT_ID`, `AUTOFIX_ENVIRONMENT_ID` | required | from `claude-lock.json` |
| `AUTOFIX_FORK` | required | `owner/repo` of the bot's fork |
| `ANTHROPIC_API_KEY`, `GITHUB_TOKEN` | required | |
| `AUTOFIX_BUDGET_CENTS` | `1000` | hard cap per session |
| `AUTOFIX_MAX_ACTIVE` | `2` | sessions in flight at once |
| `AUTOFIX_MAX_NEW` | `1` | sessions started per run |
| `AUTOFIX_MAX_AGE_MINUTES` | `180` | sessions still running after this are interrupted |

## Operating

Attempts are recorded in the Firestore `autofix` collection, one document per
error group, with a `state` of `proposed`, `no_fix`, `rejected` (the validator
refused the patch, with the reason) or `failed`. Delete a group's document to
let autofix try it again. Session transcripts are in the Claude Console.
