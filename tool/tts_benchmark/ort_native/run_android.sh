#!/usr/bin/env bash
# Compares ONNX Runtime execution providers (cpu, xnnpack, nnapi) on the raw
# TTS acoustic models, on an attached Android device.
#
# Usage: run_android.sh <work-dir> <models-dir> <out.jsonl> [adb-serial]
#   <work-dir>    output of build_android.sh
#   <models-dir>  <dest-dir>/models from scripts/download_models.sh
# Env: THREADS (default "2 4"), PROVIDERS (default "cpu xnnpack nnapi"),
#      LIMIT (messages per run, default 20)
set -euo pipefail

WORK="$1"
MODELS="$2"
OUT="$3"
SERIAL="${4:-}"
ADB=(adb)
[[ -n "$SERIAL" ]] && ADB=(adb -s "$SERIAL")
read -r -a THREADS <<<"${THREADS:-2 4}"
read -r -a PROVIDERS <<<"${PROVIDERS:-cpu xnnpack nnapi}"
# Optional subset of model names, e.g. ONLY="kokoro-multi-lang-v1_1".
ONLY="${ONLY:-}"
LIMIT="${LIMIT:-20}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORPUS="$HERE/../app/assets/corpus/en.txt"
DEV=/data/local/tmp/ortbench

# name kind onnx-file sample-rate
RUNS=(
  "kitten-nano-en-v0_8-fp32 kitten model.fp32.onnx 24000"
  "kitten-nano-en-v0_8-int8 kitten model.int8.onnx 24000"
  "vits-piper-en_US-libritts_r-medium vits en_US-libritts_r-medium.onnx 22050"
  "kokoro-int8-multi-lang-v1_1 kokoro model.int8.onnx 24000"
  "kokoro-multi-lang-v1_1 kokoro model.onnx 24000"
)

ABI="$("${ADB[@]}" shell getprop ro.product.cpu.abi | tr -d '\r')"
"${ADB[@]}" shell mkdir -p "$DEV"
"${ADB[@]}" push "$WORK/$ABI/ort_tts_bench" "$WORK/$ABI/libonnxruntime.so" "$DEV/" >/dev/null
"${ADB[@]}" shell chmod 755 "$DEV/ort_tts_bench"

: >"$OUT"
for run in "${RUNS[@]}"; do
  read -r name kind onnx sr <<<"$run"
  if [[ -n "$ONLY" && " $ONLY " != *" $name "* ]]; then continue; fi
  dir="$(dirname "$(find "$MODELS/$name" -name "$onnx" -print -quit)")"
  tmp="$(mktemp)"
  python3 -I "$HERE/make_ids.py" "$kind" "$dir/tokens.txt" "$CORPUS" >"$tmp.all"
  sed -n "1,${LIMIT}p" "$tmp.all" >"$tmp"
  rm -f "$tmp.all"
  "${ADB[@]}" shell mkdir -p "$DEV/$name"
  "${ADB[@]}" push "$dir/$onnx" "$DEV/$name/" >/dev/null
  "${ADB[@]}" push "$tmp" "$DEV/$name/ids.txt" >/dev/null
  voices=""
  if [[ -f "$dir/voices.bin" ]]; then
    "${ADB[@]}" push "$dir/voices.bin" "$DEV/$name/" >/dev/null
    voices="--voices $DEV/$name/voices.bin"
  fi
  rm -f "$tmp"
  for p in "${PROVIDERS[@]}"; do
    for t in "${THREADS[@]}"; do
      # shellcheck disable=SC2086
      line="$("${ADB[@]}" shell "cd $DEV && LD_LIBRARY_PATH=$DEV ./ort_tts_bench \
        --model $DEV/$name/$onnx --ids $DEV/$name/ids.txt $voices \
        --provider $p --threads $t --sample-rate $sr --label $name" 2>&1 | tail -1 | tr -d '\r' || true)"
      if [[ "$line" != "{"* ]]; then
        # Crashes (e.g. a segfault inside an execution provider) end up here.
        line="{\"label\":\"$name\",\"runtime\":\"ort\",\"provider\":\"$p\",\"threads\":$t,\"error\":\"${line//\"/\'}\"}"
      fi
      echo "$line" | tee -a "$OUT"
    done
  done
done
