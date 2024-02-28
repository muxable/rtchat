import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import 'package:rtchat/tts_plugin.dart';

final DateTime ttsTimeStampListener = DateTime.now();
StreamSubscription? messagesSubscription;
StreamSubscription? channelSubscription;

@pragma("vm:entry-point")
void isolateMain(
    SendPort sendPort, StreamController<String> channelStream) async {
  // print("Hello from the isolate");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final ttsQueue = TTSQueue();

  initializeService();
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
          final textToSpeak = latestMessage.docs[0]['message'] as String?;
          if (textToSpeak != null) {
            await ttsQueue.speak(latestMessage.docs[0].id, textToSpeak);
          }
        }
      });
    }
  });
}

void initializeService() async {
  debugPrint('initializeService called');

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

  debugPrint('onStart called');

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) async {
      service.setAsForegroundService();
      // Setting up the notification at the very beginning
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Handle other service events
  service.on('stopTts').listen((event) {
    TextToSpeechPlugin.stopSpeaking();

    try {
      const platform = MethodChannel('tts_notifications');
      platform.invokeMethod('dismissNotification');
    } catch (e) {
      debugPrint("Error during notification processing: $e");
    }
  });

  service.on('startTts').listen((event) async {
    try {
      const platform = MethodChannel('tts_notifications');
      await platform.invokeMethod('showNotification');
    } on PlatformException catch (e) {
      debugPrint("Error during notification processing: $e");
    }
  });
}

Future<void> resetTTS() async {
  TextToSpeechPlugin.stopSpeaking();
  final prefs = await StreamingSharedPreferences.instance;
  prefs.setString('tts_channel', '{}');
}
