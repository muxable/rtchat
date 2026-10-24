import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/twitch/raiding_event.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/style.dart';

import '../../l10n.dart';

void main() {
  HttpOverrides.global = null;

  TwitchRaidingEventModel raiding() => TwitchRaidingEventModel(
    timestamp: DateTime.now(),
    messageId: 'raiding.r1',
    duration: const Duration(seconds: 90),
    targetUser: const TwitchUserModel(
      userId: 't1',
      login: 'target',
      displayName: 'Target',
    ),
  );

  // the avatar is a real network image that flutter's image cache keeps.
  final leakTesting = LeakTesting.settings.withIgnored(
    classes: ['ImageStreamCompleterHandle', '_LiveImage'],
  );

  testWidgets(
    'cancels the raid during the countdown',
    experimentalLeakTesting: leakTesting,
    (tester) async {
      var cancelled = 0;
      await tester.pumpWidget(
        buildWidget(
          TwitchRaidingEventWidget(
            raiding(),
            onCancel: () async {
              cancelled++;
            },
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cancelled, 1);

      // Stop the countdown's periodic stream.
      await tester.pumpWidget(Container());
    },
  );

  testWidgets(
    'has nothing to cancel once the raid is complete',
    experimentalLeakTesting: leakTesting,
    (tester) async {
      await tester.pumpWidget(
        buildWidget(
          TwitchRaidingEventWidget(
            raiding().withSuccessful(),
            onCancel: () async {},
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Cancel'), findsNothing);
    },
  );
}

Widget buildWidget(Widget child) {
  return ChangeNotifierProvider<StyleModel>(
    create: (_) => StyleModel.fromJson({}),
    child: MaterialApp(home: TestLocalizations(child: Material(child: child))),
  );
}
