/// Text-to-speech engines that run on the device.
///
/// Every engine implements `TtsEngine`, so callers can queue, cut off and
/// fall back between engines without knowing how the audio is made:
///
/// * `SystemTtsEngine` speaks with the platform's voices through
///   `flutter_tts`.
///
/// `OnnxTts` runs neural TTS models (Supertonic 3) natively on ONNX Runtime;
/// see `doc/native_contract.md` for its platform channels.
///
/// This package doesn't depend on any app code, so it can move to its own
/// repository.
library;

export 'src/onnx/onnx_tts.dart';
export 'src/onnx/onnx_tts_platform.dart';
export 'src/system_tts_engine.dart';
export 'src/tts_engine.dart';
export 'src/tts_voice.dart';
