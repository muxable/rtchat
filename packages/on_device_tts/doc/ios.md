# The ONNX Runtime engine on iOS

The Swift implementation of `native_contract.md`.

## Layout

- `ios/on_device_tts/Sources/on_device_tts/`: the Flutter plugin class
  (`OnDeviceTtsPlugin`). It only maps channel calls to `OnnxTtsEngine`.
- `ios/on_device_tts/OnDeviceTtsCore/`: the engine, as a Swift package without
  Flutter, so it can be built and tested on its own.
  - `OnnxTtsEngine.swift`: model handles, `speak` (pipelining and playback),
    `synthesize`, `stop`, events.
  - `AudioOutput.swift`: `AVAudioEngine` and `AVAudioPlayerNode`.
  - `Supertonic/`: the Supertonic 3 pipeline, ported from Supertone's MIT
    reference code (the notice is in each file).
  - `NoiseGenerator.swift`: the contract's noise PRNG.
  - `Tests/`: XCTests, including real synthesis.
  - `tool/make_parity_fixture.py`: makes the tests' small reference fixture
    with the official `supertonic` Python package.
- `ios/on_device_tts.podspec`: how the app builds the plugin. It compiles the
  plugin class and the engine's sources into one module.

### Swift Package Manager and App Store packaging

The app uses `ios/on_device_tts/Package.swift` to compile the system speech
adapter, Flutter plugin and neural engine. The standalone `OnDeviceTtsCore`
package continues to run the engine tests without Flutter.

An earlier SPM build was rejected with ITMS-90208 because Xcode embedded an
`onnxruntime.framework` wrapper whose binary required iOS 15.5 but whose
copied `Info.plist` declared 15.1. The package's static product alone did not
prevent this wrapper from being embedded.

Runner's final build phase runs `ios/tool/validate_frameworks.py --repair-onnx`.
It reads the binary's deployment target with `vtool`, updates only ONNX
Runtime's plist to match, and re-signs that framework before Runner is signed.
It refuses binaries that require a newer OS than the app supports. The existing iOS build workflow runs this phase during archive creation.
The validator can also check a completed archive without `--repair-onnx`.
App Store acceptance still requires Apple's processing of a signed upload.

The podspec remains available for other apps using CocoaPods.

ONNX Runtime is the official build (MIT), pinned to **1.24.2** in both the
podspec (`onnxruntime-objc`) and the `OnDeviceTtsCore` Swift package
(Microsoft's `onnxruntime-swift-package-manager`, whose newest release is
1.24.2), so the tests run the same ONNX Runtime version the app ships. It needs iOS 15.1; the app targets 15.5.

## Running the tests

