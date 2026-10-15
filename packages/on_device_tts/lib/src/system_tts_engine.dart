import 'package:flutter_tts/flutter_tts.dart';

import 'tts_engine.dart';
import 'tts_voice.dart';

/// Speaks with the platform's own voices through `flutter_tts`.
///
/// On iOS speech plays in the playback audio category, mixed with other
/// audio, so it keeps going in the background and doesn't pause music.
class SystemTtsEngine implements TtsEngine {
  final FlutterTts _tts;
  TtsVoice? _voice;

  /// Creates an engine on [tts], or on a new [FlutterTts] when omitted.
  SystemTtsEngine({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _tts
      ..setSharedInstance(true)
      ..setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
          IosTextToSpeechAudioMode.voicePrompt);
  }

  @override
  Future<void> speak(
    String text, {
    TtsVoice? voice,
    double rate = TtsEngine.normalRate,
    double pitch = TtsEngine.normalPitch,
  }) async {
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    if (voice != _voice) {
      if (voice != null) {
        await _tts.setVoice({'name': voice.id, 'locale': voice.locale});
      } else {
        await _tts.clearVoice();
      }
      _voice = voice;
    }
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  Future<List<TtsVoice>> voices({String? language}) async {
    final result = await _tts.getVoices;
    final voices = <TtsVoice>[];
    if (result is List) {
      for (final entry in result) {
        if (entry is! Map) continue;
        final name = entry['name'];
        final locale = entry['locale'];
        if (name is! String || locale is! String) continue;
        voices.add(TtsVoice(id: name, name: name, locale: locale));
      }
    }
    if (language == null) {
      return voices;
    }
    return voices.where((voice) => voice.speaks(language)).toList();
  }

  @override
  Future<void> dispose() async {
    await _tts.stop();
  }
}
