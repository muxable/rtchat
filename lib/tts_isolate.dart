import 'dart:isolate';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

@pragma("vm:entry-point")
void isolateMain(SendPort sendPort) {
  // print("Hello from the isolate");
  sendPort.send("Isolate message");
}

void initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: (ServiceInstance service) {
        // Perform background tasks here...
        onStart(service);
      },
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: (ServiceInstance service) {
        // Send a message to the main isolate
        // Perform background tasks here...
        onStart(service);
      },
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
        // Fetch messages from Firestore
        // var messages = await fetchMessagesFromFirestore(channel);
        // Process messages as needed
      }
    });
  });
}

Future<List<dynamic>> fetchMessagesFromFirestore(String channelId) async {
  List<dynamic> messages = [];

  var collection = FirebaseFirestore.instance.collection('channels');
  var querySnapshot =
      await collection.where('channelId', isEqualTo: channelId).get();

  for (var doc in querySnapshot.docs) {
    var message = doc.data();
    messages.add(message);
  }
  return messages;
}
