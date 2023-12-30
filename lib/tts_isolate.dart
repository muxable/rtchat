import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';


@pragma("vm:entry-point")
void isolateMain(SendPort sendPort) {
  initializeService(sendPort);
}

void initializeService(SendPort sendPort) async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: (ServiceInstance service) {
        // Send a message to the main isolate
        sendPort.send("Background service started");

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
        sendPort.send("Background service started");

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

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('startTts').listen((event) async {
     await Isolate.spawn(
        isolateMain, ReceivePort().sendPort);
  });
}