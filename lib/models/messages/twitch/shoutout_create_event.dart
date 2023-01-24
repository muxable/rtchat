import 'package:rtchat/models/messages/message.dart';

/*
    "broadcaster_user_id": "12345",
    "broadcaster_user_name": "SimplySimple",
    "broadcaster_user_login": "simplysimple",
    "moderator_user_id": "98765",
    "moderator_user_name": "ParticularlyParticular123",
    "moderator_user_login": "particularlyparticular123",
    "to_broadcaster_user_id": "626262",
    "to_broadcaster_user_name": "SandySanderman",
    "to_broadcaster_user_login": "sandysanderman",
    "started_at": "2022-07-26T17:00:03.17106713Z",
    "viewer_count": 860,
    "cooldown_ends_at": "2022-07-26T17:02:03.17106713Z",
    "target_cooldown_ends_at":"2022-07-26T18:00:03.17106713Z"
*/

class TwitchShoutoutCreateEventModel extends MessageModel {
  final String fromBroadcasterUserId;
  final String fromBroadcasterUserName;
  final String toBroadcasterUserId;
  final String toBroadcasterUserName;
  final int viewerCount;

  const TwitchShoutoutCreateEventModel(
      {required DateTime timestamp,
      required String messageId,
      required this.fromBroadcasterUserId,
      required this.fromBroadcasterUserName,
      required this.toBroadcasterUserId,
      required this.toBroadcasterUserName,
      required this.viewerCount})
      : super(messageId: messageId, timestamp: timestamp);

  static TwitchShoutoutCreateEventModel fromDocumentData(
      String messageId, Map<String, dynamic> data) {
    return TwitchShoutoutCreateEventModel(
      fromBroadcasterUserId: data['event']['from_broadcaster_user_id'],
      fromBroadcasterUserName: data['event']['from_broadcaster_user_name'],
      toBroadcasterUserId: data['event']['to_broadcaster_user_id'],
      toBroadcasterUserName: data['event']['to_broadcaster_user_name'],
      viewerCount: data['event']['viewer_count'],
      timestamp: data['timestamp'].toDate(),
      messageId: messageId,
    );
  }
}
