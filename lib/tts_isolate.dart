import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

@pragma("vm:entry-point")
void isolateMain(SendPort sendPort) {
  initializeService(sendPort);
}

void initializeService(SendPort sendPort) async {
  final service = FlutterBackgroundService();

  void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
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
    // Some code for background task
  }

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
