import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/header_bar.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/adapters/channels.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/views.dart';

import '../fakes/fake_user_model.dart';

final twitch = Channel(Providers.twitch, '1', 'TwitchMux');
final kick = Channel(Providers.kick, '2', 'KickMux');

void main() {
  testWidgets("adding a channel before its metadata arrives", (tester) async {
    final user = FakeUserModel(userChannel: twitch);
    final views = ViewsModel()..update(user);
    addTearDown(views.dispose);
    addTearDown(user.dispose);

    // the single channel's metadata arrives; the added one's never does.
    final controllers = <StreamController<ChannelMetadata>>[];
    Stream<ChannelMetadata> metadataFor(Channel channel) {
      final controller = StreamController<ChannelMetadata>();
      controllers.add(controller);
      if (controllers.length == 1) {
        controller.add(
          TwitchChannelMetadata(
            viewerCount: 5,
            followerCount: 9,
            onlineAt: DateTime.now(),
          ),
        );
      }
      return controller.stream;
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ViewsModel>.value(value: views),
          ChangeNotifierProvider<LayoutModel>(
            create: (_) => LayoutModel.fromJson({}),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: HeaderBarWidget(
              channel: twitch,
              onChannelSelect: (_) {},
              metadataFor: metadataFor,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('/TwitchMux'), findsOneWidget);

    views.addChannel(kick);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('/TwitchMux +1'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsNWidgets(2));

    views.removeChannel(kick);
    await tester.pump();
    expect(find.text('/TwitchMux'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsNothing);

    // the header's timers don't outlive the test.
    await tester.pumpWidget(const SizedBox());
  });

  test("the title counts the channels after the first", () {
    expect(headerTitle([twitch]), '/TwitchMux');
    expect(headerTitle([kick, twitch]), '/KickMux +1');
    expect(
      headerTitle([twitch, kick, Channel(Providers.kick, '3', 'x')]),
      '/TwitchMux +2',
    );
  });
}
