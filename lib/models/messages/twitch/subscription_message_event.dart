import 'dart:convert';

import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/message.dart';

class SubscriptionMessageEventEmote {
  final String id;
  final int begin;
  final int end;

  const SubscriptionMessageEventEmote({
    required this.id,
    required this.begin,
    required this.end,
  });

  static List<SubscriptionMessageEventEmote> fromDynamicList(
    List<dynamic>? input,
  ) {
    if (input == null) {
      return [];
    }
    return input
        .map(
          (e) => SubscriptionMessageEventEmote(
            id: e['id'] as String,
            begin: e['begin'] as int,
            end: e['end'] as int,
          ),
        )
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

  const TwitchSubscriptionMessageEventModel({
    required super.timestamp,
    required super.messageId,
    required this.subscriberUserName,
    required this.tier,
    required this.cumulativeMonths,
    required this.durationMonths,
    required this.streakMonths,
    required this.emotes,
    required this.text,
  });

  /// The announcement text, which may contain `<b>` tags for the user name.
  String localizedText(AppLocalizations l10n, {bool escapeMarkup = false}) {
    final name =
        escapeMarkup
            ? htmlEscape.convert(subscriberUserName)
            : subscriberUserName;
    final tier = this.tier.replaceAll("000", "");
    if (durationMonths > 1) {
      return l10n.subscriptionMessageMultiMonthEvent(
        name,
        tier,
        durationMonths,
        cumulativeMonths,
      );
    }
    return l10n.subscriptionMessageEvent(name, cumulativeMonths, tier);
  }

  String emotesToString() {
    return emotes.map((e) => '${e.id}:${e.begin}-${e.end}').join('/');
  }

  List<MessageToken> tokenize() {
    Iterable<MessageToken> tokens = rootEmoteTokenizer(text, emotesToString());
    tokens = tokenizeTags(tokens);
    return tokens.toList();
  }
}
