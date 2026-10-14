#!/usr/bin/env bash
# Builds ort_tts_bench for Android against the official onnxruntime-android
# AAR (Maven Central), which includes the NNAPI and XNNPACK providers.
#
# Usage: build_android.sh <work-dir> [abi ...]   (default: arm64-v8a x86_64)
# Needs ANDROID_NDK_HOME (or ~/Android/Sdk/ndk/<version>).
# Output: <work-dir>/<abi>/{ort_tts_bench,libonnxruntime.so}
set -euo pipefail

ORT_VERSION="${ORT_VERSION:-1.28.0}"
WORK="$1"
shift
ABIS=("${@:-arm64-v8a x86_64}")
# shellcheck disable=SC2206
ABIS=(${ABIS[*]})
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NDK="${ANDROID_NDK_HOME:-}"
if [[ -z "$NDK" ]]; then
  NDK="$(find "$HOME/Android/Sdk/ndk" -mindepth 1 -maxdepth 1 -type d | sort | tail -1)"
fi
TC="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"

mkdir -p "$WORK/aar"
AAR="$WORK/onnxruntime-android-$ORT_VERSION.aar"
if [[ ! -f "$AAR" ]]; then
  curl -fsSL -o "$AAR" \
    "https://repo1.maven.org/maven2/com/microsoft/onnxruntime/onnxruntime-android/$ORT_VERSION/onnxruntime-android-$ORT_VERSION.aar"
fi
(cd "$WORK/aar" && unzip -qo "$AAR" 'headers/*' 'jni/*')

for abi in "${ABIS[@]}"; do
  case "$abi" in
    arm64-v8a) triple=aarch64-linux-android28 ;;
    x86_64) triple=x86_64-linux-android28 ;;
    armeabi-v7a) triple=armv7a-linux-androideabi28 ;;
    *) echo "unknown abi $abi" >&2; exit 64 ;;
  esac
  mkdir -p "$WORK/$abi"
  cp "$WORK/aar/jni/$abi/libonnxruntime.so" "$WORK/$abi/"
  "$TC/$triple-clang++" -O2 -std=c++17 -static-libstdc++ \
    -I"$WORK/aar/headers" "$HERE/ort_tts_bench.cc" \
    -L"$WORK/$abi" -lonnxruntime -Wl,-rpath,'$ORIGIN' \
    -o "$WORK/$abi/ort_tts_bench"
  echo "built $WORK/$abi/ort_tts_bench"
done
