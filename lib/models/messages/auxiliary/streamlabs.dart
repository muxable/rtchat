import 'package:rtchat/models/messages/message.dart';

class StreamlabsDonationEventModel extends MessageModel {
  final String name;
  final String formattedAmount;
  final String? message;
  final String currency;

  const StreamlabsDonationEventModel(
      {required this.name,
      required this.formattedAmount,
      required this.message,
      required this.currency,
      required super.messageId,
      required super.timestamp});

  static StreamlabsDonationEventModel fromDocumentData(
      String messageId, Map<String, dynamic> data) {
    return StreamlabsDonationEventModel(
        name: data['name'],
        formattedAmount: data['formattedAmount'],
        message: data['message'],
        currency: data['currency'],
        messageId: messageId,
        timestamp: data['timestamp'].toDate());
  }
}
