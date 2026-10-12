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
    await tester.pumpWidget(app(views));
    expect(find.byType(FilterChip), findsNothing);
  });

  testWidgets("chips toggle a channel's visibility", (tester) async {
    final views = simulcast();
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
}
