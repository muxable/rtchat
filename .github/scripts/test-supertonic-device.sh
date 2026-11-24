#!/usr/bin/env bash
set -euo pipefail
model="$MODEL_DIR"
reference="$RUNNER_TEMP/reference"
token=
if [[ "$1" == android ]]; then
  device=$(adb get-serialno)
  flutter build apk --debug
  adb install -r build/app/outputs/flutter-apk/app-debug.apk
  for pair in "$model|model" "$reference|reference"; do
    src=${pair%|*}
    dest=${pair##*|}
    adb shell run-as com.rtirl.chat mkdir -p "files/$dest"
    tar -C "$src" -cf - . | adb shell -T run-as com.rtirl.chat tar -xf - -C "files/$dest"
  done
  model=/data/user/0/com.rtirl.chat/files/model
  reference=/data/user/0/com.rtirl.chat/files/reference
else
  device=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
print(next(d["udid"] for r in sorted(devices, reverse=True) if "iOS" in r for d in devices[r] if d["name"].startswith("iPhone")))')
  xcrun simctl boot "$device" || xcrun simctl bootstatus "$device" -b
  xcrun simctl bootstatus "$device" -b
  token=$(uuidgen)
  stage_ios_fixtures() {
    local dir marker
    while true; do
      dir=$(xcrun simctl get_app_container "$device" com.rtirl.chat data 2>/dev/null || true)
      marker="$dir/Documents/tts-fixtures-$token"
      if [[ -n "$dir" && -f "$marker.request" ]]; then
        mkdir -p "$dir/Documents/model" "$dir/Documents/reference"
        cp -R "$MODEL_DIR/." "$dir/Documents/model/"
        cp -R "$RUNNER_TEMP/reference/." "$dir/Documents/reference/"
        touch "$marker.ready"
        return
      fi
      sleep 2
    done
  }
  stage_ios_fixtures &
  staging=$!
  trap 'kill "$staging" 2>/dev/null || true' EXIT
  model=model
  reference=reference
fi
status=0
flutter test integration_test/on_device_tts_test.dart -d "$device" --reporter expanded \
  --dart-define=ON_DEVICE_TTS_MODEL_DIR="$model" \
  --dart-define=ON_DEVICE_TTS_REFERENCE_DIR="$reference" --dart-define=ON_DEVICE_TTS_FIXTURE_TOKEN="$token" || status=$?
if [[ -n "${staging:-}" ]]; then
  kill "$staging" 2>/dev/null || true
  wait "$staging" 2>/dev/null || true
  trap - EXIT
fi
bash .github/scripts/profile-supertonic-device.sh "$1" "$device"
exit "$status"
