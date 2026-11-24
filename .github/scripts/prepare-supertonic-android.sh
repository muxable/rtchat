#!/usr/bin/env bash
# Install the Android artifacts used by the playback CI before Gradle and the emulator start.
set -euo pipefail

sdk=${ANDROID_HOME:?Android SDK path is required}
flutter_root=${FLUTTER_ROOT:-$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")}
extension="$flutter_root/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt"
ndk=$(sed -nE 's/^[[:space:]]*val ndkVersion: String = "([^"]+)".*/\1/p' "$extension")
test -n "$ndk" || { echo "Cannot determine the Flutter NDK version from $extension" >&2; exit 1; }

install_package() {
  local package=$1 required=$2
  for attempt in 1 2 3; do
    if [[ -s "$required" ]]; then return 0; fi
    echo "Installing $package (attempt $attempt)"
    if "$sdk/cmdline-tools/latest/bin/sdkmanager" --install "$package" && [[ -s "$required" ]]; then
      return 0
    fi
    df -h "$sdk"
    if [[ "$attempt" != 3 ]]; then sleep 10; fi
  done
  echo "Missing $required after installing $package" >&2
  return 1
}

install_package "ndk;$ndk" "$sdk/ndk/$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
install_package 'system-images;android-35;google_apis;x86_64' "$sdk/system-images/android-35/google_apis/x86_64/system.img"
