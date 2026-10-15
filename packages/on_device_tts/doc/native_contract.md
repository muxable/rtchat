# Native ONNX Runtime engine: platform contract

The Dart side (`OnnxTtsPlatform`, `OnnxTts`) talks to a native engine that
runs neural TTS models on the official ONNX Runtime. Android implements it in
Kotlin (`android/`), iOS in Swift (`ios/`). Both must behave as described
here; where this document and an implementation disagree, fix one of them.

## Channels

| channel | type | codec |
|---|---|---|
| `on_device_tts/onnx` | `MethodChannel` | standard |
| `on_device_tts/onnx/events` | `EventChannel` | standard |
| `on_device_tts/memory` | `EventChannel` | standard (Android only) |

Platforms without the engine answer every call with "not implemented"
(`MissingPluginException` in Dart).

## Methods

All arguments are in one map. Defaults apply when a key is missing or null.

### `load`

| argument | type | default |
|---|---|---|
| `modelType` | `String` | (required) only `'supertonic'` today |
| `modelDir` | `String` | (required) absolute path of the model directory |
| `numThreads` | `int` | `2` |
| `provider` | `String` | `'cpu'`: one of `cpu`, `xnnpack`, `nnapi`, `coreml` |

Returns a `String` handle, e.g. `supertonic-1`. Handles are never reused
within a process.

Loads the sessions once; every later call with the handle reuses them.
`numThreads` is ONNX Runtime's intra-op thread count. With `xnnpack` it is
XNNPACK's thread pool instead, and the session's own pool gets 1 thread, as
ONNX Runtime recommends. Every session sets
`session.intra_op.allow_spinning=0`, whatever the provider, so idle intra-op
threads block instead of busy-waiting between messages; see
[Threads and power](#threads-and-power).

A provider that is unknown, not available on the platform (`nnapi` on iOS,
`coreml` on Android) or that fails to take a model **falls back to `cpu`**
and logs it (Android: logcat tag `OnDeviceTts`); this is not an error. Once a
provider has failed for one of the model's files, the rest of that model's
files load on `cpu` too.

Errors: `load_failed` for an unknown `modelType`, a missing directory or
file, unreadable JSON, or a model that ONNX Runtime can't load.
`bad_args` for `numThreads < 1`.

#### Supertonic model directory

The layout of the Hugging Face repository `Supertone/supertonic-3`:

```
<modelDir>/
  onnx/
    tts.json
    unicode_indexer.json
    duration_predictor.onnx   (or duration_predictor.int8.onnx)
    text_encoder.onnx         (or text_encoder.int8.onnx)
    vector_estimator.onnx     (or vector_estimator.int8.onnx)
    vocoder.onnx              (or vocoder.int8.onnx)
  voice_styles/
    F1.json ... M5.json
```

If `onnx/` doesn't exist, the files are looked up in `<modelDir>` itself.
For each model, `<name>.onnx` wins over `<name>.int8.onnx`. Other files are
ignored.

### `voices`

`{handle}` → `List<Map>` of `{id: String, name: String, language: String?}`,
sorted by `id`.

For Supertonic, there is one voice per `voice_styles/*.json` file: `id` and
`name` are the file name without `.json` (`F1`). `language` is omitted: every
voice speaks all of the model's languages.

### `speak`

| argument | type | default |
|---|---|---|
| `handle` | `String` | (required) |
| `utteranceId` | `String` | (required) echoed in events |
| `segments` | `List<String>` | (required) |
| `language` | `String` | (required) BCP-47 tag |
| `voiceId` | `String` | (required) |
| `speed` | `double` | `1.0` |
| `steps` | `int` | `5` |

Returns `null` once the **last segment has finished playing**, or once `stop`
cut the utterance off (also `null`).

* The caller splits text into segments (clauses). The engine synthesizes
  segment *i + 1* on its synthesis thread while segment *i* plays, and
  streams PCM to the audio output as soon as each segment (each chunk of a
  long segment, see below) is ready. Nothing is written to a file.
* Segments play back to back, with no silence added between them.
  Empty or blank segments are skipped.
* Completion follows the audio output's playback position (Android:
  `AudioTrack.getPlaybackHeadPosition`; iOS: the `AVAudioPlayerNode`'s
  `dataPlayedBack` completion of the last buffer), not a timer.
* Only one utterance at a time, across all handles: `speak` while another
  utterance is active fails with `busy` (the active one continues).
