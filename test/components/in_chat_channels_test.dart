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

Widget app(ViewsModel views) => ChangeNotifierProvider<ViewsModel>.value(
  value: views,
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Material(child: InChatChannels()),
  ),
);

// the twitch icon is an asset image that flutter's image cache keeps.
final ignoreImages = LeakTesting.settings.withIgnored(
  classes: ['ImageStreamCompleterHandle', '_LiveImage'],
);

void main() {
  testWidgets(
    "nothing to show for a single channel",
    experimentalLeakTesting: ignoreImages,
    (tester) async {
      final views = ViewsModel()..openChannel(twitch);
      addTearDown(views.dispose);
      await tester.pumpWidget(app(views));
      expect(find.text('In chat'), findsNothing);
      expect(find.byType(ListTile), findsNothing);
    },
  );

  testWidgets(
    "lists the channels in chat, removed by swiping left",
    experimentalLeakTesting: ignoreImages,
    (tester) async {
      final views =
          ViewsModel()
            ..openChannel(twitch)
            ..addChannel(kick);
      addTearDown(views.dispose);
      await tester.pumpWidget(app(views));
      expect(find.text('In chat'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
      // no buttons, just the gesture.
      expect(find.byType(IconButton), findsNothing);

      // swiping right does nothing.
      await tester.drag(find.text('KickMux'), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(views.channels, [twitch, kick]);

      await tester.drag(find.text('KickMux'), const Offset(-500, 0));
      await tester.pump();
      expect(find.text('Remove from chat'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(views.channels, [twitch]);
      // a single channel can't be removed, so the section goes away.
      expect(find.text('In chat'), findsNothing);
    },
  );

  testWidgets(
    "a channel that can't be removed can't be swiped",
    experimentalLeakTesting: ignoreImages,
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SwipeToRemoveChannelTile(
              channel: twitch,
              onRemove: null,
              label: 'Remove',
            ),
          ),
        ),
      );
      expect(find.byType(Dismissible), findsNothing);
      expect(find.text('TwitchMux'), findsOneWidget);
    },
  );
}
