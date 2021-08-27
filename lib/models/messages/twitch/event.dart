import 'dart:math';

import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

class TwitchRaidEventModel extends MessageModel {
  final TwitchUserModel from;
  final int viewers;

  const TwitchRaidEventModel(
      {required DateTime timestamp,
      required String messageId,
      required this.from,
      required this.viewers})
      : super(messageId: messageId, timestamp: timestamp);
}

class TwitchFollowEventModel extends MessageModel {
  final TwitchUserModel follower;

  const TwitchFollowEventModel({
    required this.follower,
    required String messageId,
    required DateTime timestamp,
  }) : super(messageId: messageId, timestamp: timestamp);

  static TwitchFollowEventModel fromDocumentData(
      String messageId, Map<String, dynamic> data) {
    return TwitchFollowEventModel(
        follower: TwitchUserModel(
            userId: data['event']['user_id'],
            login: data['event']['user_login'],
            displayName: data['event']['user_name']),
        messageId: messageId,
        timestamp: data['timestamp'].toDate());
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
    required DateTime timestamp,
  }) : super(messageId: messageId, timestamp: timestamp);
}

class PollChoiceModel {
  final String id;
  final String title;
  final int bitVotes;
  final int channelPointVotes;
  final int votes;
  const PollChoiceModel({
    required this.id,
    required this.title,
    required this.bitVotes,
    required this.channelPointVotes,
    required this.votes,
  });
}

class TwitchPollEventModel extends MessageModel {
  final List<PollChoiceModel> choices;
  final String pollTitle;
  final bool isCompleted;

  TwitchPollEventModel({
    required this.choices,
    required this.pollTitle,
    required this.isCompleted,
    required String messageId,
    required DateTime timestamp,
  }) : super(messageId: messageId, timestamp: timestamp);

  static TwitchPollEventModel fromDocumentData(Map<String, dynamic>? data) {
    final m = TwitchPollEventModel(
        choices: parseChoices(data!),
        pollTitle: data['event']['title'],
        isCompleted: false,
        messageId: "poll${data['event']['id']}",
        timestamp: data['timestamp'].toDate());
    return m;
  }

  TwitchPollEventModel withProgress(Map<String, dynamic>? data) {
    return fromDocumentData(data);
  }

  TwitchPollEventModel withEnd(Map<String, dynamic>? data) {
    final m = TwitchPollEventModel(
        choices: parseChoices(data!),
        pollTitle: data['event']['title'],
        isCompleted: true,
        messageId: "poll${data['event']['id']}",
        timestamp: data['timestamp'].toDate());
    return m;
  }

  static List<PollChoiceModel> parseChoices(Map<String, dynamic>? data) {
    List<PollChoiceModel> lst = [];
    for (final entry in data!['event']['choices']) {
      final String id = entry['id'];
      final String title = entry['title'] ?? "Untitled";
      final int votes = entry['votes'] ?? 0;
      final int bitVotes = entry['bit_votes'] ?? 0;
      final int channelPointVotes = entry['channel_point_votes'] ?? 0;

      var poll = PollChoiceModel(
          id: id,
          title: title,
          bitVotes: bitVotes,
          channelPointVotes: channelPointVotes,
          votes: votes);
      lst.add(poll);
    }
    return lst;
  }

  int get totalVotes => choices.fold(0, (sum, choice) => sum + choice.votes);

  int get totalChannelPointsVotes =>
      choices.fold(0, (sum, choice) => sum + choice.channelPointVotes);

  int get totalBitVotes =>
      choices.fold(0, (sum, choice) => sum + choice.bitVotes);

  int get maxVotes => choices.map((e) => e.votes).reduce((a, b) => max(a, b));
}
