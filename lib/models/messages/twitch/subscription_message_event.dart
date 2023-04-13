import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/message.dart';

class SubscriptionMessageEventEmote {
  final String id;
  final int begin;
  final int end;

  const SubscriptionMessageEventEmote(
      {required this.id, required this.begin, required this.end});

  static List<SubscriptionMessageEventEmote> fromDynamicList(
      List<dynamic>? input) {
    if (input == null) {
      return [];
    }
    return input
        .map((e) => SubscriptionMessageEventEmote(
            id: e['id'] as String,
            begin: e['begin'] as int,
            end: e['end'] as int))
        .toList();
  }
}

class TwitchSubscriptionMessageEventModel extends MessageModel {
  final String subscriberUserName;
  final String tier;
  final int cumulativeMonths;
  final int durationMonths;
  final int streakMonths;
  final List<SubscriptionMessageEventEmote> emotes;
  final String text;

  const TwitchSubscriptionMessageEventModel(
      {required DateTime timestamp,
      required String messageId,
      required this.subscriberUserName,
      required this.tier,
      required this.cumulativeMonths,
      required this.durationMonths,
      required this.streakMonths,
      required this.emotes,
      required this.text})
      : super(messageId: messageId, timestamp: timestamp);

  String emotesToString() {
    return emotes.map((e) => '${e.id}:${e.begin}-${e.end}').join('/');
  }

  List<MessageToken> tokenize() {
    Iterable<MessageToken> tokens = rootEmoteTokenizer(text, emotesToString());
    tokens = tokenizeTags(tokens);
    return tokens.toList();
  }
}
