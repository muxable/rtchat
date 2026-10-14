import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/in_chat_channels.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/views.dart';

final twitch = Channel(Providers.twitch, '1', 'TwitchMux');
final kick = Channel(Providers.kick, '2', 'KickMux');
final friend = Channel(Providers.kick, '3', 'Friend');

Widget app(ViewsModel views) => ChangeNotifierProvider<ViewsModel>.value(
      value: views,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(child: InChatChannels()),
      ),
    );

Finder removeButton(String name) => find.descendant(
    of: find.widgetWithText(ListTile, name),
    matching: find.byTooltip('Remove from chat'));

// the twitch icon is an asset image that flutter's image cache keeps.
final ignoreImages = LeakTesting.settings
    .withIgnored(classes: ['ImageStreamCompleterHandle', '_LiveImage']);

void main() {
  testWidgets("nothing to show for a single channel",
      experimentalLeakTesting: ignoreImages, (tester) async {
    final views = ViewsModel()..openChannel(twitch);
    addTearDown(views.dispose);
    await tester.pumpWidget(app(views));
    expect(find.text('In chat'), findsNothing);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets("lists the channels in chat and removes them",
      experimentalLeakTesting: ignoreImages, (tester) async {
    final views = ViewsModel()
      ..openChannel(twitch)
      ..addChannel(kick)
      ..addChannel(friend);
    addTearDown(views.dispose);
    await tester.pumpWidget(app(views));
    expect(find.text('In chat'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));

    await tester.tap(removeButton('KickMux'));
    await tester.pump();
    expect(views.channels, [twitch, friend]);
    expect(find.text('KickMux'), findsNothing);

    // removing the last but one leaves a single channel, which can't be
    // removed, so the section goes away.
    await tester.tap(removeButton('Friend'));
    await tester.pump();
    expect(views.channels, [twitch]);
    expect(find.text('In chat'), findsNothing);
  });
}
