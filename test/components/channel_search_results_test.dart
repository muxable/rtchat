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
        bool Function(Channel)? isAdded,
        bool Function(Channel)? canAdd,
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
          isAdded: isAdded,
          canAdd: canAdd,
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

  testWidgets("no add buttons unless results can be added",
      experimentalLeakTesting: ignoreImages, (tester) async {
    await tester.pumpWidget(app(onChannelSelect: (_) {}));
    await tester.pump();
    expect(find.byTooltip('Add to chat'), findsNothing);
  });

  testWidgets("the add button adds a result instead of opening it",
      experimentalLeakTesting: ignoreImages, (tester) async {
    final selected = <Channel>[];
    final added = <Channel>[];
    await tester.pumpWidget(app(
        onChannelSelect: selected.add,
        onChannelAdd: added.add,
        isAdded: (channel) => channel.provider == Providers.twitch));
    await tester.pump();
    expect(find.byTooltip('Add to chat'), findsNWidgets(2));

    // already added: shown as such, and can't be added again.
    final twitchButton = tester.widget<IconButton>(find
        .descendant(
            of: find.byType(ListTile).first, matching: find.byType(IconButton))
        .first);
    expect(twitchButton.onPressed, isNull);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    expect(added, [Channel(Providers.kick, '2', 'xQc')]);
    expect(selected, isEmpty);
  });

  testWidgets("a result whose provider is already in chat can't be added",
      experimentalLeakTesting: ignoreImages, (tester) async {
    final selected = <Channel>[];
    final added = <Channel>[];
    await tester.pumpWidget(app(
        onChannelSelect: selected.add,
        onChannelAdd: added.add,
        canAdd: (channel) => channel.provider != Providers.twitch));
    await tester.pump();

    IconButton addButton(int index) => tester.widget<IconButton>(find
        .descendant(
            of: find.byType(ListTile).at(index),
            matching: find.byType(IconButton))
        .first);
    expect(addButton(0).onPressed, isNull);
    expect(addButton(0).tooltip, 'Only one Twitch channel can be in chat');
    expect(addButton(1).onPressed, isNotNull);
    expect(addButton(1).tooltip, 'Add to chat');

    // tapping it still opens it.
    await tester.tap(find.byType(ListTile).first);
    expect(selected, [Channel(Providers.twitch, '1', 'xQc')]);
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
