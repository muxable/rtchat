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
  final Queue<({String id, String text, Completer<void> completer})> queue =
      Queue();
  bool isUsernameReadingEnabled = true;
  bool isTTSDisabled = false;

  bool get isEmpty => queue.isEmpty;

  int get length => queue.length;

  Future<void> speak(String id, String text) async {
    final completer = Completer<void>();
    final element = (id: id, text: text, completer: completer);

    // Logic to manage TTS and username reading based on queue size
    manageTTSState();

    if (isTTSDisabled) {
      if (queue.length == 1) {
        // Only read the TTS disabled message once
        await TextToSpeechPlugin.speak(
            "There are too many messages. TTS Disabled");
      }
      completer.complete();
    } else {
      if (queue.isNotEmpty) {
        final previous = queue.last;
        queue.addLast(element);
        await previous.completer.future;
        if (queue.firstOrNull != element) {
          throw Exception('Message was deleted');
        }
        final message = isUsernameReadingEnabled ? text : removeUsername(text);
        await TextToSpeechPlugin.speak(message);
        completer.complete();
      } else {
        queue.addLast(element);
        final message = isUsernameReadingEnabled ? text : removeUsername(text);
        await TextToSpeechPlugin.speak(message);
        completer.complete();
      }
    }

    queue.remove(element);
    manageTTSState(); // Re-check the state in case the queue is now empty
  }

  void delete(String id) {
    queue.removeWhere((speak) => speak.id == id);
    manageTTSState();
  }

  Future<void> clear() async {
    queue.clear();
    isUsernameReadingEnabled = true;
    isTTSDisabled = false;
    try {
      await TextToSpeechPlugin.stopSpeaking();
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

  void manageTTSState() {
    if (queue.length > 20) {
      isUsernameReadingEnabled = false;
      isTTSDisabled = true;
    } else if (queue.length > 10) {
      isUsernameReadingEnabled = false;
    } else if (queue.isEmpty) {
      isUsernameReadingEnabled = true;
      isTTSDisabled = false;
    }
  }

  String removeUsername(String text) {
    int usernameEndIndex = text.indexOf(':');
    return usernameEndIndex != -1
        ? text.substring(usernameEndIndex + 1).trim()
        : text;
  }
}
