import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:rtchat/api.dart';
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
        home: Scaffold(
          body: ChatHistoryMessage(
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
  tearDown(Api.debugReset);

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
  for (final error in [
    FirebaseFunctionsException(
      code: 'failed-precondition',
      message: 'The specified broadcaster does not have a raid pending.',
    ),
    FirebaseFunctionsException(
      code: 'unavailable',
      message: 'Connection unavailable',
    ),
  ]) {
    testWidgets(
      'cancel raid reports ${error.code} without an uncaught error',
      experimentalLeakTesting: leakTesting,
      (tester) async {
        await pump(tester, raidingChannel);
        final context = tester.element(find.byType(ChatHistoryMessage));
        final account = context.read<UserModel>().accountFor(raidingChannel)!;
        Api.debugOverride(account.app, Api(_FailingFunctions(error)));
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text(error.message!), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'a late cancellation failure is safe after leaving chat',
    experimentalLeakTesting: leakTesting,
    (tester) async {
      final pending = Completer<void>();
      final error = FirebaseFunctionsException(
        code: 'unavailable',
        message: 'Connection unavailable',
      );
      await pump(tester, raidingChannel);
      final context = tester.element(find.byType(ChatHistoryMessage));
      final account = context.read<UserModel>().accountFor(raidingChannel)!;
      Api.debugOverride(
        account.app,
        Api(_FailingFunctions(error, pending.future)),
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

class _FailingFunctions extends Fake implements FirebaseFunctions {
  final FirebaseFunctionsException error;
  final Future<void>? pending;
  _FailingFunctions(this.error, [this.pending]);
  @override
  HttpsCallable httpsCallableFromUrl(
    String url, {
    HttpsCallableOptions? options,
  }) => _FailingCallable(error, pending);
}

class _FailingCallable extends Fake implements HttpsCallable {
  final FirebaseFunctionsException error;
  final Future<void>? pending;
  _FailingCallable(this.error, this.pending);
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    await pending;
    throw error;
  }
}
