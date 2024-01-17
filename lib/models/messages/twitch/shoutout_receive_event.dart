import 'package:rtchat/models/messages/message.dart';

/*
    "broadcaster_user_id": "626262",
    "broadcaster_user_name": "SandySanderman",
    "broadcaster_user_login": "sandysanderman",
    "from_broadcaster_user_id": "12345",
    "from_broadcaster_user_name": "SimplySimple",
    "from_broadcaster_user_login": "simplysimple",
    "viewer_count": 860,
    "started_at": "2022-07-26T17:00:03.17106713Z"
*/

class TwitchShoutoutReceiveEventModel extends MessageModel {
  final String fromBroadcasterUserId;
  final String fromBroadcasterUserName;
  final int viewerCount;

  const TwitchShoutoutReceiveEventModel(
      {required super.timestamp,
      required super.messageId,
      required this.fromBroadcasterUserId,
      required this.fromBroadcasterUserName,
      required this.viewerCount});

  static TwitchShoutoutReceiveEventModel fromDocumentData(
      String messageId, Map<String, dynamic> data) {
    return TwitchShoutoutReceiveEventModel(
      fromBroadcasterUserId: data['event']['from_broadcaster_user_id'],
      fromBroadcasterUserName: data['event']['from_broadcaster_user_name'],
      viewerCount: data['event']['viewer_count'],
      timestamp: data['timestamp'].toDate(),
      messageId: messageId,
    );
  }
}
