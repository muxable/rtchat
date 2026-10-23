import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/components/chat_history/message.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages/kick/message.dart';
import 'package:rtchat/models/messages/kick/user.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/user.dart';

import '../../fakes/fake_accounts.dart';
import '../../fakes/fake_api.dart';
import '../../fakes/fake_tts_engine.dart';
import '../../fakes/fake_user_model.dart';

final kickChannel = Channel(Providers.kick, '42', 'streamer');
final twitchChannel = Channel(Providers.twitch, '43', 'streamer');

KickMessageModel kickMessage() => KickMessageModel(
  messageId: 'kick:m1',
  timestamp: DateTime(2025),
  author: const KickUserModel(userId: '7', login: 'viewer'),
  message: 'hello',
  channelId: 'kick:42',
);

TwitchMessageModel twitchMessage() => TwitchMessageModel(
  messageId: 'twitch:m1',
  author: const TwitchUserModel(userId: '8', login: 'viewer'),
  tags: const {},
  annotations: const TwitchMessageAnnotationsModel(
    isAction: false,
    isFirstTimeChatter: false,
    announcement: null,
  ),
  thirdPartyEmotes: const [],
  timestamp: DateTime(2025),
  message: 'hello',
  deleted: false,
  channelId: 'twitch:43',
);

Future<void> pump(WidgetTester tester, Channel userChannel) => pumpMessage(
  tester,
  FakeUserModel(userChannel: userChannel),
  kickMessage(),
  kickChannel,
);

Future<void> pumpMessage(
  WidgetTester tester,
  UserModel userModel,
  MessageModel message,
  Channel channel,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserModel>.value(value: userModel),
        ChangeNotifierProvider<TtsModel>.value(
          value: TtsModel.fromJson({}, engine: FakeTtsEngine()),
        ),
        ChangeNotifierProvider<LayoutModel>.value(
          value: LayoutModel.fromJson({}),
        ),
        ChangeNotifierProvider<StyleModel>.value(
          value: StyleModel.fromJson({}),
        ),
      ],
      // dialogs are built outside `home`, so localizations come from the app.
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(
          child: ChatHistoryMessage(message: message, channel: channel),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openModeration(WidgetTester tester) async {
  await tester.longPress(find.byType(InkWell));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('owners can moderate their kick chat', (tester) async {
    await pump(tester, kickChannel);
    await openModeration(tester);
    expect(find.text('Delete Message'), findsOneWidget);
    expect(find.textContaining('Timeout'), findsOneWidget);
    // muting kick users isn't supported yet.
    expect(find.textContaining('Mute'), findsNothing);
  });

  testWidgets('viewers of someone else\'s kick chat cannot', (tester) async {
    await pump(tester, Channel(Providers.kick, '99', 'me'));
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('a twitch channel with the same id is not the kick channel', (
    tester,
  ) async {
    await pump(tester, Channel(Providers.twitch, '42', 'me'));
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets(
    'a channel without an account on its provider cannot be moderated',
    (tester) async {
      // signed in to twitch only, as the same streamer.
      final userModel = FakeUserModel(
        accounts: [
          fakeAccount(
            Channel(Providers.twitch, '42', 'streamer'),
            appName: '[DEFAULT]',
          ),
        ],
      );
      await pumpMessage(tester, userModel, kickMessage(), kickChannel);
      expect(find.byType(InkWell), findsNothing);
    },
  );

  group('signed in to twitch and kick', () {
    late Account twitch, kick;
    late FakeFunctions twitchApi, kickApi;
    late UserModel userModel;

    setUp(() {
      twitch = fakeAccount(twitchChannel, appName: '[DEFAULT]');
      kick = fakeAccount(kickChannel);
      twitchApi = fakeApiFor(twitch);
      kickApi = fakeApiFor(kick);
      userModel = FakeUserModel(accounts: [twitch, kick]);
    });

    tearDown(Api.debugReset);

    testWidgets('both channels can be moderated, each as its own account', (
      tester,
    ) async {
      await pumpMessage(tester, userModel, twitchMessage(), twitchChannel);
      await openModeration(tester);
      await tester.tap(find.text('Delete Message'));
      await tester.pumpAndSettle();
      await pumpMessage(tester, userModel, kickMessage(), kickChannel);
      await openModeration(tester);
      await tester.tap(find.text('Delete Message'));
      await tester.pumpAndSettle();

      expect(twitchApi.calls.single.data['provider'], Providers.twitch);
      expect(kickApi.calls.single.data['provider'], Providers.kick);
    });

    testWidgets('a kick ban calls as the kick account', (tester) async {
      await pumpMessage(tester, userModel, kickMessage(), kickChannel);
      await openModeration(tester);
      await tester.tap(find.textContaining('Ban'));
      await tester.pumpAndSettle();

      expect(twitchApi.calls, isEmpty);
      expect(kickApi.calls.single.name, 'ban');
      expect(kickApi.calls.single.data, {
        'provider': Providers.kick,
        'channelId': '42',
        'username': 'viewer',
        'userId': '7',
      });
    });

    testWidgets('a kick timeout calls as the kick account', (tester) async {
      await pumpMessage(tester, userModel, kickMessage(), kickChannel);
      await openModeration(tester);
      await tester.tap(find.textContaining('Timeout'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      expect(twitchApi.calls, isEmpty);
      expect(kickApi.calls.single.name, 'timeout');
      expect(kickApi.calls.single.data['provider'], Providers.kick);
      expect(kickApi.calls.single.data['channelId'], '42');
    });

    testWidgets('a twitch delete calls as the twitch account', (tester) async {
      await pumpMessage(tester, userModel, twitchMessage(), twitchChannel);
      await openModeration(tester);
      await tester.tap(find.text('Delete Message'));
      await tester.pumpAndSettle();

      expect(kickApi.calls, isEmpty);
      expect(twitchApi.calls.single.name, 'deleteMessage');
      expect(twitchApi.calls.single.data, {
        'provider': Providers.twitch,
        'channelId': '43',
        'messageId': 'twitch:m1',
      });
    });

    testWidgets('a twitch ban calls as the twitch account', (tester) async {
      await pumpMessage(tester, userModel, twitchMessage(), twitchChannel);
      await openModeration(tester);
      await tester.tap(find.textContaining('Ban'));
      await tester.pumpAndSettle();

      expect(kickApi.calls, isEmpty);
      expect(twitchApi.calls.single.name, 'ban');
      expect(twitchApi.calls.single.data['provider'], Providers.twitch);
      expect(twitchApi.calls.single.data['channelId'], '43');
    });
  });
}
