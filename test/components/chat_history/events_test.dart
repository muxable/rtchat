import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/chat_history/chat_cleared_event.dart';
import 'package:rtchat/components/chat_history/stream_state_event.dart';
import 'package:rtchat/components/chat_history/twitch/hype_train_event.dart';
import 'package:rtchat/components/chat_history/twitch/poll_event.dart';
import 'package:rtchat/components/chat_history/twitch/shoutout_event.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_create_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_receive_event.dart';

import 'harness.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final timestamp = DateTime(2024, 3, 14, 15, 9, 26);

  group('ChatClearedEventWidget', () {
    testWidgets('shows when chat was cleared', (tester) async {
      await pumpEvent(
        tester,
        buildEventWidget(
          ChatClearedEventWidget(
            ChatClearedEventModel(messageId: 'clear', timestamp: timestamp),
          ),
        ),
      );

      expect(find.text(l10n.chatCleared(timestamp, timestamp)), findsOneWidget);
      expect(find.textContaining('Chat cleared at'), findsOneWidget);
    });
  });

  group('StreamStateEventWidget', () {
    testWidgets('shows stream online', (tester) async {
      await pumpEvent(
        tester,
        buildEventWidget(
          StreamStateEventWidget(
            StreamStateEventModel(
              messageId: 'online',
              isOnline: true,
              timestamp: timestamp,
            ),
          ),
        ),
      );

      expect(
        find.text(l10n.streamOnline(timestamp, timestamp)),
        findsOneWidget,
      );
      expect(find.textContaining('Stream online at'), findsOneWidget);
    });

    testWidgets('shows stream offline', (tester) async {
      await pumpEvent(
        tester,
        buildEventWidget(
          StreamStateEventWidget(
            StreamStateEventModel(
              messageId: 'offline',
              isOnline: false,
              timestamp: timestamp,
            ),
          ),
        ),
      );

      expect(
        find.text(l10n.streamOffline(timestamp, timestamp)),
        findsOneWidget,
      );
      expect(find.textContaining('Stream offline at'), findsOneWidget);
    });
  });

  group('TwitchPollEventWidget', () {
    TwitchPollEventModel poll({required bool isCompleted}) =>
        TwitchPollEventModel(
          choices: const [
            PollChoiceModel(
              id: '1',
              title: 'Cats',
              bitVotes: 0,
              channelPointVotes: 0,
              votes: 3,
            ),
            PollChoiceModel(
              id: '2',
              title: 'Dogs',
              bitVotes: 0,
              channelPointVotes: 0,
              votes: 1,
            ),
          ],
          pollTitle: 'Best pet?',
          isCompleted: isCompleted,
          startTimestamp: timestamp,
          endTimestamp: timestamp.add(const Duration(minutes: 5)),
          status: isCompleted ? 'completed' : 'ongoing',
          messageId: 'poll1',
          timestamp: timestamp,
        );

    testWidgets('shows the title, choices and vote percentages', (
      tester,
    ) async {
      await pumpEvent(
        tester,
        buildEventWidget(TwitchPollEventWidget(poll(isCompleted: false))),
      );

      expect(find.text('Best pet?'), findsOneWidget);
      expect(find.text('Cats'), findsOneWidget);
      expect(find.text('Dogs'), findsOneWidget);
      expect(find.text('75% (3)'), findsOneWidget);
      expect(find.text('25% (1)'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);
    });

    testWidgets('marks the winner of a completed poll', (tester) async {
      await pumpEvent(
        tester,
        buildEventWidget(TwitchPollEventWidget(poll(isCompleted: true))),
      );

      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
      expect(find.text('Cats'), findsOneWidget);
      expect(find.text('Dogs'), findsOneWidget);
    });
  });

  group('TwitchHypeTrainEventWidget', () {
    TwitchHypeTrainEventModel train({
      bool hasEnded = false,
      bool isSuccessful = false,
    }) => TwitchHypeTrainEventModel(
      timestamp: timestamp,
      messageId: 'train',
      level: 2,
      progress: 150,
      goal: 600,
      total: 1000,
      startTimestamp: timestamp,
      endTimestamp: timestamp,
      hasEnded: hasEnded,
      isSuccessful: isSuccessful,
    );

    testWidgets('shows progress while in progress', (tester) async {
      await pumpEvent(
        tester,
        buildEventWidget(TwitchHypeTrainEventWidget(train())),
      );

      expect(
        findRichText('Hype Train level 2 in progress! 25% completed!'),
        findsOneWidget,
      );
    });

    testWidgets('shows success when ended successfully', (tester) async {
      await pumpEvent(
        tester,
        buildEventWidget(
          TwitchHypeTrainEventWidget(train(hasEnded: true, isSuccessful: true)),
        ),
      );

      expect(findRichText('Hype Train level 2 succeeded.'), findsOneWidget);
    });

    testWidgets('shows failure when ended unsuccessfully', (tester) async {
      await pumpEvent(
        tester,
        buildEventWidget(TwitchHypeTrainEventWidget(train(hasEnded: true))),
      );

      expect(findRichText('Hype Train level 2 failed.'), findsOneWidget);
    });
  });

  group('shoutout events', () {
    testWidgets('created shoutout names the recipient', (tester) async {
      await pumpEvent(
        tester,
        buildEventWidget(
          TwitchShoutoutCreateEventWidget(
            TwitchShoutoutCreateEventModel(
              timestamp: timestamp,
              messageId: 'so1',
              fromBroadcasterUserId: '1',
              fromBroadcasterUserName: 'muxfd',
              toBroadcasterUserId: '2',
              toBroadcasterUserName: 'automux',
              viewerCount: 42,
            ),
          ),
        ),
      );

      expect(
        findRichText('Shoutout was given to automux with 42 viewers'),
        findsOneWidget,
      );
    });

    testWidgets('received shoutout names the sender', (tester) async {
      await pumpEvent(
        tester,
        buildEventWidget(
          TwitchShoutoutReceiveEventWidget(
            TwitchShoutoutReceiveEventModel(
              timestamp: timestamp,
              messageId: 'so2',
              fromBroadcasterUserId: '2',
              fromBroadcasterUserName: 'automux',
              viewerCount: 7,
            ),
          ),
        ),
      );

      expect(
        findRichText('automux gave you a shoutout to 7 viewers'),
        findsOneWidget,
      );
    });
  });
}
