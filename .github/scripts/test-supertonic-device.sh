#!/usr/bin/env bash
set -euo pipefail
model="$MODEL_DIR"
reference="$RUNNER_TEMP/reference"
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
  flutter build ios --simulator --debug
  xcrun simctl install "$device" build/ios/iphonesimulator/Runner.app
  dir=$(xcrun simctl get_app_container "$device" com.rtirl.chat data)/Documents
  mkdir -p "$dir/model" "$dir/reference"
  cp -R "$model/." "$dir/model/"
  cp -R "$reference/." "$dir/reference/"
  model="$dir/model"
  reference="$dir/reference"
fi
status=0
flutter test integration_test/on_device_tts_test.dart -d "$device" --reporter expanded \
  --dart-define=ON_DEVICE_TTS_MODEL_DIR="$model" \
  --dart-define=ON_DEVICE_TTS_REFERENCE_DIR="$reference" || status=$?
bash .github/scripts/profile-supertonic-device.sh "$1" "$device"
exit "$status"
