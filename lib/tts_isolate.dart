import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rtchat/tts_plugin.dart';

import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

final DateTime ttsTimeStampListener = DateTime.now();
StreamSubscription? messagesSubscription;
StreamSubscription? channelSubscription;

@pragma("vm:entry-point")
Future<void> isolateMain(
    SendPort sendPort,
    StreamController<String> channelStream,
    StreamingSharedPreferences prefs) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final ttsQueue = TTSQueue();

  // listen for changes to the tts preferences
  bool isPreludeMuted = false;
  final ttsPrefs = prefs.getString('tts', defaultValue: '{}');
  ttsPrefs.listen((value) {
    final Map<String, dynamic> ttsMap = jsonDecode(value);
    isPreludeMuted = ttsMap['isPreludeMuted'];
  });

  // Listen for changes to the stream
  channelSubscription = channelStream.stream.listen((currentChannel) async {
    if (currentChannel.isEmpty) {
      await ttsQueue.clear();
      messagesSubscription?.cancel();
    } else {
      messagesSubscription?.cancel();
      messagesSubscription = FirebaseFirestore.instance
          .collection('channels')
          .doc(currentChannel)
          .collection('messages')
          .where('timestamp', isGreaterThan: ttsTimeStampListener)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen((latestMessage) async {
        if (latestMessage.docs.isNotEmpty) {
          final message = latestMessage.docs[0];
          if (message.data().containsKey('type')) {
            final type = message['type'] as String?;
            switch (type) {
              case "message":
                final textToSpeak = message['message'] as String?;
                String finalMessage = '';
                if (textToSpeak != null) {
                  final userName = message['author']['displayName'] as String?;
                  finalMessage = isPreludeMuted
                      ? textToSpeak
                      : (userName != null
                          ? '$userName said $textToSpeak'
                          : textToSpeak);
                  await ttsQueue.speak(message.id, finalMessage);
                }
                break;
              case "stream.offline":
                await ttsQueue.clear();
                await ttsQueue.speak(message.id,
                    "Stream went offline, disabling text to speech");
                await ttsQueue.disableTts();
                messagesSubscription?.cancel();
                break;
            }
          }
        }
      });
    }
  });
}
