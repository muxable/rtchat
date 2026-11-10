import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/chat_history/auxiliary/realtimecash_donation.dart';
import 'package:rtchat/components/chat_history/auxiliary/streamelements.dart';
import 'package:rtchat/components/chat_history/kick/events.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/auxiliary/realtimecash.dart';
import 'package:rtchat/models/messages/kick/event.dart';
import 'package:rtchat/models/messages/kick/user.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';
import 'package:styled_text/styled_text.dart';
import 'package:rtchat/components/chat_history/auxiliary/streamlabs.dart';
import 'package:rtchat/components/chat_history/twitch/channel_point_event.dart';
import 'package:rtchat/models/messages/auxiliary/streamelements.dart';
import 'package:rtchat/models/messages/auxiliary/streamlabs.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';

import 'harness.dart';

void main() {
  const donor = 'A < B & <b>literal</b>';
  const amount = r'$5 < 10';
  final timestamp = DateTime(2026);

  testWidgets('StreamElements donor and amount remain literal text', (
    tester,
  ) async {
    await pumpEvent(
      tester,
      buildEventWidget(
        StreamElementsTipEventWidget(
          StreamElementsTipEventModel(
            name: donor,
            formattedAmount: amount,
            message: null,
            currency: 'USD',
            messageId: 'se',
            timestamp: timestamp,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      findRichText('$donor tipped $amount on StreamElements.'),
      findsOneWidget,
    );
  });

  testWidgets('Streamlabs donor and amount remain literal text', (
    tester,
  ) async {
    await pumpEvent(
      tester,
      buildEventWidget(
        StreamlabsDonationEventWidget(
          StreamlabsDonationEventModel(
            name: donor,
            formattedAmount: amount,
            message: null,
            currency: 'USD',
            messageId: 'sl',
            timestamp: timestamp,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      findRichText('$donor tipped $amount on Streamlabs.'),
      findsOneWidget,
    );
  });

  testWidgets('reward names and redemption input cannot become markup', (
    tester,
  ) async {
    const reward = '<b>Drink water</b>';
    const input = 'I <3 this stream';
    await pumpEvent(
      tester,
      buildEventWidget(
        TwitchChannelPointRedemptionEventWidget(
          TwitchChannelPointRedemptionEventModel(
            timestamp: timestamp,
            messageId: 'reward',
            redeemerUsername: donor,
            status: TwitchChannelPointRedemptionStatus.fulfilled,
            rewardName: reward,
            rewardCost: 100,
            userInput: input,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      findRichText('$donor redeemed $reward for 100 points. $input'),
      findsOneWidget,
    );
  });
  testWidgets('RealtimeCash donor and currency cannot become markup', (
    tester,
  ) async {
    await pumpEvent(
      tester,
      buildEventWidget(
        RealtimeCashDonationEventWidget(
          SimpleRealtimeCashDonationEventModel(
            timestamp: timestamp,
            messageId: 'rc',
            hash: '0x1',
            donor: donor,
            value: 0.5,
            currency: '<MATIC>',
            message: null,
            image: const AssetImage('assets/MATIC.png'),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(findRichText('$donor tipped 0.5 <MATIC>.'), findsOneWidget);
  });

  testWidgets('Kick reward names and user input cannot become markup', (
    tester,
  ) async {
    const reward = '<b>Drink water</b>';
    const input = 'I <3 this stream';
    await pumpEvent(
      tester,
      buildEventWidget(
        KickRewardRedemptionEventWidget(
          KickRewardRedemptionEventModel(
            timestamp: timestamp,
            messageId: 'kick',
            redeemer: const KickUserModel(
              userId: '1',
              login: 'viewer',
              displayName: donor,
            ),
            rewardTitle: reward,
            cost: 100,
            userInput: input,
            status: 'fulfilled',
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      findRichText('$donor (viewer) redeemed $reward for 100 points. $input'),
      findsOneWidget,
    );
  });

  testWidgets('subscription markup escaping does not change spoken text', (
    tester,
  ) async {
    final model = TwitchSubscriptionMessageEventModel(
      timestamp: timestamp,
      messageId: 'sub',
      subscriberUserName: donor,
      tier: '1000',
      cumulativeMonths: 2,
      durationMonths: 1,
      streakMonths: 1,
      emotes: const [],
      text: '',
    );
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(model.localizedText(l10n), contains(donor));
    await pumpEvent(
      tester,
      buildEventWidget(
        StyledText(
          text: model.localizedText(l10n, escapeMarkup: true),
          tags: const {
            'b': StyledTextTag(style: TextStyle(fontWeight: FontWeight.bold)),
          },
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      findRichText('$donor has subscribed for 2 months at Tier 1!'),
      findsOneWidget,
    );
  });
}
