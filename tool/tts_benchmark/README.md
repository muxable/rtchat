# On-device TTS benchmark (#1500)

A harness for measuring sherpa-onnx text-to-speech models on desktops and
real phones, built for the spike in #1500 (epic #1499). It is **not** part of
the rtchat build: the root `analysis_options.yaml` excludes this directory,
and the app here has its own `pubspec.yaml`.

```
tool/tts_benchmark/
  scripts/download_models.sh   fetch + extract models, write SHA256SUMS
  scripts/run_android.sh       build, install, push models, run, pull results
  scripts/summarize.py         JSONL -> Markdown table
  desktop/bench.py             desktop benchmark (sherpa-onnx Python wheel)
  desktop/streaming.py         what the generation callback yields per model
  desktop/intelligibility.py   TTS -> ASR round trip, word error rate
  desktop/run_all.sh           the desktop matrix used for #1500
  configs/android_*.json       benchmark configs for the app
  app/                         Flutter benchmark app (sherpa_onnx +
                               flutter_onnxruntime), Android and iOS
  app/assets/corpus/           50 English and 10 Russian chat messages
```

## What it measures

For each model, thread count and execution provider:

- **load time**: creating the `OfflineTts` (or ORT session).
- **time to first audio (TTFA)**: time from `generate()` to the first
  generation callback, which is the first moment a player could start. The
  app also reports when that chunk arrives on the UI isolate
  (`ttfa_ui_isolate_median_s`), because synthesis runs on a worker isolate
  and streams chunks to the UI isolate, which is how the real engine would
  feed the player.
- **real-time factor (RTF)**: synthesis time / audio duration over the whole
  corpus. Below 1 is faster than real time.
- **peak RSS**: `ProcessInfo.maxRss` in the app (use
  `"one_run_per_launch": true` so each run gets a fresh process),
  `ru_maxrss` on desktop.
- **model size on disk**: the extracted model directory, including
  `espeak-ng-data` (~18 MB, identical in every pack that has it).

The corpus mimics what `TtsModel.getVocalization` produces: "<author> said
<text>", emote codes kept as words, links reduced to the host, emoji dropped.

## Getting models

Models come from the sherpa-onnx `tts-models` GitHub release (which mirrors
the Hugging Face originals). Treat them as untrusted data: put them outside
the repo and don't run anything from inside that directory.

```sh
tool/tts_benchmark/scripts/download_models.sh ~/.cache/rtchat-tts-spike
# or a subset:
tool/tts_benchmark/scripts/download_models.sh ~/.cache/rtchat-tts-spike \
  kitten-nano-en-v0_8-int8 vits-piper-en_US-libritts_r-medium-int8
```

This writes `~/.cache/rtchat-tts-spike/models/<name>/...` and
`~/.cache/rtchat-tts-spike/SHA256SUMS`.

## Running on an Android phone

Requirements: Flutter (stable), Android SDK with `adb`, a JDK 17 with
`javac` (a JRE is not enough for the Gradle build; set `JAVA_HOME`), USB
debugging enabled on the phone.

```sh
cd tool/tts_benchmark
scripts/run_android.sh ~/.cache/rtchat-tts-spike/models \
  configs/android_full.json /tmp/tts-results/<phone-name> [adb-serial]
python3 -I scripts/summarize.py /tmp/tts-results/<phone-name>/results.jsonl
```

The script builds `flutter build apk --release --split-per-abi`, installs the
APK for the phone's ABI, pushes the models named in the config to
`/sdcard/Android/data/com.rtirl.tts_benchmark_app/files/models/`, and then
launches the app until every run has a result. If the app dies during a run
(native crash, low-memory kill), the run is recorded as `"process died"` and
`crash_logcat.txt` is saved. Expect `android_full.json` to take 20-60 minutes
on a mid-range phone; `android_smoke.json` takes about a minute. Keep the
screen on and the phone on a charger, and note its temperature: thermal
throttling changes the results.