* Audio: mono float PCM at the model's sample rate (44.1 kHz). Android plays
  it as `USAGE_MEDIA` / `CONTENT_TYPE_SPEECH` without requesting audio focus,
  so it mixes with other audio, like the system TTS through `flutter_tts`.
  iOS plays through an `AVAudioPlayerNode` on an `AVAudioEngine` in the app's
  `flutter_tts` setup: the `playback` category with `mixWithOthers`, in the
  `voicePrompt` mode, asserted and activated before every utterance (other
  audio in the app changes the shared session) and never deactivated, as
  `flutter_tts` leaves it.
* The audio output can end an utterance early. iOS: an audio session
  interruption (a call, Siri), a configuration change that stops the audio
  engine (a route or format change, e.g. AirPods connecting) and the
  playing device going away (headphones unplugged) end it with a `stopped`
  event carrying a `message`; `speak` returns `null`. While a call holds the
  session, `speak` ends the same way at once, without audio. A media services
  reset ends it with `error` (`speak_failed`). The engine rebuilds its audio
  graph on the next `speak`; it never resumes the cut-off utterance.
* A watchdog ends an utterance with `error` (`speak_failed`) if the audio
  written so far hasn't been reported as played a few seconds (iOS: 5) after
  it should have, so a lost completion can't leave the engine `busy`.

Errors: `bad_args` (unknown handle or voice, `steps` out of range, missing
arguments), `busy`, `speak_failed` (synthesis or playback failed after the
utterance started; an `error` event is sent too).

### `synthesize`

| argument | type | default |
|---|---|---|
| `handle`, `text`, `language`, `voiceId` | | (required) as for `speak` |
| `speed` | `double` | `1.0` |
| `steps` | `int` | `5` |
| `noiseSeed` | `int` | random |

Returns `{sampleRate: int, pcm: Float32List}`, mono float PCM, without
playing it. For tests, debugging and benchmarks. Runs on the same synthesis
thread as `speak`, so it waits for queued synthesis. `stop` doesn't affect
it.

With `noiseSeed`, the output is deterministic: the initial noise comes from
the PRNG below. Without it, the engine picks a random seed.

Errors: `bad_args`, `synthesis_failed`.

### `stop`

No arguments; returns `null` at once. Stops the active utterance: playback
stops and buffered audio is dropped immediately, and the ONNX Runtime run in
flight is terminated (`RunOptions.setTerminate`; ONNX Runtime's
Objective-C API on iOS has no equivalent, so there synthesis stops before
its next model run instead, and nothing more is played). The pending `speak` call
then completes normally (`null`), and a `stopped` event is sent. Without an
active utterance it does nothing.

### `unload`

`{handle}` → `null`. Stops the active utterance (whatever its handle),
waits for queued synthesis, then releases the sessions. Later calls with the
handle fail with `bad_args`. Unloading an unknown handle does nothing.

### `deviceMemory`

No arguments. Returns `{totalBytes: int, availableBytes: int?,
lowRamDevice: bool}`: Android's `ActivityManager.MemoryInfo.totalMem` and
`availMem`, and `ActivityManager.isLowRamDevice()`. iOS: `totalBytes` is
`ProcessInfo.physicalMemory`, `availableBytes` `os_proc_available_memory()`,
`lowRamDevice` false. Platforms without it answer "not implemented", and
Dart treats that as unknown (`null`). The app uses it to decide whether a
model loads at all (`DeviceMemory.isTooSmallForNeuralTts`).

## Events

Each event is a map:

| key | type | |
|---|---|---|
| `utteranceId` | `String` | from `speak` |
| `type` | `String` | `firstAudio`, `done`, `stopped` or `error` |
| `elapsedMs` | `int` | milliseconds since the native side received the `speak` call |
| `message` | `String?` | for `error`, and for `stopped` when the engine stopped the utterance itself |

