import 'package:rtchat/models/twitch/user.dart';

abstract class MessageModel {
  final bool? pinned;
  final String messageId;

  const MessageModel({required this.pinned, required this.messageId});
}

class TwitchMessageModel extends MessageModel {
  final String channel;
  final TwitchUserModel author;
  final String message;
  final Map<String, dynamic> tags;
  final DateTime timestamp;
  final bool deleted;
  final String channelId;

  const TwitchMessageModel(
      {required String messageId,
      required this.channel,
      required this.author,
      required this.message,
      required this.tags,
      required this.timestamp,
      required this.deleted,
      required this.channelId})
      : super(messageId: messageId, pinned: null);

  bool get emoteOnly {
    return tags['emote-only'] == true;
  }

  bool get hasEmote {
    return tags['emotes'] != null ? true : false;
  }
}

class TwitchRaidEventModel extends MessageModel {
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

class StreamStateEventModel extends MessageModel {
  final bool isOnline;
  final DateTime timestamp;

  const StreamStateEventModel(
      {required String messageId,
      required this.isOnline,
      required this.timestamp})
      : super(messageId: messageId, pinned: null);
}
