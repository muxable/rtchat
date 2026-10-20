#!/bin/bash
# Runs the end-to-end tests (integration_test/app_test.dart) on the booted
# Android emulator. Starting the test app on CI emulators occasionally hangs
# or drops the emulator before any test runs, so each attempt is time limited
# and retried once; the emulator log is dumped on failure.
#
# Only app_test.dart runs here: every file is a separate build, install and
# launch on the emulator, and the other files (the on-device TTS tests) skip
# themselves without a model, so they only added launches that could flake.
set -u

attempt() {
  # DDS is an IDE debugging proxy; integration tests can use the VM service
  # directly, avoiding DDS startup failures on CI emulators.
  timeout --kill-after=30s 20m flutter test integration_test/app_test.dart --no-dds --reporter expanded
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
