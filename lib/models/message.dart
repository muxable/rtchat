abstract class MessageModel {
  final bool pinned;
  final String messageId;

  const MessageModel({required this.pinned, required this.messageId});
}

class TwitchMessageModel extends MessageModel {
  final String channel;
  final String author;
  final String message;
  final Map<String, dynamic> tags;
  final DateTime timestamp;
  final bool deleted;

  const TwitchMessageModel(
      {required bool pinned,
      required String messageId,
      required this.channel,
      required this.author,
      required this.message,
      required this.tags,
      required this.timestamp,
      required this.deleted})
      : super(messageId: messageId, pinned: pinned);
}

class TwitchRaidEventModel extends MessageModel {
  final String profilePictureUrl;
  final String fromUsername;
  final int viewers;

  TwitchRaidEventModel(
      {required bool pinned,
      required String messageId,
      required this.profilePictureUrl,
      required this.fromUsername,
      required this.viewers})
      : super(messageId: messageId, pinned: pinned);
}
