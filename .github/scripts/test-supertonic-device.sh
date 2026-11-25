#!/usr/bin/env bash
set -euo pipefail
model="$MODEL_DIR"
reference="$RUNNER_TEMP/reference"
target=integration_test/on_device_tts_test.dart
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
  flutter test "$target" -d "$device" --reporter expanded \
    --dart-define=ON_DEVICE_TTS_MODEL_DIR="$model" \
    --dart-define=ON_DEVICE_TTS_REFERENCE_DIR="$reference"
else
  device=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
print(next(d["udid"] for r in sorted(devices, reverse=True) if "iOS" in r for d in devices[r] if d["name"].startswith("iPhone")))')
  xcrun simctl boot "$device" || xcrun simctl bootstatus "$device" -b
  xcrun simctl bootstatus "$device" -b
  # Stage the fixtures in the installed app, then run the Flutter integration
  # suite without a VM-service connection to the host.
  report="tts-tests-$(uuidgen).json"
  flutter build ios --simulator --debug -t "$target" \
    --dart-define=ON_DEVICE_TTS_MODEL_DIR=model \
    --dart-define=ON_DEVICE_TTS_REFERENCE_DIR=reference \
    --dart-define=ON_DEVICE_TTS_REPORT="$report"
  app=com.rtirl.chat
  xcrun simctl install "$device" build/ios/iphonesimulator/Runner.app
  dir="$(xcrun simctl get_app_container "$device" "$app" data)/Documents"
  mkdir -p "$dir/model" "$dir/reference"
  cp -R "$model/." "$dir/model/"
  cp -R "$reference/." "$dir/reference/"
  xcrun simctl launch --terminate-running-process "$device" "$app"
  for ((attempt=0; attempt<180; ++attempt)); do
    if [[ -f "$dir/$report" ]]; then break; fi
    sleep 5
  done
  if [[ ! -f "$dir/$report" ]]; then
    echo "::error::The simulator app did not report its integration test results"
    exit 1
  fi
  cat "$dir/$report"
  jq -e '.passed and (.failures | length == 0) and (.tests | length >= 9)
         and (.tests | index("matches the reference implementation") != null)
         and (.tests | index("streams a single chat message before its final PCM is ready") != null)' "$dir/$report"
fi
bash .github/scripts/profile-supertonic-device.sh "$1" "$device"
