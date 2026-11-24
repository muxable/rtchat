#!/usr/bin/env bash
# Run from the RTChat app root with the model staged on the runner.
set -euo pipefail
platform=$1
device=$2
app=com.rtirl.chat
report="$RUNNER_TEMP/playback-$platform.jsonl"
target=integration_test/profile_playback.dart

if [[ "$platform" == android ]]; then
  flutter build apk --profile --target-platform android-x64 -t "$target"
  adb -s "$device" install -r build/app/outputs/flutter-apk/app-profile.apk
  dir="/data/user/0/$app/app_flutter"
  if adb -s "$device" shell run-as "$app" id >/dev/null 2>&1; then
    owner=(run-as "$app")
  else
    # Profile APKs can disable run-as. The Google APIs CI emulator is userdebug.
    adb -s "$device" root
    adb -s "$device" wait-for-device
    test "$(adb -s "$device" shell id -u | tr -d '\r')" = 0
    owner=()
  fi
  adb -s "$device" shell "${owner[@]}" mkdir -p "$dir/supertonic-3"
  tar -C "$MODEL_DIR" -cf - . | adb -s "$device" shell -T "${owner[@]}" tar -xf - -C "$dir/supertonic-3"
  adb -s "$device" shell "${owner[@]}" rm -f "$dir/playback.jsonl"
  if (( ${#owner[@]} == 0 )); then
    uid=$(adb -s "$device" shell stat -c %u "/data/user/0/$app" | tr -d '\r')
    adb -s "$device" shell chown -R "$uid:$uid" "$dir"
    adb -s "$device" shell restorecon -RF "$dir"
  fi
  adb -s "$device" shell am start -n "$app/.MainActivity"
  read_report() { adb -s "$device" shell "${owner[@]}" cat "$dir/playback.jsonl" 2>/dev/null | tr -d '\r'; }
else
  flutter build ios --simulator --debug -t "$target"
  xcrun simctl install "$device" build/ios/iphonesimulator/Runner.app
  dir=$(xcrun simctl get_app_container "$device" "$app" data)/Documents
  mkdir -p "$dir/supertonic-3"
  cp -R "$MODEL_DIR/." "$dir/supertonic-3/"
  rm -f "$dir/playback.jsonl"
  xcrun simctl launch --terminate-running-process "$device" "$app"
  read_report() { cat "$dir/playback.jsonl" 2>/dev/null; }
fi

for (( attempt=0; attempt<120; ++attempt )); do
  read_report > "$report" || true
  if grep -q '"error":' "$report"; then cat "$report"; exit 1; fi
  if grep -q '"complete":true' "$report"; then
    cat "$report"
    break
  fi
  sleep 5
done

python3 - "$report" <<'PY'
import json
import sys

with open(sys.argv[1]) as f:
    results = [json.loads(line) for line in f]
if not results or results[-1] != {"complete": True}:
    raise SystemExit("Playback did not finish")
audio, = (r["audio_ms"] for r in results if "audio_ms" in r)
rounds = [r for r in results if "round" in r]
if audio <= 0 or [r["round"] for r in rounds] != [1, 2, 3]:
    raise SystemExit(f"Incomplete profile: {results}")
for row in rounds:
    if not (0 < row["first_audio_ms"] < row["done_ms"]) or row["done_ms"] <= audio - 50:
        raise SystemExit(f"Unexpected playback events: {row}")
    if row["round"] > 1 and not audio - 50 < row["speak_ms"] < audio + 10_000:
        raise SystemExit(f"Missed the playback deadline for {audio:.0f} ms of audio: {row}")
PY
