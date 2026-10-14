#!/usr/bin/env bash
# Runs the benchmark app on an attached Android device or emulator.
#
# Usage: run_android.sh <models-dir> <config.json> <out-dir> [adb-serial]
#
#   <models-dir>   <dest-dir>/models from download_models.sh
#   <config.json>  benchmark config (see configs/); every model it names is
#                  pushed to the device
#   <out-dir>      results.jsonl and logcat are written here
#
# Builds and installs the release APK, pushes the models and config into the
# app's external files directory, then launches the app until every run in
# the config has a result. With "one_run_per_launch": true each run gets a
# fresh process, so peak RSS is per run.
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "usage: $0 <models-dir> <config.json> <out-dir> [adb-serial]" >&2
  exit 64
fi
MODELS="$1"
CONFIG="$2"
OUT="$3"
SERIAL="${4:-}"
ADB=(adb)
[[ -n "$SERIAL" ]] && ADB=(adb -s "$SERIAL")

PKG=com.rtirl.tts_benchmark_app
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$HERE/../app"
DEV_DIR="/sdcard/Android/data/$PKG/files"
mkdir -p "$OUT"

if [[ "${SKIP_BUILD:-0}" != 1 ]]; then
  (cd "$APP" && flutter build apk --release --split-per-abi)
fi
ABI="$("${ADB[@]}" shell getprop ro.product.cpu.abi | tr -d '\r')"
APK="$APP/build/app/outputs/flutter-apk/app-$ABI-release.apk"
"${ADB[@]}" install -r "$APK"

# Launch once so Android creates the external files directory.
"${ADB[@]}" shell monkey -p "$PKG" 1 >/dev/null
sleep 3
"${ADB[@]}" shell am force-stop "$PKG"

"${ADB[@]}" shell mkdir -p "$DEV_DIR/models"
mapfile -t NAMES < <(python3 -I -c '
import json, sys
print("\n".join(sorted({r["model"] for r in json.load(open(sys.argv[1]))["runs"]})))
' "$CONFIG")
for name in "${NAMES[@]}"; do
  if "${ADB[@]}" shell "test -d $DEV_DIR/models/$name"; then
    echo "already on device: $name"
  else
    echo "pushing $name"
    "${ADB[@]}" push "$MODELS/$name" "$DEV_DIR/models/" >/dev/null
  fi
done

"${ADB[@]}" push "$CONFIG" "$DEV_DIR/bench_config.json" >/dev/null
"${ADB[@]}" shell rm -f "$DEV_DIR/results.jsonl"
"${ADB[@]}" logcat -c

TOTAL="$(python3 -I -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["runs"]))' "$CONFIG")"
while :; do
  "${ADB[@]}" shell am start -W -n "$PKG/.MainActivity" >/dev/null
  # Wait for the process to exit (one run per launch) or print DONE.
  while "${ADB[@]}" shell pidof "$PKG" >/dev/null; do
    if "${ADB[@]}" logcat -d -s flutter | grep -q "TTSBENCH DONE"; then
      break 2
    fi
    sleep 2
  done
  done_runs="$("${ADB[@]}" shell "cat $DEV_DIR/results.jsonl 2>/dev/null | wc -l" | tr -d '\r')"
  echo "runs finished: $done_runs/$TOTAL"
  [[ "$done_runs" -ge "$TOTAL" ]] && break
  if [[ "$done_runs" == "${prev_runs:-}" ]]; then
    # The process died without writing a result (native crash or OOM kill):
    # record it so the next launch moves on to the following run.
    echo "run $done_runs crashed; see $OUT/logcat.txt"
    "${ADB[@]}" logcat -d >> "$OUT/crash_logcat.txt"
    "${ADB[@]}" shell "echo '{\"run_index\": $done_runs, \"error\": \"process died\"}' >> $DEV_DIR/results.jsonl"
    done_runs=$((done_runs + 1))
    [[ "$done_runs" -ge "$TOTAL" ]] && break
  fi
  prev_runs="$done_runs"
done

"${ADB[@]}" pull "$DEV_DIR/results.jsonl" "$OUT/results.jsonl" >/dev/null
"${ADB[@]}" logcat -d -s flutter > "$OUT/logcat.txt"
"${ADB[@]}" shell getprop > "$OUT/device_props.txt"
echo "results in $OUT/results.jsonl"
