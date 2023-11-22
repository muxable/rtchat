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

  static Future<void> clear() async {
    try {
      await _channel.invokeMethod('clear');
    } catch (e) {
      // Handle the error
    }
  }
}

class TTSQueue {
  static const MethodChannel _channel = MethodChannel('tts_plugin');

  final List<Map<String, String>> _queue = [];

  Future<void> speak(String id, String text) async {
    // Add the speak request to the queue
    _queue.add({'id': id, 'text': text});

    // If no speak is in progress, start speaking
    if (_queue.length == 1) {
      await _speakNext();
    }
  }

  Future<void> _speakNext() async {
    if (_queue.isNotEmpty) {
      final speakRequest = _queue.first;
      final id = speakRequest['id'];
      final text = speakRequest['text'];

      try {
        await _channel.invokeMethod('speak', {'text': text});
      } catch (e) {
        // handle the error;
      }

      _queue.removeAt(0);
      await _speakNext();

      // remove this when we actually use the ID,
      // needed to prevent compile errors
      print(id);
    }
  }

  Future<void> delete(String id) async {
    _queue.removeWhere((speak) => speak['id'] == id);
  }

  void clear() {
    _queue.clear();
    _stopSpeaking();
  }

  Future<void> _stopSpeaking() async {
    try {
      await _channel.invokeMethod('stopSpeaking');
    } catch (e) {
      // handle the error;
    }
  }
}
