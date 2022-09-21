import 'package:rtchat/models/messages/message.dart';

class SimpleRealTimeCashDonationEventModel extends MessageModel {
  final String assetName;
  final double value;
  final String hash;

  const SimpleRealTimeCashDonationEventModel(
      {required this.assetName,
      required this.value,
      required this.hash,
      required String messageId,
      required DateTime timestamp})
      : super(messageId: messageId, timestamp: timestamp);

  static SimpleRealTimeCashDonationEventModel fromDocumentData(
      String messageId, Map<String, dynamic> data) {
    return SimpleRealTimeCashDonationEventModel(
        assetName: data['activity']['asset'] ?? "Unknown",
        value: data['activity']['value'],
        hash: data['activity']['hash'],
        messageId: messageId,
        timestamp: data['timestamp'].toDate());
  }
}
