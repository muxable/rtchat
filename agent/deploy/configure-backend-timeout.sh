#!/bin/sh
# The agent gives callable work 60 seconds. A 30-second backend timeout
# interrupts valid requests with a load-balancer HTML 504 instead of their
# callable response. Leave five seconds for the response to reach the edge.
# Cloud Functions proxies have their own shorter request deadline.
set -eu
mode=${1:---check}
case "$mode" in
  --check|--apply) ;;
  *) echo "usage: $0 [--check|--apply]" >&2; exit 2 ;;
esac
project=rtchat-47692
backend=rtchat-api-agent
desired=65
current=$(gcloud compute backend-services describe "$backend" \
  --global --project="$project" --format='value(timeoutSec)')
if [ "$current" = "$desired" ]; then
  echo "$backend timeout is already ${desired}s."
  exit 0
fi
echo "$backend timeout: ${current}s -> ${desired}s"
if [ "$mode" = --check ]; then
  echo "Read-only plan; use --apply to update the backend timeout."
  exit 0
fi
gcloud compute backend-services update "$backend" --global \
  --project="$project" --timeout="${desired}s" --quiet
actual=$(gcloud compute backend-services describe "$backend" \
  --global --project="$project" --format='value(timeoutSec)')
if [ "$actual" != "$desired" ]; then
  echo "Backend timeout verification failed: ${actual}s" >&2
  exit 1
fi
echo "Verified $backend timeout: ${actual}s."
