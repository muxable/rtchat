#!/bin/sh
# Creates or updates the agent log-based metrics and the migration dashboard.
set -eu
cd "$(dirname "$0")"
project=rtchat-47692
for file in metrics/*.yaml; do
  name=$(basename "$file" .yaml)
  if gcloud logging metrics describe "$name" --project="$project" >/dev/null 2>&1; then
    gcloud logging metrics update "$name" --project="$project" --config-from-file="$file"
  else
    gcloud logging metrics create "$name" --project="$project" --config-from-file="$file"
  fi
done
existing=$(gcloud monitoring dashboards list --project="$project" \
  --filter='displayName="rtchat agent migration"' --format='value(name)')
if [ -n "$existing" ]; then
  etag=$(gcloud monitoring dashboards describe "$existing" --project="$project" --format='value(etag)')
  jq --arg etag "$etag" '. + {etag: $etag}' dashboard.json > /tmp/rtchat-dashboard.json
  gcloud monitoring dashboards update "$existing" --project="$project" --config-from-file=/tmp/rtchat-dashboard.json
else
  gcloud monitoring dashboards create --project="$project" --config-from-file=dashboard.json
fi

python3 apply_alerts.py --apply
