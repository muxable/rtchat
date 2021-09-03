import 'dart:io';

import 'package:flutter/services.dart';

class AudioChannel {
  static const _channel = MethodChannel('com.rtirl.chat/audio');

  static add(String url) async {
    if (!Platform.isAndroid) {
      return;
    }
    if (await hasPermission()) {
      await _channel.invokeMethod<bool>('add', {"url": url});
    }
  }

  static remove(String url) async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<bool>('remove', {"url": url});
  }

  static reload(String url) async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<bool>('remove', {"url": url});
    await _channel.invokeMethod<bool>('add', {"url": url});
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
