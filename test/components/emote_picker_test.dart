import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';

import 'l10n.dart';

final channel = Channel('twitch', '1', 'muxfd');

Emote emote(String code, String? category) => Emote(
    provider: 'bttv',
    category: category,
    id: code,
    code: code,
    imageUrl: 'https://example.com/$code.png');

Future<void> pumpEmotes(WidgetTester tester, List<Emote> emotes) async {
  await tester.pumpWidget(MaterialApp(
      home: TestLocalizations(
          child: Material(
              child: EmotesList(
                  emotes: emotes,
                  channel: channel,
                  onEmoteSelected: (_) {})))));
  // localizations load asynchronously.
  await tester.pump();
}

List<String> headers(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data!)
    .toList();

void main() {
  testWidgets("shows a channel's emotes when there are no global ones",
      (tester) async {
    await pumpEmotes(tester, [emote('muxHi', 'muxfd')]);
    expect(tester.takeException(), isNull);
    expect(headers(tester), ['muxfd']);
  });

  testWidgets("orders the channel's emotes, global emotes, then the rest",
      (tester) async {
    await pumpEmotes(tester, [
      emote('Zed', 'Zed'),
      emote('muxHi', 'muxfd'),
      emote('Kappa', null),
      emote('Abc', 'Abc'),
    ]);
    expect(headers(tester), ['muxfd', 'Global Emotes', 'Abc', 'Zed']);
  });
}
