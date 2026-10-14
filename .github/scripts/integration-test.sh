#!/bin/bash
# Runs the integration tests on the booted Android emulator. Starting the test
# app on CI emulators occasionally hangs before any test runs, so each attempt
# is time limited and retried once; the emulator log is dumped on failure.
set -u

attempt() {
  timeout 20m flutter test integration_test --reporter expanded
}

if attempt; then
  exit 0
fi
echo "::warning::integration tests failed or hung; retrying once"
adb logcat -d -t 300 || true
if attempt; then
  exit 0
fi
echo "::error::integration tests failed twice"
adb logcat -d -t 500 || true
exit 1
