import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

class RaidingEventConfig {
  bool showEvent;
  Duration eventDuration;

  RaidingEventConfig(this.showEvent, this.eventDuration);

  RaidingEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        eventDuration = Duration(seconds: json['eventDuration'].toInt());

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "eventDuration": eventDuration.inSeconds.toInt(),
      };
}

class TwitchRaidingEventModel extends MessageModel {
  // we don't populate viewer count because it's not accurate anyways.
  final Duration duration;
  final TwitchUserModel targetUser;
  final bool isComplete;
  final bool isSuccessful;

  const TwitchRaidingEventModel(
      {required DateTime timestamp,
      required String messageId,
      required this.duration,
      required this.targetUser,
      this.isComplete = false,
      this.isSuccessful = false})
      : super(messageId: messageId, timestamp: timestamp);

  static TwitchRaidingEventModel fromDocumentData(Map<String, dynamic> data) {
    return TwitchRaidingEventModel(
      timestamp: data['timestamp'].toDate(),
      messageId: "raiding.${data['raid']['id']}",
      duration:
          Duration(seconds: data['raid']['force_raid_now_seconds'].toInt()),
      targetUser: TwitchUserModel(
        userId: data['raid']['target_id'],
        displayName: data['raid']['target_display_name'],
        login: data['raid']['target_login'],
      ),
    );
  }

  TwitchRaidingEventModel withSuccessful() {
    return TwitchRaidingEventModel(
      timestamp: timestamp,
      messageId: messageId,
      duration: duration,
      targetUser: targetUser,
      isComplete: true,
      isSuccessful: true,
    );
  }

  TwitchRaidingEventModel withCancel() {
    return TwitchRaidingEventModel(
      timestamp: timestamp,
      messageId: messageId,
      duration: duration,
      targetUser: targetUser,
      isComplete: true,
      isSuccessful: false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TwitchRaidingEventModel &&
      other.duration == duration &&
      other.targetUser == targetUser &&
      other.isComplete == isComplete &&
      other.isSuccessful == isSuccessful;

  @override
  int get hashCode =>
      Object.hash(duration, targetUser, isComplete, isSuccessful);
}
