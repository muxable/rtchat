import 'package:flutter/services.dart';

class TextToSpeechPlugin {
  static const MethodChannel _channel = MethodChannel('tts_plugin');

  static Future<void> speak(String text) async {
    try {
      await _channel.invokeMethod('speak', {'text': text});
    } catch (e) {
      // Handle the error
    }
  }

  static Future<Map<String, String>> getLanguages() async {
    try {
      final Map<dynamic, dynamic> languageMap =
          await _channel.invokeMethod('getLanguages');
      return Map<String, String>.from(languageMap);
    } catch (e) {
      // Handle the error
      return <String, String>{};
    }
  }

  static Future<void> stopSpeaking() async {
    try {
      await _channel.invokeMethod('stopSpeaking');
    } catch (e) {
      // Handle the error
    }
  }
}

class TTSQueue {
  static const MethodChannel _channel = MethodChannel('tts_plugin');

  String? _queuedId;
  String? _queuedText;

  Future<void> speak(String id, String text) async {
    if (_queuedId == null) {
      _queuedId = id;
      _queuedText = text;

      try {
        await _channel.invokeMethod('speak', {'text': text});
      } catch (e) {
        // handle the error;
      }

      _queuedId = null;
      _queuedText = null;
    } else {
      _queuedId = id;
      _queuedText = text;
    }
  }
}
