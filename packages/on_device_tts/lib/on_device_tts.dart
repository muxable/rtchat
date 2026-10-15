/// Text-to-speech engines that run on the device.
///
/// Every engine implements `TtsEngine`, so callers can queue, cut off and
/// fall back between engines without knowing how the audio is made:
///
/// * `SystemTtsEngine` speaks with the platform's voices through
///   `flutter_tts`.
/// * `NeuralTtsEngine` speaks with an installed voice pack on `OnnxTts`,
///   which runs neural TTS models (Supertonic 3) natively on ONNX Runtime;
///   see `doc/native_contract.md` for its platform channels. It splits text
///   into clauses with `ClauseSplitter` to start playing sooner.
///
/// `VoiceRouter` picks which engine (e.g. which installed pack) reads text in
/// a language, matching tags with `LanguageTag`, and a stable voice per key
/// (such as a chatter) with `fnv1a32`.
///
/// Neural voices come in voice packs that are downloaded on demand:
/// `bundledVoicePacks` lists them and `VoicePackRepository` downloads,
/// verifies, installs and deletes them.
///
/// This package doesn't depend on any app code, so it can move to its own
/// repository.
library;

export 'src/clause_splitter.dart';
export 'src/language_tags.dart';
export 'src/neural_tts_engine.dart';
export 'src/onnx/onnx_tts.dart';
export 'src/onnx/onnx_tts_platform.dart';
export 'src/stable_hash.dart';
export 'src/system_tts_engine.dart';
export 'src/tts_engine.dart';
export 'src/tts_voice.dart';
export 'src/voice_router.dart';
export 'src/voice_packs/bundled_catalog.dart';
export 'src/voice_packs/installed_voice_pack.dart';
export 'src/voice_packs/voice_pack.dart';
export 'src/voice_packs/voice_pack_exceptions.dart';
export 'src/voice_packs/voice_pack_repository.dart';
