import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationsPlugin {
  static const MethodChannel _channel = MethodChannel('tts_notifications');

  static Future<void> showNotification() async {
    try {
      await _channel.invokeMethod('showNotification');
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static Future<void> cancelNotification() async {
    try {
      await _channel.invokeMethod('dismissNotification');
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
