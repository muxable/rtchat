abstract class MessageModel {
  final bool? pinned;
  final String messageId;

  const MessageModel({required this.pinned, required this.messageId});
}

class StreamStateEventModel extends MessageModel {
  final bool isOnline;
  final DateTime timestamp;

  const StreamStateEventModel(
      {required String messageId,
      required this.isOnline,
      required this.timestamp})
      : super(messageId: messageId, pinned: null);
}
