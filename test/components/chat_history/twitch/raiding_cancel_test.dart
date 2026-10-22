import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/message.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/user.dart';

import '../../../fakes/fake_user_model.dart';

final raidingChannel = Channel(Providers.twitch, '42', 'streamer');

// the avatar is a real network image that flutter's image cache keeps.
final leakTesting = LeakTesting.settings.withIgnored(
  classes: ['ImageStreamCompleterHandle', '_LiveImage'],
);

Future<void> pump(WidgetTester tester, Channel userChannel) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserModel>(
          create: (_) => FakeUserModel(userChannel: userChannel),
        ),
        ChangeNotifierProvider<LayoutModel>(
          create: (_) => LayoutModel.fromJson({}),
        ),
        ChangeNotifierProvider<StyleModel>(
          create: (_) => StyleModel.fromJson({}),
        ),
        ChangeNotifierProvider<EventSubConfigurationModel>(
          create: (_) => EventSubConfigurationModel.fromJson({}),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(
          child: ChatHistoryMessage(
            message: TwitchRaidingEventModel(
              timestamp: DateTime.now(),
              messageId: 'raiding.r1',
              duration: const Duration(seconds: 90),
              targetUser: const TwitchUserModel(
                userId: 't1',
                login: 'target',
                displayName: 'Target',
              ),
            ),
            channel: raidingChannel,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  HttpOverrides.global = null;

  testWidgets(
    'the raiding streamer can cancel',
    experimentalLeakTesting: leakTesting,
    (tester) async {
      await pump(tester, raidingChannel);
      expect(find.text('Cancel'), findsOneWidget);
    },
  );

  testWidgets(
    'moderators and viewers of the channel cannot',
    experimentalLeakTesting: leakTesting,
    (tester) async {
      await pump(tester, Channel(Providers.twitch, '99', 'mod'));
      expect(find.text('Cancel'), findsNothing);
    },
  );
}
