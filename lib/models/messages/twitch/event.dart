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
}

class TwitchFollowEventModel extends MessageModel {
  final TwitchUserModel follower;

  const TwitchFollowEventModel({
    required this.follower,
    required String messageId,
    required bool pinned,
  }) : super(messageId: messageId, pinned: pinned);

  static TwitchFollowEventModel fromDocumentData(
      String messageId, Map<String, dynamic> data) {
    return TwitchFollowEventModel(
        follower: TwitchUserModel(
            userId: data['event']['user_id'],
            login: data['event']['user_login'],
            displayName: data['event']['user_name']),
        messageId: messageId,
        pinned: false);
  }
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