Per utterance: at most one `firstAudio`, then exactly one of `done`,
`stopped` or `error`. `firstAudio` is sent once the first block of PCM has
been written to the audio output (for time-to-first-audio telemetry, #1508);
`done` when the last audio has played. The terminal event is sent just
before `speak` returns. Events of other utterances may interleave only
after it.

## Memory events

Android only: `on_device_tts/memory` sends `{level: int}` for the
`ComponentCallbacks2.onTrimMemory` levels that mean memory is short:
`TRIM_MEMORY_RUNNING_CRITICAL` (15) and `TRIM_MEMORY_BACKGROUND` (40) and up,
and 80 for `onLowMemory`. Not `TRIM_MEMORY_UI_HIDDEN` (20), which only means
the app went to the background: Flutter turns every level from
`TRIM_MEMORY_RUNNING_LOW` up, including that one, into
`didHaveMemoryPressure`, so Dart ignores `didHaveMemoryPressure` on Android
and listens here instead (`MemoryPressureMonitor`). The native side releases
nothing itself; Dart unloads (`NeuralTtsEngine.release`) and loads again on
the next `speak`. iOS sends nothing on this channel: Flutter's
`didHaveMemoryPressure` there is the real `didReceiveMemoryWarning`.

Reloading Supertonic 3 (fp32) after a release took 0.7 to 1.2 s on the
x86_64 emulator (first load 1.4 to 1.9 s), which delays the next message's
first audio by as much. Unloading it lowered the app's PSS by about 400 MB.

## Threads and power

* **Spinning.** ONNX Runtime's intra-op threads busy-wait for work by
  default. Chat arrives a message at a time, so every session sets
  `session.intra_op.allow_spinning=0`. On the x86_64 emulator (20 chat
  messages, Supertonic 3 fp32, 5 steps, `cpu`) spinning off vs on: 0.375 vs
  0.381 CPU-seconds per second of audio, real-time factor 0.19 vs 0.18; the
  cost of blocking is within noise.
* **Thread count.** `numThreads` defaults to 2. Same benchmark, 1 vs 2
  threads: 0.357 vs 0.375 CPU-s per audio-s (2 threads cost 5% more CPU),
  but real-time factor 0.35 vs 0.19 and median time to first audio 1.24 s vs
  0.66 s. A slow phone with 1 thread risks falling behind real time between
  clauses, which is a gap in the speech, so 2 stays the default.
* **Priorities (Android).** Models load and synthesize at
  `THREAD_PRIORITY_DEFAULT`. ONNX Runtime starts a session's intra-op
  threads on the thread that creates the session, and they inherit its
  priority, so loading at background priority would leave half of every
  inference at background priority. The playback thread runs at
  `THREAD_PRIORITY_AUDIO`.
* **Wake lock (Android).** A partial wake lock (`on_device_tts:speak`) is
  held while a model loads and from `speak` until its terminal event, with a
  10-minute timeout per hold; never between utterances. With the screen off
  the app's foreground service keeps the process alive but not the CPU
  awake, and the audio server's own wake lock only covers audio that is
  playing, not loading or synthesizing the first clause. Needs the
  `WAKE_LOCK` permission, which the plugin's manifest declares.
* **Audio (Android).** `USAGE_MEDIA` / `CONTENT_TYPE_SPEECH`, no audio
  focus. Playback in the background needs the app to run a foreground
  service of type `mediaPlayback` (the app's `TtsService`, with
  `FOREGROUND_SERVICE_MEDIA_PLAYBACK` on Android 14 and later); otherwise
  the cached-app freezer stops the process.

## Supertonic pipeline

Ported from Supertone's MIT reference code (the `supertonic` 1.3.1 Python
package and the Java sample in `supertone-oss-archive/supertonic`); keep
the MIT notice in ported files.

1. **Language.** The BCP-47 tag's primary subtag, lowercased (`pt-BR` →
   `pt`), if it is one of the 31 languages `en ko ja ar bg cs da de el es et
   fi fr hi hr hu id it lt lv nl pl pt ro ru sk sl sv tr uk vi`; otherwise
   `na`.
