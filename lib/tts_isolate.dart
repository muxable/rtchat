import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

@pragma("vm:entry-point")
void isolateMain(SendPort sendPort) {
  print("Hello from the isolate");
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
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('startTts').listen((event) async {
    await Isolate.spawn(isolateMain, ReceivePort().sendPort);
  });

  service.on('initSharedPreference').listen((event) async {
    final prefs = await StreamingSharedPreferences.instance;
    // Listen to changes in 'tts_channel'
    prefs.getString('tts_channel', defaultValue: '{}').listen((pref) {
      // This block will be called every time 'tts_channel' changes
      debugPrint("tts_channel changed to: $pref");
    });
  });
}
