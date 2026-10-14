#!/usr/bin/env bash
# Runs the full desktop matrix used in the #1500 spike.
#
# Usage: run_all.sh <python> <models-dir> <out-dir> [threads...]
#   <python>      interpreter with sherpa-onnx installed (see README)
#   <models-dir>  <dest-dir>/models from download_models.sh
#   <out-dir>     where results (*.jsonl, *.log, wav/) are written
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "usage: $0 <python> <models-dir> <out-dir> [threads...]" >&2
  exit 64
fi
PY="$1"
MODELS="$2"
OUT="$3"
shift 3
THREADS=("${@:-1 2 4}")
# shellcheck disable=SC2206
THREADS=(${THREADS[*]})

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORPUS="$HERE/../app/assets/corpus"
mkdir -p "$OUT"

EN_MODELS=(
  kitten-nano-en-v0_8-int8
  kitten-nano-en-v0_8-fp32
  kitten-micro-en-v0_8
  kitten-mini-en-v0_8
  kokoro-int8-en-v0_19
  kokoro-int8-multi-lang-v1_1
  kokoro-multi-lang-v1_1
  vits-piper-en_US-libritts_r-medium
  vits-piper-en_US-libritts_r-medium-int8
  sherpa-onnx-supertonic-3-tts-int8-2026-05-11
)
RU_MODELS=(
  vits-piper-ru_RU-irina-medium
  vits-piper-ru_RU-irina-medium-int8
  sherpa-onnx-supertonic-3-tts-int8-2026-05-11
)

"$PY" -I "$HERE/bench.py" --models-dir "$MODELS" --corpus "$CORPUS/en.txt" \
  --threads "${THREADS[@]}" --save-wav-dir "$OUT/wav/en" \
  --out "$OUT/desktop_en.jsonl" "${EN_MODELS[@]}" 2>&1 | tee "$OUT/desktop_en.log"

"$PY" -I "$HERE/bench.py" --models-dir "$MODELS" --corpus "$CORPUS/ru.txt" \
  --lang ru --threads "${THREADS[@]}" --save-wav-dir "$OUT/wav/ru" \
  --out "$OUT/desktop_ru.jsonl" "${RU_MODELS[@]}" 2>&1 | tee "$OUT/desktop_ru.log"

# What the generation callback yields per model type (2 threads).
taskset -c 0-1 "$PY" -I "$HERE/streaming.py" --models-dir "$MODELS" --threads 2 \
  kitten-nano-en-v0_8-int8 kitten-micro-en-v0_8 kokoro-int8-multi-lang-v1_1 \
  kokoro-multi-lang-v1_1 vits-piper-en_US-libritts_r-medium \
  sherpa-onnx-supertonic-3-tts-int8-2026-05-11 > "$OUT/streaming_en.jsonl"
taskset -c 0-1 "$PY" -I "$HERE/streaming.py" --models-dir "$MODELS" --threads 2 --lang ru \
  vits-piper-ru_RU-irina-medium sherpa-onnx-supertonic-3-tts-int8-2026-05-11 \
  > "$OUT/streaming_ru.jsonl"
