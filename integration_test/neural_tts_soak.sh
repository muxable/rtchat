#!/usr/bin/env bash
# Runs integration_test/neural_tts_soak_test.dart on an Android device or
# emulator with the screen off and the app in the background (#1507):
#
#   integration_test/neural_tts_soak.sh <supertonic-3 dir> [minutes] [out dir]
#
# <supertonic-3 dir> is a download of the Hugging Face repo
# Supertone/supertonic-3. Set ANDROID_SERIAL to pick the device. It
#
# 1. builds and installs the debug app and pushes the model into it;
# 2. starts the test, and once it says it started, presses HOME and turns
#    the screen off;
# 3. every 30 s samples the app's memory (dumpsys meminfo), CPU time
#    (/proc/<pid>/stat), process state and wake locks into samples.csv;
# 4. sends TRIM_MEMORY_RUNNING_CRITICAL at 10 and 22 min, which must release
#    the model (and TRIM_MEMORY_RUNNING_MODERATE at 11 min, which mustn't,
#    and without which am refuses the second RUNNING_CRITICAL). (Pressing HOME already sent TRIM_MEMORY_UI_HIDDEN, which
#    Flutter reports as memory pressure and which must not release it. `am
#    send-trim-memory HIDDEN` is refused for a foreground-service process.)
# 5. prints the test's SOAK_RESULT line, and uninstalls the app.
#
# Emulator numbers say nothing about a real phone's battery or heat.
set -euo pipefail

model=${1:?usage: $0 <supertonic-3 dir> [minutes] [out dir]}
minutes=${2:-30}
out=${3:-build/neural_tts_soak}
package=com.rtirl.chat
device_dir=/data/user/0/$package/files/supertonic-3
root=$(cd "$(dirname "$0")/.." && pwd)

mkdir -p "$out"
log="$out/test.log"
samples="$out/samples.csv"
events="$out/events.log"
: >"$events"

note() { echo "$(date +%T) $*" | tee -a "$events"; }

cd "$root"
flutter build apk --debug >/dev/null
adb install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null
bash packages/on_device_tts/tool/push_model.sh "$model" supertonic-3 "$package"

adb shell input keyevent KEYCODE_WAKEUP
flutter test integration_test/neural_tts_soak_test.dart \
  ${ANDROID_SERIAL:+-d "$ANDROID_SERIAL"} \
  --dart-define=ON_DEVICE_TTS_MODEL_DIR="$device_dir" \
  --dart-define=SOAK_MINUTES="$minutes" >"$log" 2>&1 &
test_pid=$!

until grep -q "SOAK started" "$log"; do
  if ! kill -0 "$test_pid" 2>/dev/null; then
    cat "$log"
    exit 1
  fi
  sleep 2
done
start=$(date +%s)
app_pid=$(adb shell pidof "$package" | tr -d '\r')
note "test started, app pid $app_pid"
sleep 20
adb shell input keyevent KEYCODE_HOME
sleep 2
adb shell input keyevent KEYCODE_SLEEP
note "home pressed, screen off: $(adb shell dumpsys power | grep -m1 mWakefulness= | tr -d '\r ')"

echo "elapsed_s,pss_kb,rss_kb,cpu_ticks,proc_state,wake_lock_held,screen" >"$samples"
sent_critical1=false
sent_moderate=false
sent_critical2=false
while kill -0 "$test_pid" 2>/dev/null; do
  elapsed=$(($(date +%s) - start))
  if [ "$sent_critical1" = false ] && [ "$elapsed" -ge 600 ]; then
    sent_critical1=true
    note "send-trim-memory RUNNING_CRITICAL: $(adb shell am send-trim-memory "$package" RUNNING_CRITICAL 2>&1 | tr -d '\r')"
  fi
  if [ "$sent_moderate" = false ] && [ "$elapsed" -ge 660 ]; then
    sent_moderate=true
    note "send-trim-memory RUNNING_MODERATE: $(adb shell am send-trim-memory "$package" RUNNING_MODERATE 2>&1 | tr -d '\r')"
  fi
  if [ "$sent_critical2" = false ] && [ "$elapsed" -ge 1320 ]; then
    sent_critical2=true
    note "send-trim-memory RUNNING_CRITICAL: $(adb shell am send-trim-memory "$package" RUNNING_CRITICAL 2>&1 | tr -d '\r')"
  fi
  meminfo=$(adb shell dumpsys meminfo "$package" 2>/dev/null | tr -d '\r')
  pss=$(echo "$meminfo" | awk '/TOTAL PSS:/ {print $3; exit}')
  rss=$(echo "$meminfo" | awk '/TOTAL RSS:/ {print $6; exit}')
  ticks=$(adb shell cat "/proc/$app_pid/stat" 2>/dev/null | tr -d '\r' |
    awk '{sub(/.*\) /, ""); print $12 + $13}')
  state=$(adb shell dumpsys activity processes "$package" 2>/dev/null | tr -d '\r' |
    grep -m1 -o 'procState=[^ ]*\|curProcState=[^ ]*' || true)
  wake=$(adb shell dumpsys power | tr -d '\r' | grep -c "PARTIAL_WAKE_LOCK *'on_device_tts:speak'" || true)
  screen=$(adb shell dumpsys power | tr -d '\r' | grep -m1 -o 'mWakefulness=[A-Za-z]*' || true)
  echo "$elapsed,${pss:-},${rss:-},${ticks:-},${state:-},$wake,${screen#mWakefulness=}" >>"$samples"
  sleep 30
done

wait "$test_pid" && status=0 || status=$?
note "test exited with $status"
grep -E "SOAK|All tests passed|Some tests failed|EXCEPTION|Expected|Actual" "$log" || true
adb shell input keyevent KEYCODE_WAKEUP
adb uninstall "$package" >/dev/null 2>&1 || true
exit "$status"
