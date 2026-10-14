import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/channel_filter_chips.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/views.dart';

import '../fakes/fake_chat.dart';

final twitch = Channel(Providers.twitch, '1', 'TwitchMux');
final kick = Channel(Providers.kick, '2', 'KickMux');

FakeChatMessage chat(String id, int seconds, Channel channel) =>
    FakeChatMessage(
        messageId: id,
        timestamp: DateTime(2025).add(Duration(seconds: seconds)),
        author: const FakeChatUser(userId: 'u', login: 'u'),
        message: id)
      ..channel = channel;

Widget app(ViewsModel views) => ChangeNotifierProvider<ViewsModel>.value(
    value: views,
    child: const MaterialApp(home: Material(child: ChannelFilterChips())));

ViewsModel simulcast() {
  final views = ViewsModel();
  return views..showView(views.saveView("Simulcast", [twitch, kick]).id);
}

void main() {
  testWidgets("no chips for single channel views", (tester) async {
    final views = ViewsModel()..openChannel(twitch);
    addTearDown(views.dispose);
    await tester.pumpWidget(app(views));
    expect(find.byType(FilterChip), findsNothing);
  });

  testWidgets("chips toggle a channel's visibility", (tester) async {
    final views = simulcast();
    addTearDown(views.dispose);
    await tester.pumpWidget(app(views));
    expect(find.byType(FilterChip), findsNWidgets(2));
    await tester.tap(find.text('KickMux'));
    await tester.pump();
    expect(views.hiddenChannels, {kick});
    await tester.tap(find.text('KickMux'));
    await tester.pump();
    expect(views.hiddenChannels, isEmpty);
  });

  test("hidden channels reset when the view changes", () {
    final views = simulcast();
    views.setChannelHidden(kick, true);
    views.openChannel(twitch);
    expect(views.hiddenChannels, isEmpty);
  });

  test("hidden channels are left out of messages and separators", () {
    final model = MessagesModel.fromJson({});
    model.messages.addAll([
      chat('t1', 0, twitch),
      chat('k1', 1, kick),
      chat('t2', 600, twitch), // after a 10 minute gap
    ]);
    model.hiddenChannels = {kick};
    expect(model.messages.map((m) => m.messageId), ['t1', 't2']);
    // separators index into the visible messages.
    expect(model.separators.toList()..sort(), [0, 1]);
    model.hiddenChannels = {};
    expect(model.messages, hasLength(3));
  });

  testWidgets("attribution shows the message's platform", (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: ChannelAttribution(provider: Providers.kick, child: Text('hi'))));
    expect(find.byType(ProviderIcon), findsOneWidget);
    expect(find.text('hi'), findsOneWidget);
  });

  Widget attributed(String text,
          {TextDirection direction = TextDirection.ltr}) =>
      MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 20),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 200,
                child: ChannelAttribution(
                    provider: Providers.kick, child: Text(text)),
              ),
            ),
          ),
        ),
      );

  testWidgets("attribution sits at the end of the message's first line",
      (tester) async {
    await tester.pumpWidget(attributed('hi'));
    final line = tester.getRect(find.text('hi'));
    final icon = tester.getRect(find.byType(ProviderIcon));
    expect(icon.left, greaterThan(line.right));
    expect(tester.getRect(find.byType(ChannelAttribution)).right - icon.right,
        moreOrLessEquals(8));
    expect(icon.center.dy, moreOrLessEquals(line.center.dy, epsilon: 1));

    const long = 'a message long enough to wrap onto a few lines';
    await tester.pumpWidget(attributed(long));
    final message = tester.getRect(find.text(long));
    final wrapped = tester.getRect(find.byType(ProviderIcon));
    expect(message.height, greaterThan(2 * line.height));
    // pinned to the first line, not centered on the whole message.
    expect(wrapped.center.dy - message.top,
        moreOrLessEquals(line.height / 2, epsilon: 1));
  });

  testWidgets("attribution follows the text direction", (tester) async {
    await tester.pumpWidget(attributed('hi', direction: TextDirection.rtl));
    final line = tester.getRect(find.text('hi'));
    final icon = tester.getRect(find.byType(ProviderIcon));
    expect(icon.right, lessThan(line.left));
    expect(icon.left - tester.getRect(find.byType(ChannelAttribution)).left,
        moreOrLessEquals(8));
  });
}
