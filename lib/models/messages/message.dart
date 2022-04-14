abstract class MessageModel {
  final DateTime timestamp;
  final String messageId;

  const MessageModel({required this.timestamp, required this.messageId});
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
      : super(messageId: "", timestamp: DateTime.now());
}
