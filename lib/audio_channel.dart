import 'package:flutter/services.dart';

class AudioChannel {
  static const _channel = MethodChannel('com.rtirl.chat/audio');

  static set(List<String> urls) async {
    if (await hasPermission()) {
      await _channel.invokeMethod<bool>('set', {"urls": urls});
    }
  }

  static reload(String url) async {
    await _channel.invokeMethod<bool>('reload', {"url": url});
  }

  static Future<bool> requestPermission() async {
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  static Future<bool> hasPermission() async {
    return await _channel.invokeMethod<bool>('hasPermission') ?? false;
  }
}
