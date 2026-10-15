# on_device_tts

Text-to-speech that runs on the device, behind one `TtsEngine` interface:

* `SystemTtsEngine`: the platform's voices, through `flutter_tts`.
* `OnnxTts`: neural TTS models (Supertonic 3 today) run natively on the
  official [ONNX Runtime](https://onnxruntime.ai) (MIT), in Kotlin on
  Android and in Swift on iOS.
* `NeuralTtsEngine`: a `TtsEngine` that speaks with an installed voice pack
  on `OnnxTts`, splitting the text into clauses with `ClauseSplitter`.

The package doesn't import any app code, so it can move to its own
repository.

## OnnxTts

```dart
final tts = await OnnxTts.load(modelDir: '/path/to/supertonic-3');
final voices = await tts.voices(); // F1..F5, M1..M5
await tts.speak(['Hello chat,', 'thanks for the follow!'],
    language: 'en', voiceId: 'F1');
await tts.unload();
```

`modelDir` is a download of the Hugging Face repository
[`Supertone/supertonic-3`](https://huggingface.co/Supertone/supertonic-3)
(`onnx/` and `voice_styles/`). The weights are under the BigScience
OpenRAIL-M license; the reference code the pipeline was ported from is MIT.

`speak` streams: each segment is synthesized on a background thread while
the previous one plays. `doc/native_contract.md` is the platform contract
(channels, errors, events, the exact pipeline and the noise PRNG) that the
Android and iOS implementations share.

On Android the plugin depends on `com.microsoft.onnxruntime:onnxruntime-android`
(pinned in `android/build.gradle.kts`), which adds its native library to
every ABI. On iOS it depends on `onnxruntime-objc` 1.24.2 (CocoaPods) or
Microsoft's `onnxruntime-swift-package-manager` 1.24.2 (Swift Package
Manager), which need iOS 15.1; `doc/ios.md` describes the iOS side.

## NeuralTtsEngine

```dart
final engine = NeuralTtsEngine(installedPack, numThreads: 2, steps: 5);
await engine.load(); // optional: speak loads the model on first use
engine.events.listen(print); // firstAudio, done, stopped, error
await engine.speak('Muxfd said: hello chat, thanks for the raid!',
    language: 'en', rate: 0.5);
await engine.release(); // frees the model; the next speak loads it again
await engine.dispose();
```

The model stays loaded between utterances. `speak` splits the text into
clauses and passes them all to the native `speak`, which plays each clause
while it synthesizes the next, so the first audio waits for the first clause
only. Clauses break after `, ; : . ! ? …` followed by whitespace (never inside
`3.5`, `example.com` or `:)`), after CJK/Arabic/Devanagari clause punctuation
even without whitespace, but not after abbreviations or initials; fragments
under 6 letters join a neighbour, and over-long clauses (300 code units, 120
for Korean and Japanese) split at whitespace.

`rate` (0..1, 0.5 normal) maps to the native speed as `2 × rate` clamped to
0.7..2.0, the way `flutter_tts` maps it to Android's speech rate. `pitch` is
ignored: Supertonic has no pitch control.

## VoiceRouter

```dart
final router = VoiceRouter([kokoroEngine, supertonicEngine]); // preferred first
final route = await router.route('pt-BR'); // null: no engine speaks it
if (route == null) {
  await systemEngine.speak(text, language: 'pt-BR');
} else {
  final voice = route.voiceForKey('twitch:1234'); // same key, same voice
  await route.engine.speak(text, voice: voice, language: route.language);
}
```

`route` sends a language to the first engine with a voice for it, reading
each engine's languages from the locales of its `voices()`. Tags match with
`LanguageTag.matchScore`: a `pt` voice reads `pt-BR`, an `en-US` voice reads
`en`, and a `pt-PT` voice reads `pt-BR` when nothing closer exists, but a
`zh-Hans` voice never reads `zh-Hant` (or `zh-TW`). `voiceForKey` hashes the
key with `fnv1a32` (FNV-1a, 32-bit, over UTF-8), which unlike
`String.hashCode` is the same on every run and platform.

`SystemTtsEngine.speak` sets the platform's language when given one (falling
back to the primary language, then the default voice), unless a `voice` is
given.

## Tests

### Dart

```sh
flutter test   # in this directory
```

### Kotlin (JVM)

The plugin's unit tests (text normalization, chunking, the PRNG, JSON) run
through the app's Gradle project:

```sh
flutter build apk --config-only   # in the repository root, once
cd android && ./gradlew :on_device_tts:testDebugUnitTest
```

#### Parity with the reference implementation

`ReferenceParityTest` compares every intermediate tensor with Supertone's
own Python package. It is skipped unless `SUPERTONIC_PARITY_DIR` is set.
In a scratch directory outside the repository:

```sh
python3 -m venv venv && venv/bin/pip install supertonic==1.3.1
venv/bin/python -I <repo>/packages/on_device_tts/tool/supertonic_reference.py \
    <supertonic-3 download> <reference dir>
cd <repo>/android && SUPERTONIC_PARITY_DIR=<reference dir> \
    ./gradlew :on_device_tts:testDebugUnitTest --tests '*ReferenceParityTest*'
```

### Swift (iOS simulator)

The engine's Swift code is the `ios/on_device_tts/OnDeviceTtsCore` Swift package, with
XCTests that run real synthesis on the simulator, compare it with the
reference and exercise `speak` and `stop`. On a Mac, see `doc/ios.md`; CI
runs them in `.github/workflows/on-device-tts-ios.yml`.

### On a device

`integration_test/on_device_tts_test.dart` (in the app) loads a real model
and checks `load`, `voices`, `synthesize` and `speak`/`stop`. It skips
itself unless `ON_DEVICE_TTS_MODEL_DIR` is set, so the regular integration
run passes over it. On an Android emulator or phone:

```sh
# In the repository root. Install a debug build so run-as works.
flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk
packages/on_device_tts/tool/push_model.sh <supertonic-3 download>
flutter test integration_test/on_device_tts_test.dart --no-uninstall \
    --dart-define=ON_DEVICE_TTS_MODEL_DIR=/data/user/0/com.rtirl.chat/files/supertonic-3
```

`--no-uninstall` keeps the app, and the model in its files directory, for
the next run. To also compare the device's audio with the reference, push
the reference directory (`push_model.sh <reference dir> reference`) and add
`--dart-define=ON_DEVICE_TTS_REFERENCE_DIR=/data/user/0/com.rtirl.chat/files/reference`.

`integration_test/neural_tts_engine_test.dart` takes the same
`ON_DEVICE_TTS_MODEL_DIR` and reads chat through the app's `TtsModel` queue
with `NeuralTtsEngine`: order, `firstAudio` events, no overlap, `stop` and the
backlog cutoff. It prints time to first audio with and without clause
splitting as a `TTFA {...}` line.

`integration_test/on_device_tts_benchmark_test.dart` measures load time,
time to first audio, real-time factor and CPU time over 20 chat messages;
pass `--dart-define=PROVIDER=cpu|xnnpack|nnapi` and `THREADS=<n>`.
