import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/message.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages/kick/message.dart';
import 'package:rtchat/models/messages/kick/user.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/user.dart';

import '../../fakes/fake_user_model.dart';

final kickChannel = Channel(Providers.kick, '42', 'streamer');

KickMessageModel kickMessage() => KickMessageModel(
  messageId: 'kick:m1',
  timestamp: DateTime(2025),
  author: const KickUserModel(userId: '7', login: 'viewer'),
  message: 'hello',
  channelId: 'kick:42',
);

Future<void> pump(WidgetTester tester, Channel userChannel) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserModel>.value(
          value: FakeUserModel(userChannel: userChannel),
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
          child: ChatHistoryMessage(
            message: kickMessage(),
            channel: kickChannel,
          ),
        ),
      ),
    ),
  );
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

  testWidgets('a twitch channel with the same id is not the kick channel', (
    tester,
  ) async {
    await pump(tester, Channel(Providers.twitch, '42', 'me'));
    expect(find.byType(InkWell), findsNothing);
  });
}
