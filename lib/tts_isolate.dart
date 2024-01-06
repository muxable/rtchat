import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:rtchat/tts_plugin.dart';

@pragma("vm:entry-point")
void isolateMain(SendPort sendPort) {
  // print("Hello from the isolate");
  sendPort.send("Isolate message");
}

void initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
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

  // Initialize Firebase
  await Firebase.initializeApp();

  service.on('stopService').listen((event) {
    // print("Stopping this service right now");
    service.stopSelf();
  });

  service.on('startTts').listen((event) async {
    // print("Starting this service right now");
    await Isolate.spawn(isolateMain, ReceivePort().sendPort);
  });

  service.on('initSharedPreference').listen((event) async {
    final prefs = await StreamingSharedPreferences.instance;
    prefs.getString('tts_channel', defaultValue: '{}').listen((channel) async {
      debugPrint("tts_channel changed to: $channel");
      if (channel.isNotEmpty && channel != "{}") {
        listenForNewMessages(channel);
      }
    });
  });
}

void listenForNewMessages(String channelId) {
  // Listen to changes in Firestore and process messages
  FirebaseFirestore.instance
      .collection('channels')
      .where('channelId', isEqualTo: channelId)
      .snapshots()
      .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        // Process the added message and vocalize it
        var message = change.doc.data();
        vocalizeMessage(message);
      }
    }
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
