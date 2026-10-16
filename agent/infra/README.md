# API hostname and migration

The API frontend is `https://rtchat-api.rtirl.com`, using the global static IP
`34.117.145.239` (`rtchat-api` in project `rtchat-47692`). `rtirl.com` is registered
with Squarespace Domains II LLC and its authoritative nameservers are
`ns-cloud-b1.googledomains.com` through `ns-cloud-b4.googledomains.com`. Its DNS is
managed through Squarespace; Porkbun's zone is not authoritative. The DNS record
is `rtchat-api A 34.117.145.239`.

Run from the repository root with an authenticated gcloud CLI:

```sh
agent/infra/setup-api.sh
```

The script provisions an external Application Load Balancer, Google-managed TLS
certificate, two backend services, a serverless NEG for the existing Cloud
Functions, and an HTTP health check for the regional agent instance group. It
reuses existing resources and reconciles the URL map, named port and firewall
source ranges on each run. It is a provisioning script, not a general drift
reconciler. `PROJECT_ID`, `API_HOSTNAME`, `AGENT_GROUP`, `AGENT_REGION` and
`FUNCTIONS_REGION` can override the defaults for another environment; resource
names retain the `rtchat-api` prefix.

The agent backend uses `http:8080`, `/healthz` and 30 seconds of connection
draining. The existing `/` autohealing check and recycling policy are separate.
The `allow-health-check` firewall rule is restricted to `130.211.0.0/22` and
`35.191.0.0/16`; check for other firewall rules before claiming port 8080 is
unreachable directly.

## Routes

| Public path | Initial backend | Cutover work |
| --- | --- | --- |
| `/send`, `/ban`, `/unban`, `/timeout`, `/deleteMessage`, `/raid`, `/cancelRaid` | Same-named Cloud Function | Move individual routes after their agent implementations exist |
| `/subscribe`, `/search`, `/getEmotes`, `/getBadges`, `/getViewerList`, `/setRealTimeCashAddress` | Same-named Cloud Function | Same as above |
| `/eventsub` | Existing `eventsub` Cloud Function | Existing Twitch subscriptions retain their old callbacks until #1449 |
| `/healthz` | Agent instance group | Verify HTTP 200 before webhook cutover |
| `/kick/webhook` | Agent instance group | Kick dashboard change and parity checks in #1447 |
| `/twitch/eventsub` | Agent instance group | New callback, dedicated signing secret and subscription migration in #1449 |
| `/alchemy/webhook` | Agent instance group | Verify signatures, secrets and delivery parity before changing Alchemy dashboard URLs |

All other paths initially resolve through the serverless NEG's `/<function>`
URL mask in `us-central1`. This keeps callable POST payloads, Firebase ID tokens,
App Check and SDK errors intact without redirects or a per-request proxy
function. The app uses `lib/api.dart` to select these URLs; integration tests use
named SDK calls against their local emulator instead.

OAuth redirects/callbacks stay at `https://chat.rtirl.com/auth/...` and stream
previews stay at `/embed`: these aren't part of the webhook migration, and moving
OAuth requires updating provider allowlists and session cookie handling.
Existing Firebase Hosting rewrites (including `/api/kick/webhook`) and direct
Cloud Functions URLs remain available for old clients/subscriptions.

## Verification and rollout

Do not release the app or deploy the callback URL change until the certificate
is ACTIVE and the Cloud Functions routes work through the new hostname:

```sh
gcloud compute ssl-certificates describe rtchat-api --global \
  --project=rtchat-47692 --format='yaml(managed)'
gcloud compute backend-services get-health rtchat-api-agent --global \
  --project=rtchat-47692
curl --fail https://rtchat-api.rtirl.com/healthz
# The callable protocol should return an INVALID_ARGUMENT JSON error, not a
# load-balancer 404/502, when sent a deliberately malformed request.
curl -i -X POST https://rtchat-api.rtirl.com/getEmotes \
  -H 'Content-Type: application/json' -d '{}'
```

Also test signed-in calls on a device before releasing: custom URLs must retain
Firebase Authentication credentials. A successful call to a public callable is
not an authentication test.

The `/eventsub` callback URL change in this PR still targets the existing
function with its existing signing secret. It does not cut Twitch traffic over
to the agent. New subscriptions use the new hostname; old subscriptions can
continue using their original Cloud Functions URL. #1449 must re-create
subscriptions with `https://rtchat-api.rtirl.com/twitch/eventsub` and the agent's
`twitch-eventsub-secret`. Do not delete `eventsub` before that migration.

For Kick, change the app dashboard URL to
`https://rtchat-api.rtirl.com/kick/webhook` only after the comparison in #1447.
Alchemy callbacks similarly require a dashboard change. The current agent only
implements `/alchemy/webhook`; verify which legacy Alchemy endpoints are actually
deployed before planning additional routes. Remove legacy functions and Hosting rewrites only
after confirming that their callers have migrated.

This implements the frontend setup from #1446 and prepares the URL changes in
#1441, #1447 and #1449. Drain/preemption testing, provider parity checks and
subscription migration remain separate cutover tasks. To roll back the app URL
change, restore named Firebase SDK calls; to roll back a provider cutover, restore
its previous callback and matching signing secret.

References: [Google's serverless NEG setup](https://cloud.google.com/load-balancing/docs/https/setup-global-ext-https-serverless)
and [Firebase Hosting rewrites](https://firebase.google.com/docs/hosting/full-config#rewrites).

## Full retirement scope

The complete migration is tracked in #1551. This frontend PR does not remove
Cloud Functions: the serverless backend is an intentional compatibility bridge.
The remaining ports have separate tickets: callable/auth/token foundation #1552,
chat actions #1553, read APIs #1554, subscription/donation registration #1555,
OAuth/HTTP handlers #1556, scheduled jobs #1557, Alchemy cutover #1558 and final
retirement #1559. The final gate includes all deployed functions, supported old
mobile clients, provider callbacks and scheduled triggers, not just webhook load.
