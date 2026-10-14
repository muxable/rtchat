import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/message.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages/kick/message.dart';
import 'package:rtchat/models/messages/kick/user.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/youtube/message.dart';
import 'package:rtchat/models/messages/youtube/user.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/user.dart';

import '../../fakes/fake_functions.dart';
import '../../fakes/fake_user_model.dart';

final kickChannel = Channel(Providers.kick, '42', 'streamer');

KickMessageModel kickMessage() => KickMessageModel(
    messageId: 'kick:m1',
    timestamp: DateTime(2025),
    author: const KickUserModel(userId: '7', login: 'viewer'),
    message: 'hello',
    channelId: 'kick:42');

const youtubeChannelId = 'UCaaaaaaaaaaaaaaaaaaaaaa';
const youtubeViewerId = 'UCbbbbbbbbbbbbbbbbbbbbbb';
final youtubeChannel = Channel(Providers.youtube, youtubeChannelId, 'me');

YouTubeMessageModel youtubeMessage() => YouTubeMessageModel(
    messageId: 'youtube:LCC.m1',
    timestamp: DateTime(2026),
    author:
        const YouTubeUserModel(userId: youtubeViewerId, displayName: '@viewer'),
    message: 'hello',
    channelId: 'youtube:$youtubeChannelId');

Future<void> pump(WidgetTester tester, Channel userChannel,
    {MessageModel? message, Channel? channel}) async {
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<UserModel>.value(
          value: FakeUserModel(userChannel: userChannel)),
      ChangeNotifierProvider<LayoutModel>.value(
          value: LayoutModel.fromJson({})),
      ChangeNotifierProvider<StyleModel>.value(value: StyleModel.fromJson({})),
    ],
    // dialogs are built outside `home`, so localizations come from the app.
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChatHistoryMessage(
            message: message ?? kickMessage(), channel: channel ?? kickChannel),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('owners can moderate their kick chat', (tester) async {
    await pump(tester, kickChannel);
    await tester.longPress(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.text('Delete Message'), findsOneWidget);
    expect(find.textContaining('Timeout'), findsOneWidget);
    // muting kick users isn't supported yet.
    expect(find.textContaining('Mute'), findsNothing);
  });

  testWidgets('viewers of someone else\'s kick chat cannot', (tester) async {
    await pump(tester, Channel(Providers.kick, '99', 'me'));
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('a twitch channel with the same id is not the kick channel',
      (tester) async {
    await pump(tester, Channel(Providers.twitch, '42', 'me'));
    expect(find.byType(InkWell), findsNothing);
  });

  group('youtube', () {
    late FakeCallable delete;
    late FakeCallable ban;
    late FakeCallable timeout;

    setUp(() {
      delete = FakeCallable((_) async => null);
      ban = FakeCallable((_) async => null);
      timeout = FakeCallable((_) async => null);
      ActionsAdapter.instance = ActionsAdapter.withFunctions(FakeFunctions(
          {'deleteMessage': delete, 'ban': ban, 'timeout': timeout}));
    });

    tearDown(() => ActionsAdapter.instance = null);

    Future<void> pumpYouTube(WidgetTester tester, Channel userChannel) =>
        pump(tester, userChannel,
            message: youtubeMessage(), channel: youtubeChannel);

    Future<void> open(WidgetTester tester) async {
      await tester.longPress(find.byType(InkWell));
      await tester.pumpAndSettle();
    }

    testWidgets('owners can delete, time out and ban', (tester) async {
      await pumpYouTube(tester, youtubeChannel);
      await open(tester);
      expect(find.text('Delete Message'), findsOneWidget);
      expect(find.textContaining('Timeout'), findsOneWidget);
      expect(find.textContaining('Ban'), findsOneWidget);
      // youtube unbans need the ban id, which messages don't carry.
      expect(find.textContaining('Unban'), findsNothing);

      await tester.tap(find.text('Delete Message'));
      await tester.pumpAndSettle();
      expect(delete.calls.single, {
        'provider': 'youtube',
        'channelId': youtubeChannelId,
        'messageId': 'youtube:LCC.m1',
      });

      await open(tester);
      await tester.tap(find.textContaining('Ban'));
      await tester.pumpAndSettle();
      expect(ban.calls.single['userId'], youtubeViewerId);
      expect(ban.calls.single['channelId'], youtubeChannelId);
    });

    testWidgets('shows quota errors', (tester) async {
      delete = FakeCallable((_) async => throw youTubeQuotaError());
      ActionsAdapter.instance = ActionsAdapter.withFunctions(
          FakeFunctions({'deleteMessage': delete}));
      await pumpYouTube(tester, youtubeChannel);
      await open(tester);
      await tester.tap(find.text('Delete Message'));
      await tester.pumpAndSettle();
      expect(find.text(youTubeQuotaMessage), findsOneWidget);
    });

    testWidgets('viewers of someone else\'s youtube chat cannot',
        (tester) async {
      await pumpYouTube(
          tester, Channel(Providers.youtube, youtubeViewerId, 'viewer'));
      expect(find.byType(InkWell), findsNothing);
    });
  });
}