Report the phone model, SoC and RAM alongside `results.jsonl`
(`device_props.txt` has the build properties).

## Running on an iPhone

There is no script for iOS; it needs a Mac with Xcode.

1. `cd tool/tts_benchmark/app && flutter build ios --release`, then open
   `ios/Runner.xcworkspace`, set a development team, and run on the device
   (Release configuration for meaningful numbers).
2. The app has file sharing enabled. In Finder, select the iPhone, open
   **Files**, and drag a `models` folder (subfolders named exactly like the
   archives, e.g. `models/kitten-nano-en-v0_8-int8/`) and a
   `bench_config.json` into "tts_benchmark_app".
3. Relaunch the app; it starts running automatically. `results.jsonl` appears
   in the same Files view when it is done. For iOS, use configs with
   `"one_run_per_launch": false` (nothing relaunches the app), so peak RSS is
   cumulative across runs; run one model per config if you need clean
   numbers.

The benchmark app's deployment target is iOS 16.0 because
`flutter_onnxruntime` (only used for the `"runtime": "ort"` runs) requires
it. `sherpa_onnx_ios` itself only needs iOS 13.0. To test on an iOS 15.5
device, remove `flutter_onnxruntime` and `lib/ort_bench.dart` and set the
target back to 15.5. To try CoreML, add runs with `"provider": "coreml"`.

## Config format

```json
{
  "one_run_per_launch": true,
  "runs": [
    {"model": "kitten-nano-en-v0_8-int8", "threads": 2},
    {"model": "kokoro-int8-multi-lang-v1_1", "threads": 4, "provider": "cpu"},
    {"model": "vits-piper-ru_RU-irina-medium", "corpus": "ru", "lang": "ru"},
    {"model": "vits-piper-en_US-libritts_r-medium", "runtime": "ort",
     "provider": "xnnpack", "limit": 20}
  ]
}
```

| key | default | meaning |
|---|---|---|
| `model` | | directory name under `models/` (the archive name) |
| `threads` | 2 | ONNX Runtime intra-op threads |
| `provider` | `cpu` | `cpu`, `xnnpack`, `nnapi`, `coreml` |
| `runtime` | `sherpa` | `sherpa` = full TTS through `sherpa_onnx`; `ort` = raw acoustic model through `flutter_onnxruntime` (official ORT builds, which include XNNPACK/NNAPI/CoreML) with character-level token ids, for comparing execution providers only |
| `corpus` | `en` | `en`, `ru` or `streaming_en` (asset file name) |
| `lang` | `en` | language for Supertonic |
| `sid` | 0 | speaker id |
| `limit` | 0 | only the first N messages (0 = all) |
| `max_num_sentences` | 1 | sherpa `max_num_sentences` |

Note that the sherpa-onnx prebuilt Android libraries are built without NNAPI
or XNNPACK support: `"provider": "nnapi"` or `"xnnpack"` with
`"runtime": "sherpa"` silently falls back to the CPU (logcat shows the
fallback warning). Use `"runtime": "ort"` to measure those providers.

## Desktop

```sh
python3 -m venv ~/.cache/rtchat-tts-spike-venv
~/.cache/rtchat-tts-spike-venv/bin/pip install sherpa-onnx==1.13.8 numpy
tool/tts_benchmark/desktop/run_all.sh ~/.cache/rtchat-tts-spike-venv/bin/python \
  ~/.cache/rtchat-tts-spike/models /tmp/tts-desktop 1 2 4
python3 -I tool/tts_benchmark/scripts/summarize.py /tmp/tts-desktop/desktop_en.jsonl
```

`bench.py` pins each run to N cores with `taskset` and N ONNX Runtime
threads, to roughly mimic a phone with N big cores. A desktop core is still
several times faster than a phone core, so treat desktop numbers as a
relative ranking, not as phone numbers.
