import 'package:rtchat/models/message.dart';

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

class TwitchFollowEventModel extends MessageModel {
  final String followerName;

  const TwitchFollowEventModel({
    required this.followerName,
    required String messageId,
    required bool pinned,
  }) : super(messageId: messageId, pinned: pinned);
}
