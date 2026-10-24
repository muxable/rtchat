import 'package:flutter/services.dart';

class AudioChannel {
  static const _channel = MethodChannel('com.rtirl.chat/audio');

  /// Returns false if Android refused to start the audio service.
  static Future<bool> set(List<String> urls) async {
    // clearing doesn't need the overlay permission, and must still stop the
    // service if the permission was revoked while it ran.
    if (urls.isNotEmpty && !await hasPermission()) {
      return true;
    }
    return await _channel.invokeMethod<bool>('set', {"urls": urls}) ?? false;
  }

  /// Reloads every active source.
  static Future<void> reload() async {
    await _channel.invokeMethod<bool>('reload');
  }

  static Future<bool> requestPermission() async {
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  static Future<bool> hasPermission() async {
    return await _channel.invokeMethod<bool>('hasPermission') ?? false;
  }
}
