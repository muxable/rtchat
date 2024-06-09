import 'package:flutter/services.dart';

class VolumePlugin {
  static const MethodChannel _channel = MethodChannel('volume_channel');

  static Future<void> reduceVolumeOnTtsStart() async {
    await _channel.invokeMethod('tts_on');
  }

  static Future<void> increaseVolumeOnTtsStop() async {
    await _channel.invokeMethod('tts_off');
  }
}
