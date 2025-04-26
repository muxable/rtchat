import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/messages/twitch/reply.dart';
import 'package:rtchat/tts_plugin.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

final DateTime ttsTimeStampListener = DateTime.now();
StreamSubscription? messagesSubscription;
StreamSubscription? channelSubscription;

Future<void> isolateMain(
    SendPort sendPort,
    StreamController<String> channelStream,
    StreamingSharedPreferences prefs,
    Locale currentLocale) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final localizations = await AppLocalizations.delegate.load(currentLocale);

  final ttsQueue = TTSQueue();

  final ttsModel = TtsModel.fromJson(
      jsonDecode(prefs.getString("tts", defaultValue: '{}').getValue()));

  // Listen for changes to the tts preferences and update the isolates ttsModel
  final ttsPrefs = prefs.getString('tts', defaultValue: '{}');
  ttsPrefs.listen((value) async {
    ttsModel.updateFromJson(jsonDecode(value));
    await TextToSpeechPlugin.updateTTSPreferences(
        ttsModel.pitch, ttsModel.speed);
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
        final docs = latestMessage.docs;
        if (docs.isNotEmpty) {
          final message = docs.first;
          final messageData = message.data();
          if (messageData.containsKey('type')) {
            final type = messageData['type'] as String?;
            switch (type) {
              case "message":
                if (ttsModel.mode == TtsMode.alertsOnly) {
                  return;
                }
                if (ttsModel.isSubscribersOnly &&
                    (messageData['tags']['subscriber'] == null ||
                        messageData['tags']['subscriber'] == '0')) {
                  return;
                }
                final messageModel = TwitchMessageModel(
                    messageId: message.id,
                    author: TwitchUserModel(
                      userId: messageData['tags']['user-id'],
                      login: messageData['author']['displayName'],
                    ),
                    message: messageData['message'],
                    reply: messageData['reply'] != null
                        ? TwitchMessageReplyModel(
                            messageId: messageData['reply']['messageId'],
                            message: messageData['reply']['message'],
                            author: TwitchUserModel(
                              userId: messageData['reply']['userId'],
                              displayName: messageData['reply']['displayName'],
                              login: messageData['reply']['userLogin'],
                            ),
                          )
                        : null,
                    tags: messageData['tags'],
                    annotations: TwitchMessageAnnotationsModel.fromMap(
                        messageData['annotations']),
                    thirdPartyEmotes: [],
                    timestamp: messageData['timestamp'].toDate(),
                    deleted: false,
                    channelId: messageData['channelId']);
                // Check if the message is from a bot and if bot messages should be muted
                if (ttsModel.isBotMuted && messageModel.author.isBot) {
                  return; // Skip vocalization for bot messages
                }
                final finalMessage = ttsModel.getVocalization(
                  localizations,
                  messageModel,
                  includeAuthorPrelude: !ttsModel.isPreludeMuted,
                );
                if (finalMessage.isNotEmpty) {
                  // Pass the speech rate and volume values to the TTS engine before vocalizing.
                  await ttsQueue.speak(message.id, finalMessage,
                      speed: ttsModel.speed * 1.2,
                      volume: ttsModel.pitch,
                      timestamp: messageModel.timestamp);
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
