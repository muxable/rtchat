import 'package:flutter/material.dart';
import 'package:rtchat/models/messages/message.dart';

// this class is a simplified helper class to consolidate some code.
class DecoratedEventModel extends MessageModel {
  final String title;
  final String? subtitle;
  final AssetImage? avatar;

  const DecoratedEventModel(
      {required super.messageId,
      required super.timestamp,
      required this.title,
      this.subtitle,
      this.avatar});
}
