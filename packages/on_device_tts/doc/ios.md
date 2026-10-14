# The ONNX Runtime engine on iOS

The iOS side of the `on_device_tts/onnx` method channel and the
`on_device_tts/onnx/events` event channel (see `native_contract.md`).

## Layout

- `ios/Classes/OnDeviceTtsPlugin.swift`: the Flutter plugin. It only maps
  channel calls to `OnnxTtsEngine`.
- `ios/OnDeviceTtsCore/`: everything else, as a Swift package with no
  Flutter dependency, so it can be tested on its own. The podspec compiles
  the same sources into the plugin.
  - `OnnxTtsEngine.swift`: model handles, `speak` (pipelining and playback),
    `synthesize`, `stop`, events.
  - `AudioOutput.swift`: `AVAudioEngine` and `AVAudioPlayerNode`.
  - `Supertonic/`: the Supertonic 3 pipeline, ported from Supertone's MIT
    reference code (the notice is in each file).
  - `NoiseGenerator.swift`: the cross-platform noise generator.
  - `Tests/`: XCTests, including real synthesis.
  - `tool/make_parity_fixture.py`: makes the reference fixture with the
    official `supertonic` Python package.

ONNX Runtime is the official build (MIT), pinned to **1.24.2** in both the
podspec (`onnxruntime-objc`) and `Package.swift` (Microsoft's
`onnxruntime-swift-package-manager`, whose newest release is 1.24.2), so the
tests run the same binary the app ships. It needs iOS 15.1; the app targets
15.5.

## Running the tests

On a Mac, with the model from
[Supertone/supertonic-3](https://huggingface.co/Supertone/supertonic-3)
(revision `3cadd1ee6394adea1bd021217a0e650ede09a323`) in `$MODEL_DIR`:

```sh
cd packages/on_device_tts/ios/OnDeviceTtsCore
TEST_RUNNER_SUPERTONIC_MODEL_DIR="$MODEL_DIR" xcodebuild test \
  -scheme OnDeviceTtsCore -destination 'platform=iOS Simulator,name=iPhone 16'
```

Without `SUPERTONIC_MODEL_DIR` the tests that need the model are skipped.
`TEST_RUNNER_SUPERTONIC_BENCHMARK=cpu,coreml,xnnpack` also runs the timing
benchmark. CI runs all of this in `.github/workflows/on-device-tts-ios.yml`.

## Behaviour

- **Providers:** `cpu` (the default), `coreml` and `xnnpack`. `coreml` tries
  the ML Program format with `MLComputeUnits=ALL`, then the NeuralNetwork
  format. `nnapi`, anything unknown, and a provider whose sessions fail to
  load fall back to `cpu` with a log line.
- **Audio:** an `AVAudioPlayerNode` on an `AVAudioEngine`, in the `playback`
  category with `mixWithOthers` and the `voicePrompt` mode, the same as
  `SystemTtsEngine`'s `flutter_tts` setup, so it plays in the background with
  the app's `audio` background mode. `done` comes from the player node's
  `dataPlayedBack` completion of the last buffer, not from a timer. An audio
  session interruption (a call, Siri) ends the current utterance with a
  `stopped` event; after a route change the engine is restarted. The engine
  is paused between utterances.
- **Pipelining:** segments are synthesized in order on a serial background
  queue. Each chunk's PCM is scheduled as soon as it is ready, so segment
  i + 1 is synthesized while segment i plays; synthesis waits when two
  buffers are already queued.
- **Stopping:** `stop()` stops the player at once and completes the pending
  `speak`. Synthesis checks for cancellation before every model run (the
  Objective-C API has no way to terminate a run), so the run in flight
  finishes in the background, but nothing more is played. `stop()` also
  cancels `synthesize` calls in flight, which fail with `cancelled`.
- **Errors:** `load_failed`, `busy`, `invalid_handle`, `invalid_args`,
  `speak_failed` (also sent as an `error` event), `synthesize_failed`,
  `cancelled`.
- **Language:** the primary subtag of the BCP-47 tag when Supertonic knows it
  (`pt-BR` → `pt`), otherwise `na`.
- **Text:** as the reference (`supertonic` 1.3.1), except that characters
  without an entry in `unicode_indexer.json` are dropped (after `@` has
  become ` at `), where the reference rejects the text, and that a sentence
  longer than the chunk limit (300 characters, 120 for `ko`) is split at
  commas, then spaces, instead of being kept whole. Chunks are joined with
  0.3 s of silence, and each chunk is trimmed to its predicted duration.
- **Model directory:** `tts.json`, `unicode_indexer.json` and the four
  `.onnx` files directly in `modelDir` or in `modelDir/onnx/` (the Hugging
  Face layout), and the voice styles in `modelDir/voice_styles/*.json`.
  Voice ids are the file names (`F1`); names are `Female 1`, `Male 1`, and
  so on.

## Noise generator

With `noiseSeed`, `synthesize` makes the flow-matching noise with this
generator, so the output is deterministic and matches the other platform:

1. State: the seed's 64-bit two's-complement bits. A zero seed becomes
   `0x9E3779B97F4A7C15`.
2. `nextUInt64`, xorshift64*: `x ^= x >> 12; x ^= x << 25; x ^= x >> 27;`
   store `x`, return `x * 0x2545F4914F6CDD1D` (mod 2^64).
3. `nextUniform`: `(nextUInt64() >> 11) * 2^-53`, a double in [0, 1).
4. `nextGaussian`: Box–Muller in doubles. `u1 = 1 - nextUniform()`,
   `u2 = nextUniform()`, `r = sqrt(-2 ln u1)`, `θ = 2π u2`; return `r cos θ`
   and keep `r sin θ` for the next call.
5. The latent `[1, latent_dim * chunk_compress_factor, latent_len]` is filled
   in row-major order, each value rounded to float32, then multiplied by the
   latent mask. One generator runs across all the chunks of a text.

Known values: seed 1 gives `nextUInt64` = 5180492295206395165, then
12380297144915551517; seed 42 gives `nextGaussian` = 0.18318703067772193,
then -0.8914613797411998.

Without `noiseSeed`, and in `speak`, the generator gets a random seed.
