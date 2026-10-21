import 'package:flutter/services.dart';

class AppShare {
  static const MethodChannel _channel = MethodChannel('com.rtirl.chat/share');

  static Future<void> shareText(String text) async {
    await _channel.invokeMethod<bool>(
      'shareText',
      {'text': text},
    );
  }
}
