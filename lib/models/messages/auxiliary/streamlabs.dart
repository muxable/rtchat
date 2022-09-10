import 'package:rtchat/models/messages/message.dart';

class StreamlabsDonationEventModel extends MessageModel {
  final String name;
  final String amount;
  final String formattedAmount;
  final String? message;
  final String currency;

  const StreamlabsDonationEventModel(
      {required this.name,
      required this.amount,
      required this.formattedAmount,
      required this.message,
      required this.currency,
      required String messageId,
      required DateTime timestamp})
      : super(messageId: messageId, timestamp: timestamp);

  static StreamlabsDonationEventModel fromDocumentData(
      String messageId, Map<String, dynamic> data) {
    return StreamlabsDonationEventModel(
        name: data['event']['name'],
        amount: data['event']['amount'],
        formattedAmount: data['event']['formatted_amount'],
        message: data['event']['message'],
        currency: data['event']['currency'],
        messageId: messageId,
        timestamp: data['timestamp'].toDate());
  }
}
