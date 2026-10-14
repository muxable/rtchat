import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/chat_history/youtube/events.dart';
import 'package:rtchat/components/chat_history/youtube/message.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/youtube/event.dart';
import 'package:rtchat/models/messages/youtube/message.dart';
import 'package:rtchat/models/messages/youtube/user.dart';

import '../harness.dart';

final t0 = DateTime(2026);
const viewer = YouTubeUserModel(
    userId: 'UCviewer',
    displayName: '@Viewer',
    isChatModerator: true,
    isChatSponsor: true,
    isVerified: true);

/// The accent color of the only decorated event on screen.
Color accentColor(WidgetTester tester) {
  final container = tester.widget<Container>(find
      .descendant(
          of: find.byType(DecoratedEventWidget),
          matching: find.byType(Container))
      .first);
  final border = (container.decoration as BoxDecoration).border as Border;
  return border.left.color;
}

void main() {
  testWidgets('renders youtube chat with author and badges', (tester) async {
    await pumpEvent(
        tester,
        buildEventWidget(YouTubeMessageWidget(YouTubeMessageModel(
            messageId: 'youtube:m',
            timestamp: t0,
            author: viewer,
            message: 'hello youtube :wave:',
            channelId: 'youtube:UCstreamer'))));
    expect(find.byIcon(Icons.build), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
    expect(find.byIcon(Icons.videocam), findsNothing);
    expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('@Viewer: hello youtube :wave:')),
        findsOneWidget);
  });

  testWidgets('dims deleted youtube chat', (tester) async {
    await pumpEvent(
        tester,
        buildEventWidget(YouTubeMessageWidget(YouTubeMessageModel(
            messageId: 'youtube:m',
            timestamp: t0,
            author: viewer,
            message: 'removed',
            deleted: true,
            channelId: 'youtube:UCstreamer'))));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.6);
  });

  testWidgets('renders super chats with their amount and tier color',
      (tester) async {
    await pumpEvent(
        tester,
        buildEventWidget(YouTubeSuperChatEventWidget(YouTubeSuperChatEventModel(
            messageId: 'youtube:sc',
            timestamp: t0,
            author: viewer,
            amountMicros: 5000000,
            currency: 'USD',
            amountDisplayString: '\$5.00',
            tier: 3,
            comment: 'great stream!'))));
    expect(findRichText('@Viewer sent a \$5.00 Super Chat!'), findsOneWidget);
    expect(find.text('great stream!'), findsOneWidget);
    expect(accentColor(tester), youTubeTierColor(3));
  });

  testWidgets('renders super stickers', (tester) async {
    await pumpEvent(
        tester,
        buildEventWidget(YouTubeSuperStickerEventWidget(
            YouTubeSuperStickerEventModel(
                messageId: 'youtube:ss',
                timestamp: t0,
                author: viewer,
                amountMicros: 20000000,
                currency: 'USD',
                amountDisplayString: '\$20.00',
                tier: 9,
                stickerId: 's',
                altText: 'Dancing cat'))));
    expect(
        findRichText('@Viewer sent a \$20.00 Super Sticker!'), findsOneWidget);
    expect(find.text('Dancing cat'), findsOneWidget);
    // tiers past the last color use the top color.
    expect(accentColor(tester), youTubeTierColors.last);
  });

  testWidgets('renders memberships', (tester) async {
    await pumpEvent(
        tester,
        buildEventWidget(Column(children: [
          YouTubeNewMemberEventWidget(YouTubeNewMemberEventModel(
              messageId: 'youtube:n',
              timestamp: t0,
              member: viewer,
              levelName: 'Super Fan',
              isUpgrade: false)),
          YouTubeNewMemberEventWidget(YouTubeNewMemberEventModel(
              messageId: 'youtube:u',
              timestamp: t0,
              member: viewer,
              levelName: 'Mega Fan',
              isUpgrade: true)),
          YouTubeMemberMilestoneEventWidget(YouTubeMemberMilestoneEventModel(
              messageId: 'youtube:ms',
              timestamp: t0,
              member: viewer,
              levelName: 'Super Fan',
              months: 6,
              comment: 'half a year!')),
          YouTubeMembershipGiftingEventWidget(
              YouTubeMembershipGiftingEventModel(
                  messageId: 'youtube:g1',
                  timestamp: t0,
                  gifter: viewer,
                  count: 1,
                  levelName: 'Super Fan')),
          YouTubeMembershipGiftingEventWidget(
              YouTubeMembershipGiftingEventModel(
                  messageId: 'youtube:g5',
                  timestamp: t0,
                  gifter: viewer,
                  count: 5,
                  levelName: 'Super Fan')),
          YouTubeGiftMembershipReceivedEventWidget(
              YouTubeGiftMembershipReceivedEventModel(
                  messageId: 'youtube:r',
                  timestamp: t0,
                  recipient: viewer,
                  levelName: 'Super Fan')),
        ])));
    expect(findRichText('@Viewer became a member!'), findsOneWidget);
    expect(findRichText('@Viewer upgraded to Mega Fan!'), findsOneWidget);
    expect(findRichText('@Viewer has been a member for 6 months!'),
        findsOneWidget);
    expect(find.text('half a year!'), findsOneWidget);
    expect(findRichText('@Viewer gifted a membership!'), findsOneWidget);
    expect(findRichText('@Viewer gifted 5 memberships!'), findsOneWidget);
    expect(
        findRichText('@Viewer received a gifted membership!'), findsOneWidget);
  });

  testWidgets('renders jewels gifts with their combo', (tester) async {
    await pumpEvent(
        tester,
        buildEventWidget(YouTubeGiftEventWidget(YouTubeGiftEventModel(
            messageId: 'youtube:gift',
            timestamp: t0,
            sender: viewer,
            giftName: 'Rose',
            jewels: 10,
            comboCount: 3))));
    expect(findRichText('@Viewer sent Rose (10 Jewels)! ×3'), findsOneWidget);
  });

  testWidgets('renders polls', (tester) async {
    await pumpEvent(
        tester,
        buildEventWidget(YouTubePollEventWidget(YouTubePollEventModel(
            messageId: 'youtube:p',
            timestamp: t0,
            author: viewer,
            question: 'Best snack?',
            options: const [
              YouTubePollOption(text: 'Chips', tally: 12),
              YouTubePollOption(text: 'Popcorn', tally: 30),
            ],
            isClosed: true))));
    expect(find.text('Best snack?'), findsOneWidget);
    expect(find.text('Chips'), findsOneWidget);
    expect(find.text('Popcorn'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
  });

  testWidgets('renders members-only mode and chat ended', (tester) async {
    await pumpEvent(
        tester,
        buildEventWidget(Column(children: [
          YouTubeMembersOnlyModeEventWidget(YouTubeMembersOnlyModeEventModel(
              messageId: 'youtube:on', timestamp: t0, isEnabled: true)),
          YouTubeMembersOnlyModeEventWidget(YouTubeMembersOnlyModeEventModel(
              messageId: 'youtube:off', timestamp: t0, isEnabled: false)),
          YouTubeChatEndedEventWidget(YouTubeChatEndedEventModel(
              messageId: 'youtube:e', timestamp: t0)),
        ])));
    expect(find.text('Members-only mode is on'), findsOneWidget);
    expect(find.text('Members-only mode is off'), findsOneWidget);
    expect(find.text('The live chat has ended'), findsOneWidget);
  });

  testWidgets('shows the youtube provider icon', (tester) async {
    await pumpEvent(
        tester, buildEventWidget(const ProviderIcon(Providers.youtube)));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(providerName(Providers.youtube), 'YouTube');
  });
}
