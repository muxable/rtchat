#!/usr/bin/env bash
# Run from the RTChat app root with the model staged on the runner.
set -euo pipefail
platform=$1
device=$2
app=com.rtirl.chat
report="$RUNNER_TEMP/playback-$platform.jsonl"
target=integration_test/profile_playback.dart

# Allow installation, simulator startup and indexing to settle before timing the
# first model load. Keep all measurements even if the guest stays busy.
wait_for_idle() {
  python3 - "$platform" "$device" <<'PYTHON'
import ctypes
import subprocess
import sys
import time

platform, device = sys.argv[1:]
if platform == "ios":
    libc = ctypes.CDLL("/usr/lib/libSystem.B.dylib")
    host = libc.mach_host_self()
    def sample():
        ticks = (ctypes.c_uint32 * 4)()
        count = ctypes.c_uint32(4)
        if libc.host_statistics(host, 3, ticks, ctypes.byref(count)) or count.value != 4:
            raise RuntimeError("Couldn't read host CPU counters")
        return sum(ticks), ticks[2]  # CPU_STATE_IDLE
else:
    def sample():
        row = subprocess.check_output(
            ["adb", "-s", device, "shell", "head", "-1", "/proc/stat"], text=True
        )
        ticks = list(map(int, row.split()[1:9]))
        return sum(ticks), ticks[3] + ticks[4]

previous = sample()
quiet = 0
for _ in range(36):
    time.sleep(5)
    current = sample()
    idle = (current[1] - previous[1]) / max(1, current[0] - previous[0])
    previous = current
    print(f"{platform} CPU idle {idle:.0%}", flush=True)
    quiet = quiet + 1 if idle >= 0.75 else 0
    if quiet == 3:
        break
if platform == "ios" and quiet < 3:
    processes = subprocess.check_output(
        ["ps", "-A", "-o", "pcpu=,pid=,comm="], text=True
    ).splitlines()
    processes.sort(key=lambda row: float(row.split(None, 1)[0]), reverse=True)
    print("Highest CPU usage before playback (%CPU, PID, command):", flush=True)
    print("\n".join(processes[:12]), flush=True)
PYTHON
}

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
  wait_for_idle
  adb -s "$device" shell am start -n "$app/.MainActivity"
  read_report() { adb -s "$device" shell "${owner[@]}" cat "$dir/playback.jsonl" 2>/dev/null | tr -d '\r'; }
else
  flutter build ios --simulator --debug -t "$target"
  xcrun simctl install "$device" build/ios/iphonesimulator/Runner.app
  dir=$(xcrun simctl get_app_container "$device" "$app" data)/Documents
  mkdir -p "$dir/supertonic-3"
  cp -R "$MODEL_DIR/." "$dir/supertonic-3/"
  rm -f "$dir/playback.jsonl"
  wait_for_idle
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
generation = [r for r in results if "synthesis_round" in r]
if [r["synthesis_round"] for r in generation] != [1, 2, 3]:
    raise SystemExit(f"Incomplete synthesis measurements: {generation}")
for r in generation:
    if not 0 < r["synthesis_ms"] < r["audio_ms"]:
        raise SystemExit(f"Synthesis exceeded the real-time budget: {r}")
audio = generation[0]["audio_ms"]
rounds = [r for r in results if "round" in r]
if audio <= 0 or [r["round"] for r in rounds] != [1, 2, 3]:
    raise SystemExit(f"Incomplete profile: {results}")
for row in rounds:
    if not (0 < row["first_audio_ms"] < row["done_ms"]) or row["done_ms"] <= audio - 50:
        raise SystemExit(f"Unexpected playback events: {row}")
    if row["round"] > 1 and not audio - 50 < row["speak_ms"] < audio + 10_000:
        raise SystemExit(f"Missed the playback deadline for {audio:.0f} ms of audio: {row}")
PY
