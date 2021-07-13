abstract class MessageModel {
  final bool pinned;
  final String messageId;

  const MessageModel({required this.pinned, required this.messageId});
}

abstract class PinnableMessageModel extends MessageModel {
  const PinnableMessageModel({required bool pinned, required String messageId})
      : super(pinned: pinned, messageId: messageId);
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

  bool get emoteOnly {
    return tags['emote-only'] == true;
  }

  bool get hasEmote {
    return tags['emotes'] != null ? true : false;
  }
}

class TwitchRaidEventModel extends PinnableMessageModel {
  final String profilePictureUrl;
  final String fromUsername;
  final int viewers;

  const TwitchRaidEventModel(
      {required bool pinned,
      required String messageId,
      required this.profilePictureUrl,
      required this.fromUsername,
      required this.viewers})
      : super(messageId: messageId, pinned: pinned);
}
