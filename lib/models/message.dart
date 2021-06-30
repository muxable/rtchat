class MessageModel {}

class PinnableMessageModel extends MessageModel {
  bool pinned;

  PinnableMessageModel({required this.pinned});
}

class TwitchMessageModel implements MessageModel {
  final String messageId;
  final String channel;
  final String author;
  final String message;
  final Map<String, dynamic> tags;
  final DateTime timestamp;
  final bool deleted;

  TwitchMessageModel(
      {required this.messageId,
      required this.channel,
      required this.author,
      required this.message,
      required this.tags,
      required this.timestamp,
      required this.deleted});
}

class TwitchRaidEventModel extends PinnableMessageModel {
  final String profilePictureUrl;
  final String fromUsername;
  final int viewers;

  TwitchRaidEventModel(
      {required this.profilePictureUrl,
      required this.fromUsername,
      required this.viewers,
      required bool pinned})
      : super(pinned: pinned);
}
