import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rtchat/tts_plugin.dart';

final DateTime ttsTimeStampListener = DateTime.now();
StreamSubscription? messagesSubscription;
StreamSubscription? channelSubscription;

@pragma("vm:entry-point")
Future<void> isolateMain(
    SendPort sendPort, StreamController<String> channelStream) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final ttsQueue = TTSQueue();

  // Listen for changes to the stream
  channelSubscription = channelStream.stream.listen((currentChannel) async {
    debugPrint("VALUE HERE $currentChannel");
    if (currentChannel.isEmpty) {
      await ttsQueue.clear();
      messagesSubscription?.cancel();
    } else {
      debugPrint("CURRENT TWITCH CHANNEL $currentChannel");
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
          final textToSpeak = latestMessage.docs[0]['message'] as String?;
          if (textToSpeak != null) {
            await ttsQueue.speak(latestMessage.docs[0].id, textToSpeak);
          }
        }
      });
    }
  });
}
