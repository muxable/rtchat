import 'package:flutter/services.dart';

class TextToSpeechPlugin {
  static const MethodChannel _channel = MethodChannel('tts_plugin');

  static Future<void> speak(String text) async {
    try {
      await _channel.invokeMethod('speak', {'text': text});
    } catch (e) {
      // TODO Handle the error?
      // print('Error in TTSPlugin: $e');
    }
  }

  static Future<Map<String, String>> getLanguages() async {
    try {
      final Map<dynamic, dynamic> languageMap =
          await _channel.invokeMethod('getLanguages');
      // Convert the map from platform-specific types to Dart types
      return Map<String, String>.from(languageMap);
    } catch (e) {
      // Handle the error, e.g., log or throw an exception
      // print('Error in TextToSpeechPlugin.getLanguages: $e');
      return <String, String>{};
    }
  }
}
