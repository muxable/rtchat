import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationsPlugin {
  static const MethodChannel _channel = MethodChannel('tts_notifications');

  static Future<void> showNotification() async {
    try {
      await _channel.invokeMethod('showNotification');
    } catch (e) {
      // Handle the error
      debugPrint("Error during notification processing");
    }
  }

  static Future<void> dismissNotification() async {
    try {
      await _channel.invokeMethod('dismissNotification');
    } catch (e) {
      // Handle the error
      debugPrint("Error during notification processing");
    }
  }
}
