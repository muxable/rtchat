import 'dart:async';
import 'dart:collection';
import 'package:flutter/services.dart';

import 'package:rtchat/main.dart';

class TextToSpeechPlugin {
  static const MethodChannel channel = MethodChannel('ttsPlugin');

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
  final Queue<TTSQueueElement> queue = Queue<TTSQueueElement>();

  bool get isEmpty => queue.isEmpty;
  int get length => queue.length;

  Future<void> speak(String id, String text) async {
    final completer = Completer<void>();
    final element = TTSQueueElement(id: id, text: text, completer: completer);

    if (queue.length >= 20 && !readUserName) {
      queue.clear();
      await clear();
      updateChannelSubscription("");
      await TextToSpeechPlugin.speak(
          "There are too many messages. Text to speech disabled");
      return;
    }

    queue.addLast(element);

    if (queue.length == 1) {
      await _processQueue();
    }
  }

  bool get readUserName => queue.length < 10;

  Future<void> _processQueue() async {
    while (queue.isNotEmpty) {
      final element = queue.first;
      await TextToSpeechPlugin.speak(element.text);
      element.completer.complete();
      queue.removeFirst();
    }
  }

  void delete(String id) {
    queue.removeWhere((element) => element.id == id);
  }

  Future<void> clear() async {
    await TextToSpeechPlugin.clear();
    queue.clear();
  }

  TTSQueueElement? peek() {
    return queue.isNotEmpty ? queue.first : null;
  }
}

class TTSQueueElement {
  final String id;
  final String text;
  final Completer<void> completer;

  TTSQueueElement(
      {required this.id, required this.text, required this.completer});
}
