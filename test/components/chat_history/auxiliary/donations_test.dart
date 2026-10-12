import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/chat_history/auxiliary/realtimecash_donation.dart';
import 'package:rtchat/components/chat_history/auxiliary/streamelements.dart';
import 'package:rtchat/components/chat_history/auxiliary/streamlabs.dart';
import 'package:rtchat/models/messages/auxiliary/realtimecash.dart';
import 'package:rtchat/models/messages/auxiliary/streamelements.dart';
import 'package:rtchat/models/messages/auxiliary/streamlabs.dart';

import '../harness.dart';

void main() {
  final timestamp = DateTime(2024, 3, 14);

  group('StreamlabsDonationEventWidget', () {
    testWidgets('shows donor, amount and message', (tester) async {
      await pumpEvent(
          tester,
          buildEventWidget(StreamlabsDonationEventWidget(
              StreamlabsDonationEventModel(
                  name: 'muxfd',
                  formattedAmount: '\$5.00',
                  message: 'great stream',
                  currency: 'USD',
                  messageId: 'sl1',
                  timestamp: timestamp))));

      expect(
          findRichText('muxfd tipped \$5.00 on Streamlabs.'), findsOneWidget);
      expect(find.text('great stream'), findsOneWidget);
    });

    testWidgets('omits an empty message', (tester) async {
      await pumpEvent(
          tester,
          buildEventWidget(StreamlabsDonationEventWidget(
              StreamlabsDonationEventModel(
                  name: 'muxfd',
                  formattedAmount: '\$5.00',
                  message: '',
                  currency: 'USD',
                  messageId: 'sl2',
                  timestamp: timestamp))));

      expect(
          findRichText('muxfd tipped \$5.00 on Streamlabs.'), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });
  });

  group('StreamElementsTipEventWidget', () {
    testWidgets('shows donor, amount and message', (tester) async {
      await pumpEvent(
          tester,
          buildEventWidget(StreamElementsTipEventWidget(
              StreamElementsTipEventModel(
                  name: 'automux',
                  formattedAmount: '€3.00',
                  message: 'hello',
                  currency: 'EUR',
                  messageId: 'se1',
                  timestamp: timestamp))));

      expect(findRichText('automux tipped €3.00 on StreamElements.'),
          findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
    });
  });

  group('RealtimeCashDonationEventWidget', () {
    SimpleRealtimeCashDonationEventModel donation(
            {String? donor, String? message}) =>
        SimpleRealtimeCashDonationEventModel(
            currency: 'ETH',
            image: const AssetImage('assets/ETH.png'),
            value: 0.5,
            hash: '0xabc',
            donor: donor,
            message: message,
            messageId: 'rc1',
            timestamp: timestamp);

    testWidgets('names the donor when present', (tester) async {
      await pumpEvent(
          tester,
          buildEventWidget(RealtimeCashDonationEventWidget(
              donation(donor: 'muxfd', message: 'gm'))));

      expect(findRichText('muxfd tipped 0.5 ETH.'), findsOneWidget);
      expect(find.text('gm'), findsOneWidget);
    });

    testWidgets('falls back to anonymous without a donor', (tester) async {
      await pumpEvent(
          tester,
          buildEventWidget(
              RealtimeCashDonationEventWidget(donation(donor: ''))));

      expect(findRichText('Anonymous tipped 0.5 ETH.'), findsOneWidget);
    });
  });
}
