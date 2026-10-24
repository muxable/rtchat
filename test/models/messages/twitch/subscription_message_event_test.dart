import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';

TwitchSubscriptionMessageEventModel subscription({
  required int durationMonths,
}) => TwitchSubscriptionMessageEventModel(
  timestamp: DateTime(2024),
  messageId: 'id',
  subscriberUserName: 'muxfd',
  tier: '1000',
  streakMonths: 0,
  cumulativeMonths: 12,
  durationMonths: durationMonths,
  emotes: const [],
  text: '',
);

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('single month subscriptions show cumulative months', () {
    expect(
      subscription(durationMonths: 1).localizedText(l10n),
      '<b>muxfd</b> has subscribed for 12 months at Tier 1!',
    );
  });

  test('multi-month subscriptions show the prepaid duration', () {
    expect(
      subscription(durationMonths: 6).localizedText(l10n),
      '<b>muxfd</b> has subscribed at Tier 1 for 6 months in advance, 12 months in total!',
    );
  });
}
