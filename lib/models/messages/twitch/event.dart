import 'dart:math';

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
    required bool pinned,
  }) : super(messageId: messageId, pinned: pinned);

  static TwitchPollEventModel fromDocumentData(Map<String, dynamic>? data) {
    final m = TwitchPollEventModel(
        choices: parseChoices(data!),
        pollTitle: data['event']['title'],
        isCompleted: false,
        messageId: "poll${data['event']['id']}",
        pinned: false);
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
        pinned: false);
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
