import 'dart:io';

import 'package:flutter/foundation.dart';

class AdHelper {
  static String get chatHistoryAdId {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
      throw UnsupportedError("Unsupported platform");
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-2604378007164700/7379157643';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2604378007164700/6776274993';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}

abstract class MessageModel {
  final DateTime timestamp;
  final String messageId;

  const MessageModel({required this.timestamp, required this.messageId});
}

var nativeMessageIdCounter = 0;

class AdMessageModel extends MessageModel {
  final String adId;

  AdMessageModel({required this.adId})
      : super(
            timestamp: DateTime.now(),
            messageId: 'ad-${nativeMessageIdCounter++}');
}

class StreamStateEventModel extends MessageModel {
  final bool isOnline;

  const StreamStateEventModel(
      {required String messageId,
      required this.isOnline,
      required DateTime timestamp})
      : super(messageId: messageId, timestamp: timestamp);
}

class SystemMessageModel extends MessageModel {
  final String text;

  SystemMessageModel({required this.text})
      : super(
            messageId: 'system-${nativeMessageIdCounter++}',
            timestamp: DateTime.now());
}

class ChatClearedEventModel extends MessageModel {
  ChatClearedEventModel(
      {required String messageId, required DateTime timestamp})
      : super(messageId: messageId, timestamp: timestamp);
}
