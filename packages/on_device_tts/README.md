# on_device_tts

Text-to-speech that runs on the device, behind one `TtsEngine` interface:

* `SystemTtsEngine`: the platform's voices, through `flutter_tts`.
* `OnnxTts`: neural TTS models (Supertonic 3 today) run natively on the
  official [ONNX Runtime](https://onnxruntime.ai) (MIT), in Kotlin on
  Android and in Swift on iOS.

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
every ABI. On iOS the app builds the plugin with CocoaPods only, so that
ONNX Runtime (`onnxruntime-objc` 1.24.2, which needs iOS 15.1) is linked
statically: through Flutter's Swift Package Manager integration it was
embedded as an `onnxruntime.framework` that App Store Connect rejects
(ITMS-90208). `doc/ios.md` describes the iOS side.

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
