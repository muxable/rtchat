import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/channel_search_bottom_sheet.dart';
import 'package:rtchat/components/channel_search_results.dart';

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
      language: null,
    );

void main() {
  group("filterRecentChannels", () {
    final recent = [
      result("twitch", "xqc"),
      result("kick", "xqc"),
      result("kick", "xqcshadow", isOnline: true),
      result("twitch", "muxfd"),
    ];

    test("keeps only the selected provider's channels", () {
      expect(
        filterRecentChannels(
          recent,
          "xqc",
          "kick",
        ).map((r) => "${r.provider}:${r.login}"),
        ["kick:xqcshadow", "kick:xqc"],
      );
      expect(
        filterRecentChannels(
          recent,
          "",
          "twitch",
        ).map((r) => "${r.provider}:${r.login}"),
        ["twitch:xqc", "twitch:muxfd"],
      );
    });

    test("matches the query case-insensitively", () {
      expect(
        filterRecentChannels(recent, "MUX", "twitch").map((r) => r.login),
        ["muxfd"],
      );
      expect(filterRecentChannels(recent, "MUX", "kick"), isEmpty);
    });
  });

  testWidgets("the provider dropdown switches which provider is searched", (
    tester,
  ) async {
    final calls = <String>[];
    Stream<List<SearchResult>> fakeSearch(
      String query,
      String provider,
      bool isShowOnlyOnline,
    ) {
      calls.add("$provider:$query");
      return Stream.value(const []);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: TestLocalizations(
          child: Material(
            child: ChannelSearchBottomSheetWidget(
              onChannelSelect: (_) {},
              search: fakeSearch,
            ),
          ),
        ),
      ),
    );
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
}
