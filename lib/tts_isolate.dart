import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
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

  final ttsModel = TtsModel.fromJson(
      jsonDecode(prefs.getString("tts", defaultValue: '{}').getValue()));

  // listen for changes to the tts preferences and update the isolates ttsModel
  final ttsPrefs = prefs.getString('tts', defaultValue: '{}');
  ttsPrefs.listen((value) async {
    ttsModel.updateFromJson(jsonDecode(value));
    await TextToSpeechPlugin.updateTTSPreferences(
        ttsModel.pitch, ttsModel.speed);
  });

  TwitchMessageModel createMessageModelFromData(
      String messageId, Map<String, dynamic> messageData, DateTime timestamp) {
    return TwitchMessageModel(
      messageId: messageId,
      author: TwitchUserModel(
        userId: messageData['tags']['user-id'],
        login: messageData['author']['displayName'],
      ),
      message: messageData['message'],
      tags: messageData['tags'],
      annotations: const TwitchMessageAnnotationsModel(
        isAction: false,
        isFirstTimeChatter: false,
        announcement: TwitchMessageAnnouncementModel(Colors.black),
      ),
      thirdPartyEmotes: [],
      timestamp: timestamp,
      deleted: false,
      channelId: messageData['channelId'],
    );
  }

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
        final docs = latestMessage.docs;
        if (docs.isNotEmpty) {
          final message = docs.first;
          final messageData = message.data();
          if (messageData.containsKey('type')) {
            final type = messageData['type'] as String?;
            switch (type) {
              case "message":
                final timestamp =
                    (messageData['timestamp'] as Timestamp?)?.toDate() ??
                        DateTime.now();
                final messageModel = createMessageModelFromData(
                    message.id, messageData, timestamp);
                final finalMessage = ttsModel.getVocalization(
                  messageModel,
                  includeAuthorPrelude: !ttsModel.isPreludeMuted,
                );
                if (finalMessage.isNotEmpty) {
                  await ttsQueue.speak(message.id, finalMessage);
                }
                break;
              case "stream.offline":
                await ttsQueue.clear();
                await ttsQueue.speak(
                  message.id,
                  "Stream went offline, disabling text to speech",
                );
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
