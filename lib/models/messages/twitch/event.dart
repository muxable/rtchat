import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'dart:math' as math;

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

class PollChoiceData {
  final String id;
  final String title;
  final int bitVotes;
  final int channelPointVotes;
  final int votes;
  final double percentage;
  const PollChoiceData(
      {required this.id,
      required this.title,
      required this.bitVotes,
      required this.channelPointVotes,
      required this.votes,
      required this.percentage});
}

class TwitchPollEventModel extends MessageModel {
  final List<dynamic> choices;
  final String pollTitle;
  final bool isCompleted;
  int totalVotes = 0;
  int totalChannelPointsVotes = 0;
  int totalBitVotes = 0;
  int maxVotes = 0;

  TwitchPollEventModel({
    required this.choices,
    required this.pollTitle,
    required this.isCompleted,
    required String messageId,
    required bool pinned,
  }) : super(messageId: messageId, pinned: pinned);

  static TwitchPollEventModel fromDocumentData(Map<String, dynamic>? data) {
    final m = TwitchPollEventModel(
        choices: data!['event']['choices'],
        pollTitle: data['event']['title'],
        isCompleted: false,
        messageId: "poll${data['event']['id']}",
        pinned: false);
    m.computeTotalVotes();
    return m;
  }

  TwitchPollEventModel withProgress(Map<String, dynamic>? data) {
    return fromDocumentData(data);
  }

  TwitchPollEventModel withEnd(Map<String, dynamic>? data) {
    final m = TwitchPollEventModel(
        choices: data!['event']['choices'],
        pollTitle: data['event']['title'],
        isCompleted: true,
        messageId: "poll${data['event']['id']}",
        pinned: false);
    m.computeTotalVotes();
    return m;
  }

  void computeTotalVotes() {
    for (final entry in choices) {
      final int votes = entry['votes'] ?? 0;
      final int bitVotes = entry['bit_votes'] ?? 0;
      final int channelPointVotes = entry['channel_point_votes'] ?? 0;
      totalVotes = totalVotes + votes;
      totalChannelPointsVotes += channelPointVotes;
      totalBitVotes += bitVotes;
      maxVotes = math.max(maxVotes, votes);
    }
  }
}
