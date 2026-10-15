#!/usr/bin/env bash
# Copies a directory into an installed, debuggable Android app's internal
# files directory, where the on-device integration tests read it.
#
#   tool/push_model.sh <dir> [name on the device] [package]
#
# For a Supertonic 3 model, <dir> is a download of the Hugging Face repo
# Supertone/supertonic-3 (onnx/ and voice_styles/). The name defaults to
# supertonic-3 and the package to com.rtirl.chat, so the model lands in
# /data/user/0/com.rtirl.chat/files/supertonic-3. Set ANDROID_SERIAL to pick
# the device.
set -euo pipefail

src=${1:?usage: $0 <dir> [name] [package]}
name=${2:-supertonic-3}
package=${3:-com.rtirl.chat}
staging=/data/local/tmp/on_device_tts-$name

adb shell rm -rf "$staging"
adb push "$src" "$staging" >/dev/null
adb shell run-as "$package" sh -c "'rm -rf files/$name && mkdir -p files && cp -r $staging files/$name'"
adb shell rm -rf "$staging"
echo "Pushed $src to /data/user/0/$package/files/$name"
