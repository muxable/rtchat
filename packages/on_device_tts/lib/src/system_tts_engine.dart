import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'tts_engine.dart';
import 'tts_voice.dart';

/// Speaks with the platform's own voices through `flutter_tts`.
///
/// On iOS speech plays in the playback audio category, mixed with other
/// audio, so it keeps going in the background and doesn't pause music.
class SystemTtsEngine implements TtsEngine {
  final FlutterTts _tts;
  final String? Function() _platformLanguage;

  // What the platform was last asked to speak with: a voice, else a
  // language, else (both null) its default voice.
  TtsVoice? _voice;
  String? _language;

  /// Creates an engine on [tts], or on a new [FlutterTts] when omitted.
  ///
  /// [platformLanguage] is the language to go back to after speaking in
  /// another one, on platforms where clearing the voice doesn't restore it:
  /// by default the device's language on iOS and macOS, and nothing
  /// elsewhere (Android's default voice carries its language).
  SystemTtsEngine({FlutterTts? tts, String? Function()? platformLanguage})
      : _tts = tts ?? FlutterTts(),
        _platformLanguage = platformLanguage ?? _devicePlatformLanguage {
    _tts
      ..setSharedInstance(true)
      ..setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
          IosTextToSpeechAudioMode.voicePrompt);
  }

  static String? _devicePlatformLanguage() => switch (defaultTargetPlatform) {
        TargetPlatform.iOS ||
        TargetPlatform.macOS =>
          PlatformDispatcher.instance.locale.toLanguageTag(),
        _ => null,
      };

  /// With a [voice], that voice speaks. Otherwise, with a [language], the
  /// platform's voice for that language speaks: the full tag if the
  /// platform has it, else its primary language (`pt` for `pt-BR`), else
  /// the default voice. Without either, the platform's default voice speaks.
  @override
  Future<void> speak(
    String text, {
    TtsVoice? voice,
    double rate = TtsEngine.normalRate,
    double pitch = TtsEngine.normalPitch,
    String? language,
  }) async {
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    if (voice != null) {
      if (voice != _voice) {
        await _tts.setVoice({'name': voice.id, 'locale': voice.locale});
        _voice = voice;
        _language = null;
      }
    } else if (language != null) {
      if (_voice != null || language != _language) {
        await _setLanguage(language);
        _voice = null;
        _language = language;
      }
    } else if (_voice != null || _language != null) {
      await _useDefaultVoice(restoreLanguage: _language != null);
      _voice = null;
      _language = null;
    }
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
  }

  Future<void> _setLanguage(String language) async {
    if (await _tts.setLanguage(language) == 1) return;
    final primary = language.replaceAll('_', '-').split('-').first;
    if (primary != language && await _tts.setLanguage(primary) == 1) return;
    await _useDefaultVoice(restoreLanguage: true);
  }

  Future<void> _useDefaultVoice({required bool restoreLanguage}) async {
    await _tts.clearVoice();
    final platformLanguage = restoreLanguage ? _platformLanguage() : null;
    if (platformLanguage != null) {
      await _tts.setLanguage(platformLanguage);
    }
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

  /// The platform's voices live outside the app: nothing to free.
  @override
  Future<void> release() async {}

  @override
  Future<void> dispose() async {
    await _tts.stop();
  }
}
