import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:rtchat/tts_plugin.dart';

final ttsQueue = TTSQueue();
StreamSubscription? messagesSubscription;
StreamSubscription? channelSubscription;

@pragma("vm:entry-point")
void isolateMain(SendPort sendPort) {
  sendPort.send("Isolate message");
}

void initializeService() async {
  final service = FlutterBackgroundService();

  // this will be used as notification channel id
  const notificationChannelId = 'my_foreground';

  // this will be used for notification id, So you can update your custom notification with this id.
  const notificationId = 888;

  await service.configure(
    androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: false,
        notificationChannelId: notificationChannelId,
        foregroundServiceNotificationId: notificationId),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  channelSubscription = service.on("setTtsChannel").listen((event) async {
    if (event != null) {
      Map<String, dynamic>? args = event;
      if (args['channel'] == null) {
        await ttsQueue.clear();
        messagesSubscription?.cancel();
      } else {
        var channelData = args["channel"];
        var ttsCurrentChannel =
            "${channelData['provider']}:${channelData['channelId']}";
        messagesSubscription?.cancel();
        messagesSubscription = FirebaseFirestore.instance
            .collection('channels')
            .doc(ttsCurrentChannel)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots()
            .listen((latestMessage) async {
          if (latestMessage.docs.isNotEmpty) {
            final timestamp = latestMessage.docs[0]['timestamp'];
            final userId = latestMessage.docs[0]['author']["userId"];
            final uniqueId = '$timestamp-$userId';
            final textToSpeak = latestMessage.docs[0]['message'] as String?;
            if (textToSpeak != null) {
              await ttsQueue.speak(uniqueId, textToSpeak);
            }
          }
        });
      }
    }
  });

  /// you can see this log in logcat
  debugPrint('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

  // test using external plugin
  service.invoke(
    'update',
    {
      "current_date": DateTime.now().toIso8601String(),
    },
  );
}
