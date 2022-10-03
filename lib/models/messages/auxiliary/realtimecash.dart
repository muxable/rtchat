import 'package:flutter/material.dart';
import 'package:rtchat/models/messages/message.dart';

class SimpleRealtimeCashDonationEventModel extends MessageModel {
  final AssetImage image;
  final String currency;
  final double value;
  final String hash;
  final String? donor;
  final String? message;

  const SimpleRealtimeCashDonationEventModel(
      {required this.currency,
      required this.image,
      required this.value,
      required this.hash,
      required this.donor,
      required this.message,
      required String messageId,
      required DateTime timestamp})
      : super(messageId: messageId, timestamp: timestamp);

  static SimpleRealtimeCashDonationEventModel fromDocumentData(
      String messageId, Map<String, dynamic> data) {
    return SimpleRealtimeCashDonationEventModel(
        currency: data['activity']['asset'] ?? "UNKNOWN",
        value: double.parse(data['activity']['value'].toString()),
        hash: data['activity']['hash'],
        donor: data['donor'],
        message: data['message'],
        messageId: messageId,
        timestamp: data['timestamp'].toDate(),
        image:
            AssetImage("assets/${data['activity']['asset'] ?? "UNKNOWN"}.png"));
  }
}
