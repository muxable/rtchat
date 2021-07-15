import 'dart:io';

import 'package:flutter/services.dart';

class ForegroundServiceChannel {
  static const _channel = MethodChannel('com.rtirl.chat/foreground_service');

  static start() {
    if (!Platform.isAndroid) {
      return;
    }
    _channel.invokeMethod<bool>('start');
  }

  static stop() {
    if (!Platform.isAndroid) {
      return;
    }
    _channel.invokeMethod<bool>('stop');
  }
}