2. **Chunking.** Each segment (and `synthesize`'s text) is split like the
   Java sample's `chunkText`: paragraphs (blank lines), then sentences
   (after `.!?` plus whitespace, not after the sample's abbreviations),
   packed up to 300 UTF-16 units (120 for `ko` and `ja`); a sentence that is
   still too long is split on commas, then spaces. Chunks are synthesized in
   order, with 0.3 s of silence between chunks of the same text.
3. **Text normalization**, exactly as the Python package's
   `UnicodeProcessor._preprocess_text`: NFKD; remove the emoji ranges
   (U+1F600–1F64F, 1F300–1F5FF, 1F680–1F6FF, 1F700–1F77F, 1F780–1F7FF,
   1F800–1F8FF, 1F900–1F9FF, 1FA00–1FA6F, 1FA70–1FAFF, 2600–26FF,
   2700–27BF, 1F1E6–1F1FF); replace `– ‑ —` with `-`, `¯ _ [ ] | / # → ←`
   with a space, `“ ”` with `"`, `‘ ’ ´ \`` with `'`; delete `♥ ☆ ♡ © \`;
   replace `@` → ` at `, `e.g.,` → `for example, `, `i.e.,` → `that is, `;
   remove a space before `, . ! ? ; : '`; collapse repeated `"`, `'` or
   `` ` `` into one; collapse whitespace runs (Python's `str.isspace`
   characters) into one space and trim; append `.` unless the text ends with
   one of `.!?;:,'"')]}…。」』】〉》›»`; wrap as `<lang>text</lang>`.
   **Deviation:** the reference rejects text with characters the model
   doesn't know; we delete them instead (code points that are past the end
   of `unicode_indexer.json` or map to `-1`), right before the whitespace
   step. Whitespace is never deleted.
4. **Ids.** Each Unicode code point (not UTF-16 unit) of the result maps
   through `unicode_indexer.json`. `text_mask` is all ones, shape
   `[1, 1, n]`.
5. **Duration.** `duration_predictor(text_ids, style_dp, text_mask)` →
   seconds, divided by `speed`. `speed` is clamped to the reference's range
   [0.7, 2.0]; `steps` must be in [1, 100] (else `bad_args`).
6. **Text encoder.** `text_encoder(text_ids, style_ttl, text_mask)` →
   `text_emb`.
7. **Noise.** In float32, as the reference: `wav_len = trunc(duration *
   sample_rate)`, `latent_len = trunc((duration * sample_rate + C - 1) / C)`
   where `C = base_chunk_size * chunk_compress_factor` (3072), channels =
   `latent_dim * chunk_compress_factor` (144). Fill `[1, 144, latent_len]`
   from the PRNG, then zero the frames at or past
   `ceil(wav_len / C)` (`latent_mask`).
8. **Flow matching.** For `step` in `0 ..< steps`: `latent =
   vector_estimator(noisy_latent=latent, text_emb, style_ttl, latent_mask,
   text_mask, current_step=[step], total_step=[steps])`.
9. **Vocoder.** `vocoder(latent)` → `wav_tts`, truncated to
   `trunc(sample_rate * duration)` samples (float32 product), as the samples
   do.

Voice style JSON: `style_ttl` and `style_dp`, each `{dims, data}`, with
`data` a nested list flattened in row-major order into a float32 tensor of
shape `dims` (`[1, 50, 256]` and `[1, 8, 16]`).

## Noise PRNG

Deterministic, so Kotlin and Swift give the same noise for a seed:

```
state: UInt64 = seed               // the Dart int's 64 bits, two's complement

next_u64():                        // SplitMix64; all arithmetic mod 2^64
  state = state + 0x9E3779B97F4A7C15
  z = state
  z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9
  z = (z ^ (z >> 27)) * 0x94D049BB133111EB
  return z ^ (z >> 31)             // >> is a logical shift

next_double():                     // uniform in [0, 1)
  return Double(next_u64() >> 11) * 2^-53

next_gaussian():                   // Box–Muller, cosine branch only
  u1 = next_double()
  u2 = next_double()
  return Float(sqrt(-2 * ln(1 - u1)) * cos(2 * pi * u2))   // computed in Double
```

The latent `[1, channels, frames]` is filled in row-major order (all frames
of channel 0, then channel 1, ...), one `next_gaussian()` per element. Each
chunk of a text continues the same generator, in order.

Test vectors: seed 0 gives `next_u64()` = `0xE220A8397B1DCDAF`,
`0x6E789E6AA1B965F4`, `0x06C45D188009454F`. Seed 42 gives the gaussians
`0.88224888, -0.45084986, 0.18835263, 0.21958637, -0.67037147, -0.67652798`;
seed -1 gives `1.80689597, -0.62971526, 0.70706838`.

`cos`, `log` and `sqrt` may differ in the last bit between platforms' math
libraries; after rounding to float that is at most 1 ulp, far below the
parity tolerance.

## Parity testing

`tool/supertonic_reference.py` runs Supertone's own Python package with this
PRNG and writes every intermediate tensor (`text_ids`, `duration`,
`text_emb`, `noise`, `latent_<step>`, `wav`) and the trimmed PCM, with a
`manifest.json`. Platform tests compare against it:

* Android JVM: `SUPERTONIC_PARITY_DIR=<dir> ./gradlew
  :on_device_tts:testDebugUnitTest` from the app's `android/`
  (`ReferenceParityTest`, desktop ONNX Runtime).
* On a device: the app's `integration_test/on_device_tts_test.dart` with
  `ON_DEVICE_TTS_REFERENCE_DIR` (final PCM only).

Expected: fp32 output within 1e-3 max abs difference of the reference (bit
exact on the same ONNX Runtime CPU build). int8 models are only comparable
on the same CPU and build: ONNX Runtime's quantized kernels differ between
builds, and the differences grow through the flow-matching steps.
