import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

class TwitchRaidEventModel extends MessageModel {
  final TwitchUserModel from;
  final int viewers;

  const TwitchRaidEventModel(
      {required bool pinned,
      required String messageId,
      required this.from,
      required this.viewers})
      : super(messageId: messageId, pinned: pinned);

  String get profilePictureUrl =>
      "https://us-central1-rtchat-47692.cloudfunctions.net/getProfilePicture?provider=twitch&channelId=${from.userId}";
}

class TwitchFollowEventModel extends MessageModel {
  final String followerName;

  const TwitchFollowEventModel({
    required this.followerName,
    required String messageId,
    required bool pinned,
  }) : super(messageId: messageId, pinned: pinned);
}

class TwitchCheerEventModel extends MessageModel {
  final int bits;
  final bool isAnonymous;
  final String cheerMessage;
  final String giverName;

  const TwitchCheerEventModel({
    required this.bits,
    required this.isAnonymous,
    required this.cheerMessage,
    required this.giverName,
    required String messageId,
    required bool pinned,
  }) : super(messageId: messageId, pinned: pinned);
}
