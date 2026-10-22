import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/kick/events.dart';
import 'package:rtchat/components/chat_history/kick/message.dart';
import 'package:rtchat/models/messages/kick/event.dart';
import 'package:rtchat/models/messages/kick/message.dart';
import 'package:rtchat/models/messages/kick/user.dart';
import 'package:rtchat/models/user.dart';

import '../../../fakes/fake_user_model.dart';
import '../harness.dart';

final t0 = DateTime(2025);
const viewer = KickUserModel(
  userId: '1',
  login: 'viewer',
  displayName: 'Viewer',
  badges: [KickBadge(type: 'moderator', text: 'Moderator')],
);

void main() {
  testWidgets('renders kick chat with author and badges', (tester) async {
    await pumpEvent(
      tester,
      ChangeNotifierProvider<UserModel>.value(
        value: FakeUserModel(),
        child: buildEventWidget(
          KickMessageWidget(
            KickMessageModel(
              messageId: 'kick:m',
              timestamp: t0,
              author: viewer,
              message: 'hello kick',
              channelId: 'kick:1',
            ),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.shield), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().contains('Viewer: hello kick'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders kick subscriptions', (tester) async {
    await pumpEvent(
      tester,
      buildEventWidget(
        KickSubscriptionEventWidget(
          KickSubscriptionEventModel(
            messageId: 'kick:s',
            timestamp: t0,
            subscriber: viewer,
            months: 3,
            isRenewal: true,
          ),
        ),
      ),
    );
    expect(
      findRichText('Viewer has resubscribed for 3 months!'),
      findsOneWidget,
    );
  });

  testWidgets('renders anonymous gifts', (tester) async {
    await pumpEvent(
      tester,
      buildEventWidget(
        KickGiftedSubscriptionsEventWidget(
          KickGiftedSubscriptionsEventModel(
            messageId: 'kick:g',
            timestamp: t0,
            gifter: null,
            giftees: const [viewer, viewer],
          ),
        ),
      ),
    );
    expect(findRichText('Anonymous has gifted 2 subs!'), findsOneWidget);
  });

  testWidgets('renders kicks with their message', (tester) async {
    await pumpEvent(
      tester,
      buildEventWidget(
        KicksGiftedEventWidget(
          KicksGiftedEventModel(
            messageId: 'kick:k',
            timestamp: t0,
            sender: viewer,
            amount: 500,
            giftName: 'Rage Quit',
            message: 'gg',
          ),
        ),
      ),
    );
    expect(findRichText('Viewer sent 500 Kicks!'), findsOneWidget);
    expect(find.text('gg'), findsOneWidget);
  });

  testWidgets('renders follows and redemptions', (tester) async {
    await pumpEvent(
      tester,
      buildEventWidget(
        Column(
          children: [
            KickFollowEventWidget(
              KickFollowEventModel(
                messageId: 'kick:f',
                timestamp: t0,
                follower: viewer,
              ),
            ),
            KickRewardRedemptionEventWidget(
              KickRewardRedemptionEventModel(
                messageId: 'kick:r',
                timestamp: t0,
                redeemer: viewer,
                rewardTitle: 'Hydrate',
                cost: 100,
                status: 'accepted',
              ),
            ),
          ],
        ),
      ),
    );
    expect(findRichText('Viewer is following you'), findsOneWidget);
    expect(
      findRichText('Viewer redeemed Hydrate for 100 points.'),
      findsOneWidget,
    );
  });
}
