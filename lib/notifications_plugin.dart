import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rtchat/models/tts.dart';

class NotificationsPlugin {
  static const MethodChannel _channel = MethodChannel('tts_notifications');

  static Future<void> showNotification() async {
    try {
      await _channel.invokeMethod('showNotification');
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static Future<void> listenToTTs(TtsModel model) async {
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == "disableTTs") {
          model.enabled = false;
        }
      });
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
