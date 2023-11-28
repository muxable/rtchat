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
  final MethodChannel _channel;

  TTSQueue(this._channel);

  final List<Map<String, String>> queue = [];

  bool get isEmpty => queue.isEmpty;

  int get length => queue.length;

  Future<void> speak(String id, String text) async {
    queue.add({'id': id, 'text': text});
  }

  Future<void> speakNext() async {
    if (queue.isNotEmpty) {
      final speakRequest = queue.first;
      final id = speakRequest['id'];
      final text = speakRequest['text'];

      try {
        await _channel.invokeMethod('speak', {'text': text});
      } catch (e) {
        // handle the error;
      }

      queue.removeAt(0);

      // remove this when we actually use the ID,
      // needed to prevent compile errors
      print(id);
    }
  }

  Future<void> delete(String id) async {
    queue.removeWhere((speak) => speak['id'] == id);
  }

  Future<void> clear() async {
    queue.clear();
    await _stopSpeaking();
  }

  Future<void> _stopSpeaking() async {
    try {
      await _channel.invokeMethod('stopSpeaking');
    } catch (e) {
      // handle the error;
    }
  }

  Map<String, String>? peek() {
    return queue.isNotEmpty ? queue.first : null;
  }
}
