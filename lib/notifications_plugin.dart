import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/tts_plugin.dart';

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
      debugPrint("Listening to TTS");

      _channel.setMethodCallHandler((call) async {
        if (call.method == "disableTTs") {
          debugPrint("Disabling TTS");

          model.enabled = false;

          TextToSpeechPlugin.speak('Text to speech disabled');
        }
      });
    } catch (e) {
      debugPrint("Error listening to TTS : $e");
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
