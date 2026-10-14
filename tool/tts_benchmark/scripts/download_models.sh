#!/usr/bin/env bash
# Downloads the sherpa-onnx pre-converted TTS models used by the benchmark.
#
# Usage: download_models.sh <dest-dir> [model-name ...]
#
# Each archive is extracted into its own new directory under
# <dest-dir>/models/<model-name>/ and its sha256 is written to
# <dest-dir>/SHA256SUMS. Model files are untrusted data: keep <dest-dir>
# outside the repository and never run anything from inside it.
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <dest-dir> [model-name ...]" >&2
  exit 64
fi

DEST="$1"
shift
BASE_URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models"

DEFAULT_MODELS=(
  kokoro-int8-multi-lang-v1_1
  kokoro-multi-lang-v1_1
  kokoro-int8-en-v0_19
  kitten-nano-en-v0_8-int8
  kitten-nano-en-v0_8-fp32
  kitten-micro-en-v0_8
  kitten-mini-en-v0_8
  sherpa-onnx-supertonic-3-tts-int8-2026-05-11
  vits-piper-en_US-libritts_r-medium
  vits-piper-en_US-libritts_r-medium-int8
  vits-piper-ru_RU-irina-medium
  vits-piper-ru_RU-irina-medium-int8
)

if [[ $# -gt 0 ]]; then
  MODELS=("$@")
else
  MODELS=("${DEFAULT_MODELS[@]}")
fi

mkdir -p "$DEST/archives" "$DEST/models"
for name in "${MODELS[@]}"; do
  archive="$DEST/archives/$name.tar.bz2"
  if [[ ! -f "$archive" ]]; then
    echo "downloading $name"
    curl -fsSL --retry 3 -o "$archive.part" "$BASE_URL/$name.tar.bz2"
    mv "$archive.part" "$archive"
  fi
  out="$DEST/models/$name"
  if [[ ! -d "$out" ]]; then
    mkdir "$out"
    # --no-same-owner/--no-same-permissions: treat the archive as untrusted.
    tar --no-same-owner --no-same-permissions -xjf "$archive" -C "$out"
  fi
done

(cd "$DEST/archives" && sha256sum ./*.tar.bz2 | sed 's# \./# #') > "$DEST/SHA256SUMS"
echo "wrote $DEST/SHA256SUMS"
