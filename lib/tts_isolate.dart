import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:rtchat/tts_plugin.dart';

final ttsQueue = TTSQueue();
bool ttsEnabled = false;
StreamSubscription? ttsListenerSubscription;
String ttsCurrentChannel = '';

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
  // final prefs = await StreamingSharedPreferences.instance;

  // if (service is AndroidServiceInstance) {
  //   service.on('setAsForeground').listen((event) async {
  //     service.setAsForegroundService();
  //     // Setting up the notification at the very beginning
  //   });

  //   service.on('setAsBackground').listen((event) {
  //     service.setAsBackgroundService();
  //   });
  // }

  // Handle other service events
  service.on('stopTts').listen((event) async {
    await toggleTts(event);
    await ttsQueue.clear();
  });

  service.on('startTts').listen((event) async {
    await Isolate.spawn(isolateMain, ReceivePort().sendPort);
    await toggleTts(event);
    await setupTtsListener();
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

Future<void> toggleTts(event) async {
  if (event != null) {
    Map<String, dynamic>? args = event as Map<String, dynamic>?;
    ttsEnabled = args?['toggle'] ?? false;
    if (args?['channel'] != null) {
      var channelData = args!["channel"];
      ttsCurrentChannel =
          "${channelData['provider']}:${channelData['channelId']}";
    } else {
      ttsCurrentChannel = '';
    }
  }
}

Future<void> setupTtsListener() async {
  ttsListenerSubscription = FirebaseFirestore.instance
      .collection('channels')
      .doc(ttsCurrentChannel)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .listen((latestMessage) async {
    if (!ttsEnabled) {
      ttsListenerSubscription?.cancel();
      return;
    }
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

Future<void> resetTTS() async {
  TextToSpeechPlugin.stopSpeaking();
  final prefs = await StreamingSharedPreferences.instance;
  prefs.setString('tts_channel', '{}');
}

// void vocalizeMessage(Map<String, dynamic>? message) async {
//   StreamingSharedPreferences prefs = await StreamingSharedPreferences.instance;
//   if (message == null) {
//     // print("Received a null message");
//     return;
//   }

//   var textToSpeak = message['text'] as String?;

//   var isOnline = message['isOnline'] as bool? ?? false;

//   if (!isOnline) {
//     debugPrint("Received a message from an offline user");
//     TextToSpeechPlugin.stopSpeaking();
//     prefs.remove('tts_channel');
//   }
//   if (textToSpeak != null) {
//     try {
//       TextToSpeechPlugin.speak(textToSpeak);
//     } catch (e) {
//       debugPrint("Error during TTS processing: $e");
//     }
//   } else {
//     debugPrint("Received a message with null or missing 'text' field");
//   }
// }
