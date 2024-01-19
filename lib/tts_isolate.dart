import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:rtchat/tts_plugin.dart';

@pragma("vm:entry-point")
void isolateMain(SendPort sendPort) {
  // print("Hello from the isolate");
  sendPort.send("Isolate message");
}

void initializeService() async {
  final service = FlutterBackgroundService();

  // this will be used as notification channel id
  const notificationChannelId = 'my_foreground';

// this will be used for notification id, So you can update your custom notification with this id.
  const notificationId = 888;

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId, // id
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        foregroundServiceNotificationId: notificationId),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );
  // Start the background service
  service.startService();
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

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
          android: AndroidInitializationSettings('notification_icon')),
      onDidReceiveBackgroundNotificationResponse: (payload) async {
    if (payload.actionId == "DISABLE_TTS") {
      TextToSpeechPlugin.stopSpeaking();
    }
  });

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  //bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
            888,
            'rtchat',
            'disableTTS',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                  'my_foreground', 'MY FOREGROUND SERVICE',
                  icon: 'notification_icon',
                  ongoing: true,
                  actions: <AndroidNotificationAction>[
                    AndroidNotificationAction(
                      "DISABLE_TTS",
                      'Action 1',
                      icon: DrawableResourceAndroidBitmap('voiceover'),
                      contextual: true,
                    ),
                  ]),
            ));
      }
    }
  });

  final prefs = await StreamingSharedPreferences.instance;
  prefs.getString('tts_channel', defaultValue: '{}').switchMap((channel) {
    if (channel.isNotEmpty && channel != "{}") {
      return FirebaseFirestore.instance
          .collection('channels')
          .where('channelId', isEqualTo: channel)
          .snapshots();
    } else {
      return const Stream.empty();
    }
  }).listen((snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        vocalizeMessage(change.doc.data());
      }
    }
  });

  // Handle other service events
  service.on('stopService').listen((event) {
    // print("Stopping this service right now");
    service.stopSelf();
  });

  service.on('startTts').listen((event) async {
    // print("Starting this service right now");
    await Isolate.spawn(isolateMain, ReceivePort().sendPort);
  });
}

void vocalizeMessage(Map<String, dynamic>? message) {
  if (message == null) {
    // print("Received a null message");
    return;
  }

  var textToSpeak = message['text'] as String?;

  if (textToSpeak != null) {
    try {
      TextToSpeechPlugin.speak(textToSpeak);
    } catch (e) {
      // print("Error during TTS processing: $e");
    }
  } else {
    // print("Received a message with null or missing 'text' field");
  }
}
