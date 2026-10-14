import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:rtchat/components/channel_search_bottom_sheet.dart';
import 'package:rtchat/components/channel_search_results.dart';
import 'package:rtchat/models/channels.dart';

import 'l10n.dart';

SearchResult result(String provider, String login, {bool isOnline = false}) =>
    SearchResult(
        channelId: login,
        provider: provider,
        login: login,
        displayName: login,
        isOnline: isOnline,
        imageUrl: Uri.parse("https://example.com/$login.png"),
        title: null,
        isPromoted: true,
        language: null);

void main() {
  test("youtube can be searched", () {
    expect(searchProviders.keys, ["twitch", "kick", "youtube"]);
    expect(searchProviders["youtube"], "youtube.com/@");
  });

  group("filterRecentChannels", () {
    final recent = [
      result("twitch", "xqc"),
      result("kick", "xqc"),
      result("kick", "xqcshadow", isOnline: true),
      result("twitch", "muxfd"),
    ];

    test("keeps only the selected provider's channels", () {
      expect(
          filterRecentChannels(recent, "xqc", "kick")
              .map((r) => "${r.provider}:${r.login}"),
          ["kick:xqcshadow", "kick:xqc"]);
      expect(
          filterRecentChannels(recent, "", "twitch")
              .map((r) => "${r.provider}:${r.login}"),
          ["twitch:xqc", "twitch:muxfd"]);
    });

    test("matches the query case-insensitively", () {
      expect(filterRecentChannels(recent, "MUX", "twitch").map((r) => r.login),
          ["muxfd"]);
      expect(filterRecentChannels(recent, "MUX", "kick"), isEmpty);
    });
  });

  testWidgets("the provider dropdown switches which provider is searched",
      (tester) async {
    final calls = <String>[];
    Stream<List<SearchResult>> fakeSearch(
        String query, String provider, bool isShowOnlyOnline) {
      calls.add("$provider:$query");
      return Stream.value(const []);
    }

    await tester.pumpWidget(MaterialApp(
        home: TestLocalizations(
            child: Material(
                child: ChannelSearchBottomSheetWidget(
                    onChannelSelect: (_) {}, search: fakeSearch)))));
    await tester.pump();

    expect(find.text("twitch.tv/"), findsOneWidget);
    expect(calls, ["twitch:"]);

    await tester.tap(find.text("twitch.tv/"));
    await tester.pumpAndSettle();
    expect(find.text("kick.com/"), findsOneWidget);
    await tester.tap(find.text("kick.com/"));
    await tester.pumpAndSettle();

    expect(find.text("kick.com/"), findsOneWidget);
    expect(find.text("twitch.tv/"), findsNothing);
    expect(calls, ["twitch:", "kick:"]);

    await tester.enterText(find.byType(TextField), "xqc");
    await tester.pump();
    // typing is debounced.
    await tester.pump(const Duration(milliseconds: 600));
    expect(calls.last, "kick:xqc");
  });

  test("youtube results become youtube channels", () {
    final channel = result("youtube", "UCX6OQ3DkcsbYNE6H8uQQuVA").channel;
    expect(channel.provider, Providers.youtube);
    expect(channel.toString(), "youtube:UCX6OQ3DkcsbYNE6H8uQQuVA");
  });

  testWidgets("picking youtube searches youtube and lists its channels",
      // the profile pictures are network images that flutter's image cache
      // keeps.
      experimentalLeakTesting: LeakTesting.settings
          .withIgnored(classes: ['ImageStreamCompleterHandle', '_LiveImage']),
      (tester) async {
    final calls = <String>[];
    Stream<List<SearchResult>> fakeSearch(
        String query, String provider, bool isShowOnlyOnline) {
      calls.add("$provider:$query");
      return Stream.value([
        if (provider == "youtube" && query.isNotEmpty)
          result("youtube", "MrBeast", isOnline: false),
      ]);
    }

    await tester.pumpWidget(MaterialApp(
        home: TestLocalizations(
            child: Material(
                child: ChannelSearchBottomSheetWidget(
                    onChannelSelect: (_) {}, search: fakeSearch)))));
    await tester.pump();

    await tester.tap(find.text("twitch.tv/"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("youtube.com/@"));
    await tester.pumpAndSettle();
    expect(find.text("youtube.com/@"), findsOneWidget);

    await tester.enterText(find.byType(TextField), "mrbeast");
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(calls.last, "youtube:mrbeast");
    expect(find.text("MrBeast"), findsOneWidget);
  });
}
