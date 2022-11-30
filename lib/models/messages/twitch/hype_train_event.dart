import 'package:rtchat/models/messages/message.dart';

class TwitchHypeTrainEventModel extends MessageModel {
  final int level;
  final int progress;
  final int goal;
  final int total;
  final bool isSuccessful;
  final bool hasEnded;
  final DateTime startTimestamp;
  final DateTime endTimestamp;

  const TwitchHypeTrainEventModel(
      {required DateTime timestamp,
      required String messageId,
      required this.level,
      required this.progress,
      required this.goal,
      required this.total,
      required this.startTimestamp,
      required this.endTimestamp,
      this.isSuccessful = false,
      this.hasEnded = false})
      : super(messageId: messageId, timestamp: timestamp);

  static TwitchHypeTrainEventModel fromDocumentData(Map<String, dynamic> data) {
    return TwitchHypeTrainEventModel(
        timestamp: data['timestamp'].toDate(),
        messageId: "channel.hype_train-${data['event']['id']}",
        level: data['event']['level'] ?? 1,
        progress: data['event']['progress'],
        goal: data['event']['goal'],
        total: data['event']['total'],
        startTimestamp: DateTime.parse(data['event']['started_at']),
        endTimestamp: DateTime.parse(data['event']['expires_at']));
  }

  TwitchHypeTrainEventModel withProgress(Map<String, dynamic> data) {
    final level = data['event']['level'];
    final total = data['event']['total'];

    if (this.level > level || this.total > total) {
      return this;
    }

    return fromDocumentData(data);
  }

  TwitchHypeTrainEventModel withEnd(Map<String, dynamic> data) {
    final level = data['event']['level'];
    final total = data['event']['total'];

    final wasSuccessful = level > 1;
    final previousLevel = level == 1 ? 1 : level - 1;
    final endLevel = progress >= goal ? level : previousLevel;

    return TwitchHypeTrainEventModel(
        timestamp: data['timestamp'].toDate(),
        messageId: messageId,
        level: endLevel,
        progress: progress,
        goal: goal,
        total: total,
        isSuccessful: wasSuccessful,
        hasEnded: true,
        startTimestamp: DateTime.parse(data['event']['started_at']),
        endTimestamp: DateTime.parse(data['event']['ended_at']));
  }

  @override
  bool operator ==(Object other) =>
      other is TwitchHypeTrainEventModel &&
      other.level == level &&
      other.progress == progress &&
      other.goal == goal &&
      other.total == total &&
      other.isSuccessful == isSuccessful &&
      other.hasEnded == hasEnded;

  @override
  int get hashCode => Object.hash(
      level, progress, goal.hashCode, total, isSuccessful, hasEnded);
}
