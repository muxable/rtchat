import 'dart:async';
import 'dart:collection';

import 'package:flutter/services.dart';

class TextToSpeechPlugin {
  static const MethodChannel channel = MethodChannel('tts_plugin');

  static Future<void> speak(String text) async {
    try {
      await channel.invokeMethod('speak', {'text': text});
    } catch (e) {
      // Handle the error
    }
  }

  static Future<Map<String, String>> getLanguages() async {
    try {
      final Map<dynamic, dynamic> languageMap =
          await channel.invokeMethod('getLanguages');
      return Map<String, String>.from(languageMap);
    } catch (e) {
      // Handle the error
      return <String, String>{};
    }
  }

  static Future<void> stopSpeaking() async {
    try {
      await channel.invokeMethod('stopSpeaking');
    } catch (e) {
      // Handle the error
    }
  }

  static Future<void> clear() async {
    try {
      await channel.invokeMethod('clear');
    } catch (e) {
      // Handle the error
    }
  }
}

class TTSQueue {
  final queue = Queue<({String id, String text, Completer<void> completer})>();

  bool get isEmpty => queue.isEmpty;

  int get length => queue.length;

  bool get readUserName => queue.length <= 10;

  Future<void> speak(String id, String text) async {
    final completer = Completer<void>();
    final element = (id: id, text: text, completer: completer);

    if (queue.isNotEmpty) {
      if (queue.length > 20) {
        // Disable TTS and read a specific message
        queue.clear();
        await TextToSpeechPlugin.speak(
            "There are too many messages. TTS Disabled");

        return;
      }

      final previous = queue.last;
      queue.addLast(element);
      await previous.completer.future;
      if (queue.firstOrNull != element) {
        throw Exception('Message was deleted');
      }
      await TextToSpeechPlugin.speak(text);
      completer.complete();
    } else {
      queue.addLast(element);
      await TextToSpeechPlugin.speak(text);
      completer.complete();
    }
    queue.remove(element);
  }

  void delete(String id) {
    queue.removeWhere((speak) => speak.id == id);
  }

  Future<void> clear() async {
    queue.clear();
    try {
      await TextToSpeechPlugin.stopSpeaking();
      await TextToSpeechPlugin.clear();
    } catch (e) {
      // handle the error;
    }
  }

  ({String id, String text})? peek() {
    final first = queue.firstOrNull;
    if (first != null) {
      return (id: first.id, text: first.text);
    }
    return null;
  }
}
