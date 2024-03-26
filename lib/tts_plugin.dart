import 'dart:async';
import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:rtchat/main.dart';
import 'package:rtchat/notifications_plugin.dart';

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

  static Future<void> disableTTS() async {
    try {
      await channel.invokeMethod('disableTTS');
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
      await disableTts();
      await TextToSpeechPlugin.stopSpeaking();
      await TextToSpeechPlugin.speak(
          "There are too many messages. Text to speech disabled");
      NotificationsPlugin.cancelNotification();
      return;
    }

    if (queue.isNotEmpty) {
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

  bool get readUserName => queue.length < 10;

  void delete(String id) {
    if (queue.isNotEmpty && queue.first.id != id) {
      queue.removeWhere((element) => element.id == id);
    }
  }

  Future<void> clear() async {
    await TextToSpeechPlugin.clear();
    queue.clear();
  }

  TTSQueueElement? peek() {
    return queue.isNotEmpty ? queue.first : null;
  }

  Future<void> disableTts() async {
    updateChannelSubscription("");
    TextToSpeechPlugin.disableTTS();
  }
}

class TTSQueueElement {
  final String id;
  final String text;
  final Completer<void> completer;

  TTSQueueElement(
      {required this.id, required this.text, required this.completer});
}
