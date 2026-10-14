import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:rtchat/components/channel_search_results.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';

SearchResult result(String provider, String id, String name) => SearchResult(
    channelId: id,
    provider: provider,
    login: name.toLowerCase(),
    displayName: name,
    isOnline: true,
    // a data uri, so no network image is fetched.
    imageUrl: Uri.parse('data:,'),
    title: null,
    isPromoted: false,
    language: 'en');

final results = [
  result(Providers.twitch, '1', 'xQc'),
  result(Providers.kick, '2', 'xQc'),
];

Widget app(
        {required void Function(Channel) onChannelSelect,
        void Function(Channel)? onChannelAdd,
        List<Channel> channels = const [],
        Widget? header}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(
        child: ChannelSearchResultsWidget(
          query: 'xqc',
          isShowOnlyOnline: false,
          onChannelSelect: onChannelSelect,
          onChannelAdd: onChannelAdd,
          channels: channels,
          header: header,
          search: (query, provider, isShowOnlyOnline) => Stream.value(results),
        ),
      ),
    );

// the profile pictures are network images that flutter's image cache keeps.
final ignoreImages = LeakTesting.settings
    .withIgnored(classes: ['ImageStreamCompleterHandle', '_LiveImage']);

void main() {
  testWidgets("tapping a result opens it",
      experimentalLeakTesting: ignoreImages, (tester) async {
    final selected = <Channel>[];
    await tester.pumpWidget(app(onChannelSelect: selected.add));
    await tester.pump();
    await tester.tap(find.byType(ListTile).last);
    expect(selected, [Channel(Providers.kick, '2', 'xQc')]);
  });

  testWidgets("results can't be swiped unless they can be added",
      experimentalLeakTesting: ignoreImages, (tester) async {
    await tester.pumpWidget(app(onChannelSelect: (_) {}));
    await tester.pump();
    expect(find.byType(Dismissible), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets("swiping a result right adds it instead of opening it",
      experimentalLeakTesting: ignoreImages, (tester) async {
    final selected = <Channel>[];
    final added = <Channel>[];
    await tester.pumpWidget(app(
        onChannelSelect: selected.add,
        onChannelAdd: added.add,
        channels: [Channel(Providers.twitch, '9', 'Someone')]));
    await tester.pump();
    // no buttons, just the gesture.
    expect(find.byType(IconButton), findsNothing);

    // swiping left does nothing.
    await tester.drag(find.byType(ListTile).last, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(added, isEmpty);

    await tester.drag(find.byType(ListTile).last, const Offset(400, 0));
    await tester.pump();
    expect(find.text('Add to chat'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(added, [Channel(Providers.kick, '2', 'xQc')]);
    expect(selected, isEmpty);
    // the result stays.
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets("swiping a result whose provider is in chat replaces it",
      experimentalLeakTesting: ignoreImages, (tester) async {
    final added = <Channel>[];
    await tester.pumpWidget(app(
        onChannelSelect: (_) {},
        onChannelAdd: added.add,
        channels: [Channel(Providers.twitch, '9', 'Someone')]));
    await tester.pump();
    await tester.drag(find.byType(ListTile).first, const Offset(400, 0));
    await tester.pump();
    expect(find.text('Replace Someone'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(added, [Channel(Providers.twitch, '1', 'xQc')]);
  });

  testWidgets("a result already in chat can't be swiped",
      experimentalLeakTesting: ignoreImages, (tester) async {
    await tester.pumpWidget(app(
        onChannelSelect: (_) {},
        onChannelAdd: (_) {},
        channels: [Channel(Providers.twitch, '1', 'xQc')]));
    await tester.pump();
    expect(find.byType(Dismissible), findsOneWidget);
    expect(
        find.ancestor(
            of: find.byType(ListTile).first,
            matching: find.byType(Dismissible)),
        findsNothing);
  });

  testWidgets("tapping a result switches to it whatever is in chat",
      experimentalLeakTesting: ignoreImages, (tester) async {
    final selected = <Channel>[];
    final added = <Channel>[];
    await tester.pumpWidget(app(
        onChannelSelect: selected.add,
        onChannelAdd: added.add,
        channels: [Channel(Providers.twitch, '9', 'Someone')]));
    await tester.pump();
    await tester.tap(find.byType(ListTile).last);
    expect(selected, [Channel(Providers.kick, '2', 'xQc')]);
    expect(added, isEmpty);
  });

  testWidgets("a header is shown above the results",
      experimentalLeakTesting: ignoreImages, (tester) async {
    await tester.pumpWidget(
        app(onChannelSelect: (_) {}, header: const Text('In chat')));
    await tester.pump();
    expect(tester.getTopLeft(find.text('In chat')).dy,
        lessThan(tester.getTopLeft(find.byType(ListTile).first).dy));
  });
}
