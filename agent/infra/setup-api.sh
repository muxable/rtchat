#!/usr/bin/env bash
# Provision the shared API frontend without changing provider webhook settings.
set -euo pipefail

project=${PROJECT_ID:-rtchat-47692}
hostname=${API_HOSTNAME:-rtchat-api.rtirl.com}
group=${AGENT_GROUP:-agent-small-us-west1}
region=${AGENT_REGION:-us-west1}
functions_region=${FUNCTIONS_REGION:-us-central1}

# Existing resources are reused. The URL map, named port and firewall rule are
# reconciled on each run; other settings below apply when resources are created.
gc() { gcloud --project="$project" --quiet "$@"; }
ensure() {
  local collection=$1 name=$2 scope=$3
  shift 3
  if ! gc compute "$collection" describe "$name" "$scope" >/dev/null 2>&1; then
    gc compute "$collection" create "$name" "$scope" "$@"
  fi
}

ensure addresses rtchat-api --global --ip-version=IPV4 --network-tier=PREMIUM

gc compute instance-groups managed set-named-ports "$group" \
  --region="$region" --named-ports=http:8080
if ! gc compute health-checks describe rtchat-api --global >/dev/null 2>&1; then
  gc compute health-checks create http rtchat-api --global --port=8080 \
    --request-path=/healthz --check-interval=5s --timeout=5s \
    --healthy-threshold=2 --unhealthy-threshold=2
fi
ensure backend-services rtchat-api-agent --global \
  --load-balancing-scheme=EXTERNAL_MANAGED --protocol=HTTP --port-name=http \
  --health-checks=rtchat-api --connection-draining-timeout=30s --timeout=30s

# add-backend is not idempotent, so check membership first.
backends=$(gc compute backend-services describe rtchat-api-agent --global \
  --format='value(backends[].group)')
if [[ "$backends" != *"/instanceGroups/$group"* ]]; then
  gc compute backend-services add-backend rtchat-api-agent --global \
    --instance-group="$group" --instance-group-region="$region" \
    --balancing-mode=UTILIZATION --max-utilization=0.8
fi

# Keep callables on their current implementation while URLs move to our domain.
# A URL mask resolves /send, /subscribe, /getEmotes, etc. to the same-named
# first-generation Cloud Function. No redirect: POST bodies and auth survive.
ensure network-endpoint-groups rtchat-api-functions "--region=$functions_region" \
  --network-endpoint-type=serverless --cloud-function-url-mask='/<function>'
ensure backend-services rtchat-api-functions --global \
  --load-balancing-scheme=EXTERNAL_MANAGED --protocol=HTTP
backends=$(gc compute backend-services describe rtchat-api-functions --global \
  --format='value(backends[].group)')
if [[ "$backends" != *"/networkEndpointGroups/rtchat-api-functions"* ]]; then
  gc compute backend-services add-backend rtchat-api-functions --global \
    --network-endpoint-group=rtchat-api-functions \
    --network-endpoint-group-region="$functions_region"
fi

url_map=$(mktemp)
trap 'rm -f "$url_map"' EXIT
cat > "$url_map" <<JSON
{
  "name": "rtchat-api",
  "defaultService": "https://www.googleapis.com/compute/v1/projects/$project/global/backendServices/rtchat-api-functions",
  "hostRules": [{"hosts": ["$hostname"], "pathMatcher": "api"}],
  "pathMatchers": [{
    "name": "api",
    "defaultService": "https://www.googleapis.com/compute/v1/projects/$project/global/backendServices/rtchat-api-functions",
    "pathRules": [{
      "paths": ["/healthz", "/kick/*", "/twitch/*", "/alchemy/*"],
      "service": "https://www.googleapis.com/compute/v1/projects/$project/global/backendServices/rtchat-api-agent"
    }]
  }]
}
JSON
gc compute url-maps import rtchat-api --global --source="$url_map"
ensure ssl-certificates rtchat-api --global --domains="$hostname"
ensure target-https-proxies rtchat-api --global \
  --ssl-certificates=rtchat-api --url-map=rtchat-api
ensure forwarding-rules rtchat-api --global \
  --load-balancing-scheme=EXTERNAL_MANAGED --network-tier=PREMIUM \
  --address=rtchat-api --target-https-proxy=rtchat-api --ports=443

# These ranges cover Google health checks and the global frontend's proxies.
# Preserve the existing autohealing check on / and its separate recycle policy.
gc compute firewall-rules update allow-health-check \
  --source-ranges=130.211.0.0/22,35.191.0.0/16

ip=$(gc compute addresses describe rtchat-api --global --format='value(address)')
printf 'DNS: %s A %s\n' "$hostname" "$ip"
printf 'Wait for the managed certificate to be ACTIVE, then verify https://%s/healthz\n' "$hostname"
