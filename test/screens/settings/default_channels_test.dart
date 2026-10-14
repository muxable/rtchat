import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/channel_search_bottom_sheet.dart';
import 'package:rtchat/components/channel_search_results.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/views.dart';
import 'package:rtchat/screens/settings/default_channels.dart';

import '../../fakes/fake_user_model.dart';

final twitch = Channel(Providers.twitch, '1', 'TwitchMux');
final kick = Channel(Providers.kick, '2', 'KickMux');

ViewsModel signedInAs(Channel channel) {
  final user = FakeUserModel(userChannel: channel);
  final views = ViewsModel()..update(user);
  addTearDown(views.dispose);
  addTearDown(user.dispose);
  return views;
}

SearchResult result(Channel channel) => SearchResult(
    channelId: channel.channelId,
    provider: channel.provider,
    login: channel.displayName.toLowerCase(),
    displayName: channel.displayName,
    isOnline: true,
    // a data uri, so no network image is fetched.
    imageUrl: Uri.parse('data:,'),
    title: null,
    isPromoted: false,
    language: 'en');

Widget app(ViewsModel views,
        {void Function(BuildContext)? searchChannels,
        List<SearchResult> results = const []}) =>
    ChangeNotifierProvider<ViewsModel>.value(
      value: views,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DefaultChannelsScreen(
            searchChannels: searchChannels,
            search: (query, provider, isShowOnlyOnline) =>
                Stream.value(results)),
      ),
    );

// the twitch icon is an asset image that flutter's image cache keeps.
final ignoreImages = LeakTesting.settings
    .withIgnored(classes: ['ImageStreamCompleterHandle', '_LiveImage']);

void main() {
  testWidgets("shows the user's channel until others are picked",
      experimentalLeakTesting: ignoreImages, (tester) async {
    await tester.pumpWidget(app(signedInAs(twitch)));
    expect(find.text('TwitchMux'), findsOneWidget);
    // it's the fallback, so there's nothing to remove.
    expect(find.byType(Dismissible), findsNothing);
    expect(find.text('Swipe left to remove'), findsNothing);
  });

  testWidgets("adds channels from search and removes them",
      experimentalLeakTesting: ignoreImages, (tester) async {
    final views = signedInAs(twitch);
    await tester.pumpWidget(
        app(views, searchChannels: (context) => views.addDefaultChannel(kick)));
    await tester.tap(find.text('Add channel'));
    await tester.pump();
    expect(views.defaultChannels, [twitch, kick]);
    expect(find.text('KickMux'), findsOneWidget);

    expect(find.text('Swipe left to remove'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
    await tester.drag(find.text('TwitchMux'), const Offset(-500, 0));
    await tester.pump();
    expect(find.text('Remove'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(views.defaultChannels, [kick]);
    expect(find.text('TwitchMux'), findsNothing);
  });

  testWidgets("copies the current channels",
      experimentalLeakTesting: ignoreImages, (tester) async {
    final views = signedInAs(twitch);
    await tester.pumpWidget(app(views));
    final button = find.widgetWithText(OutlinedButton, 'Use current channels');
    // already the same.
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);

    views.addChannel(kick);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    expect(views.defaultChannels, [twitch, kick]);
    expect(find.text('KickMux'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
  });

  testWidgets("search swipes add or replace by provider, taps switch",
      experimentalLeakTesting: ignoreImages, (tester) async {
    final otherTwitch = Channel(Providers.twitch, '3', 'Friend');
    final otherKick = Channel(Providers.kick, '4', 'Pal');
    final views = signedInAs(twitch);
    await tester.pumpWidget(app(views,
        results: [result(otherTwitch), result(kick), result(otherKick)]));
    await tester.tap(find.text('Add channel'));
    await tester.pumpAndSettle();
    expect(find.text('Tap a channel to switch to it, or swipe right to add it'),
        findsOneWidget);
    expect(find.byType(IconButton), findsNothing);

    await tester.drag(
        find.widgetWithText(ListTile, 'KickMux').last, const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(views.defaultChannels, [twitch, kick]);

    await tester.drag(
        find.widgetWithText(ListTile, 'Friend').last, const Offset(400, 0));
    await tester.pump();
    expect(find.text('Replace TwitchMux'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(views.defaultChannels, [otherTwitch, kick]);

    await tester.drag(
        find.widgetWithText(ListTile, 'Pal').last, const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(views.defaultChannels, [otherTwitch, otherKick]);

    // tapping a result makes it the only default channel.
    tester
        .widget<ChannelSearchBottomSheetWidget>(
            find.byType(ChannelSearchBottomSheetWidget))
        .onChannelSelect(kick);
    expect(views.defaultChannels, [kick]);
  });
}
