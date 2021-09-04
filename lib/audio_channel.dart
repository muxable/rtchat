import 'dart:io';

import 'package:flutter/services.dart';

class AudioChannel {
  static const _channel = MethodChannel('com.rtirl.chat/audio');

  static set(List<String> urls) async {
    if (!Platform.isAndroid) {
      return;
    }
    print("set urls $urls");
    if (await hasPermission()) {
      await _channel.invokeMethod<bool>('set', {"urls": urls});
    }
  }

  static reload(String url) async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<bool>('reload', {"url": url});
  }

  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) {
      return false;
    }
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  static Future<bool> hasPermission() async {
    if (!Platform.isAndroid) {
      return false;
    }
    return await _channel.invokeMethod<bool>('hasPermission') ?? false;
  }
}
