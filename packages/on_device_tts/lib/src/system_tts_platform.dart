import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The portion of the system speech channel used by [SystemTtsEngine].
/// Native adapters derive from flutter_tts 4.2.5; see third_party/flutter_tts.
class SystemTtsPlatform {
  static const _channel = MethodChannel('on_device_tts/system');

  Future<void> configureAudioSession() async {
    await _channel.invokeMethod<void>('setSharedInstance', true);
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await _channel.invokeMethod<void>('setIosAudioCategory', {
      'iosAudioCategoryKey': 'iosAudioCategoryPlayback',
      'iosAudioCategoryOptionsKey': ['iosAudioCategoryOptionsMixWithOthers'],
      'iosAudioModeKey': 'iosAudioModeVoicePrompt',
    });
  }

  Future<Object?> setSpeechRate(double rate) =>
      _channel.invokeMethod('setSpeechRate', rate);
  Future<Object?> setPitch(double pitch) =>
      _channel.invokeMethod('setPitch', pitch);
  Future<Object?> setVoice(Map<String, String> voice) =>
      _channel.invokeMethod('setVoice', voice);
  Future<Object?> clearVoice() => _channel.invokeMethod('clearVoice');
  Future<Object?> setLanguage(String language) =>
      _channel.invokeMethod('setLanguage', language);
  Future<Object?> awaitSpeakCompletion(bool value) =>
      _channel.invokeMethod('awaitSpeakCompletion', value);
  Future<Object?> awaitSynthCompletion(bool value) =>
      _channel.invokeMethod('awaitSynthCompletion', value);
  Future<Object?> speak(String text) => _channel.invokeMethod(
    'speak',
    defaultTargetPlatform == TargetPlatform.android
        ? {'text': text, 'focus': false}
        : text,
  );
  Future<Object?> synthesizeToFile(
    String text,
    String fileName,
    bool isFullPath,
  ) => _channel.invokeMethod('synthesizeToFile', {
    'text': text,
    'fileName': fileName,
    'isFullPath': isFullPath,
  });
  Future<Object?> stop() => _channel.invokeMethod('stop');
  Future<Object?> get getVoices => _channel.invokeMethod('getVoices');
}
