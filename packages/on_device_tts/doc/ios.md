# The ONNX Runtime engine on iOS

The Swift implementation of `native_contract.md`.

## Layout

- `ios/on_device_tts/`: the Flutter plugin (`OnDeviceTtsPlugin`), as a Swift
  package for Flutter's Swift Package Manager integration. It only maps
  channel calls to `OnnxTtsEngine`.
- `ios/OnDeviceTtsCore/`: the engine, as a Swift package without Flutter, so
  it can be built and tested on its own. The plugin package depends on it.
  - `OnnxTtsEngine.swift`: model handles, `speak` (pipelining and playback),
    `synthesize`, `stop`, events.
  - `AudioOutput.swift`: `AVAudioEngine` and `AVAudioPlayerNode`.
  - `Supertonic/`: the Supertonic 3 pipeline, ported from Supertone's MIT
    reference code (the notice is in each file).
  - `NoiseGenerator.swift`: the contract's noise PRNG.
  - `Tests/`: XCTests, including real synthesis.
  - `tool/make_parity_fixture.py`: makes the tests' small reference fixture
    with the official `supertonic` Python package.
- `ios/on_device_tts.podspec`: the same sources for CocoaPods.

ONNX Runtime is the official build (MIT), pinned to **1.24.2** in both the
podspec (`onnxruntime-objc`) and the Swift package (Microsoft's
`onnxruntime-swift-package-manager`, whose newest release is 1.24.2), so the
tests run the binary the app ships. It needs iOS 15.1; the app targets 15.5.

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
`TEST_RUNNER_SUPERTONIC_BENCHMARK=cpu` (or `coreml`, `xnnpack`) runs the
timing benchmark instead. CI runs all of this in
`.github/workflows/on-device-tts-ios.yml`.

## Platform details

- **Providers:** `cpu` (the default), `coreml` and `xnnpack`. `coreml` tries
  the ML Program format with `MLComputeUnits=ALL`, then the NeuralNetwork
  format, then `cpu`. On the simulator ML Program fails to compile these
  models (error -7), and NeuralNetwork runs about 25 % of the nodes on CPU,
  in 30 to 140 partitions per model; it was no faster than `cpu` there.
  Simulator numbers say nothing about the Neural Engine, so `coreml` still
  needs measuring on an iPhone.
- **Audio:** `done` comes from the `dataPlayedBack` completion of the last
  buffer. Synthesis runs at most two buffers ahead of playback. The engine
  is paused between utterances and restarted after a route change.
- **Stopping:** the Objective-C API has no `RunOptions` terminate, so
  synthesis checks for cancellation before every model run; a vector
  estimator step takes tens of milliseconds. Playback stops at once.