On a Mac, with the model from
[Supertone/supertonic-3](https://huggingface.co/Supertone/supertonic-3)
(revision `3cadd1ee6394adea1bd021217a0e650ede09a323`) in `$MODEL_DIR`:

```sh
cd packages/on_device_tts/ios/on_device_tts/OnDeviceTtsCore
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
- **Threads:** every session sets `session.intra_op.allow_spinning=0`
  (`SupertonicModel.sessionConfig`), for every provider, as on Android
  (#1531): chat comes a message at a time, and spinning intra-op threads
  burn the battery between runs. Sessions run sequentially, so there is no
  inter-op pool. Inference runs at `.userInitiated` QoS.
- **Audio:** `done` comes from the `dataPlayedBack` completion of the last
  buffer. Synthesis runs at most two buffers ahead of playback. The engine
  is paused between utterances.
- **Stopping:** the Objective-C API has no `RunOptions` terminate, so
  synthesis checks for cancellation before every model run; a vector
  estimator step takes tens of milliseconds. Playback stops at once.

## Audio robustness

`AudioOutput` owns an `AVAudioEngine` and an `AVAudioPlayerNode`;
`OnnxTtsEngine` turns what happens to them into the utterance's terminal
event. Whatever happens, the active utterance ends and the engine is no
longer `busy`:

| what happens | the active utterance | then |
|---|---|---|
| `AVAudioEngineConfigurationChange` with the engine stopped (route or format change, e.g. AirPods connecting) | `stopped`, "audio configuration changed" | a new engine and player node on the next `speak` |
| route change `.oldDeviceUnavailable` (headphones unplugged) | `stopped`, "audio device removed" (not carried on through the loudspeaker) | same |
| any other route change that left the engine stopped | as a configuration change | same |
| interruption `.began` (a call, Siri) | `stopped`, "audio session interrupted" | rebuilt on the next `speak`; nothing resumes on `.ended` |
| interruption `.began` with reason `.appWasSuspended` | nothing: a stale interruption delivered on resume | |
| `speak` while a call holds the session (`setActive` fails with `cannotInterruptOthers` / `insufficientPriority`, or between `.began` and `.ended`) | `stopped` at once, no audio, `speak` returns `null` | the next `speak` tries again; `.ended` isn't needed |
| `mediaServicesWereResetNotification` | `error`, `speak_failed` | the whole `AudioOutput` is dropped and a new one built on the next `speak` |
| `AVAudioPlayerNode.play()` with the engine stopped | never called: `play()` starts the engine first, every time a buffer is queued | if the engine can't start: `error`, `speak_failed` |
| no `dataPlayedBack` completion arrives | `error`, "audio playback stalled", 5 s (`watchdogMargin`) after the queued audio should have ended | |

A configuration change ends the utterance instead of rescheduling it,
because whether the buffers queued before the engine stopped still call back
is undocumented; stopping the player runs their completions, so nothing is
left waiting.

The configuration-change notification is ignored while the engine is still
running: the engine stops itself before posting it, so a running engine
means the change came before our own `start` (which sets the category and
activates the session) and was already taken into account.

### The shared audio session

There is one `AVAudioSession` per app, and three things set it:

- `flutter_tts` (`SystemTtsEngine`): `.playback` + `.mixWithOthers` in
  `.voicePrompt`, once, when the engine is made, and activates it. With
  `mixWithOthers` it never deactivates it (`shouldDeactivateAndNotifyOthers`
  is false), so the session stays active for good.
- audioplayers (`audioplayers_darwin` 6.5.0) applies `.playback` with no
  options when the plugin registers; `lib/main.dart` then sets the global
  context to `.ambient` (for the message ping, which respects the silent
  switch). `SpeakerKeepAlive` plays an inaudible clip every 5 minutes with
  `AudioContextConfig(focus: mixWithOthers)`, which on iOS replaces the
  *global* context with `.playback` + `.mixWithOthers` (iOS has no
  per-player context). Whenever no audioplayers player is playing any more
  (after each sound), it calls `setActive(false)` on the session, without
  `notifyOthersOnDeactivation`.
- this engine.

So the category the TTS needs can be replaced at startup and every 5
minutes, and the session can be deactivated under it. The engine therefore
asserts `.playback` + `.mixWithOthers` + `.voicePrompt` and calls
`setActive(true)` before every utterance (`AudioOutput.configureSharedSession`),
and never deactivates the session, like `flutter_tts`. A switch in the
middle of an utterance (only possible when that clip starts or ends
during it) ends it through the configuration-change path above at worst.
The app needs no change for this engine. `SystemTtsEngine` still only sets
its category once, so after `.ambient` the system voices follow the silent
switch; reasserting it before each `speak` there is a separate change.

### Background

The app has `UIBackgroundModes` `audio`. iOS keeps a background app running
only while it plays audio: once the engine pauses after an utterance, the
app may be suspended, and chat that arrives while it is suspended isn't
read until it runs again. `flutter_tts` behaves the same way: it keeps the
session active but `AVSpeechSynthesizer` stops producing audio between
utterances, and nothing else keeps the app alive. This engine matches it:
the session stays active between messages, the engine pauses (it doesn't
render silence), and there is no silent-audio keep-alive. Whether and how
soon iOS suspends the app with the screen locked between messages needs
measuring on an iPhone; if it does, keeping the engine running while TTS is
on and the app is in the background is the option to measure (battery
cost included), for both engines together.
