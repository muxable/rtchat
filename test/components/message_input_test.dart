import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/components/message_input.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/models/views.dart';

import '../fakes/fake_user_model.dart';

final twitch = Channel(Providers.twitch, '1', 'TwitchMux');
final kick = Channel(Providers.kick, '2', 'KickMux');
final otherKick = Channel(Providers.kick, '3', 'Friend');

/// A view of [twitch], [kick] and [otherKick], seen by a user signed in as
/// [kick].
ViewsModel simulcast() {
  final views = ViewsModel()..update(FakeUserModel(userChannel: kick));
  return views
    ..showView(views.saveView("Simulcast", [twitch, kick, otherKick]).id);
}

List<Emote> emotesOf(Channel channel) => [
      Emote(
          provider: 'twitch',
          category: null,
          id: 'global',
          code: 'Kappa',
          imageUrl: 'https://example.com/kappa.png'),
      Emote(
          provider: '7tv',
          category: channel.displayName,
          id: channel.channelId,
          code: 'emote${channel.channelId}',
          imageUrl: 'https://example.com/${channel.channelId}.png'),
    ];

void main() {
  setUp(() {
    // the input listens for text shared to the app.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('com.rtirl.chat/share'), (call) async => '');
  });

  group("emotes", () {
    late List<Channel> loaded;

    Future<List<Emote>> loadEmotes(Channel channel) async {
      loaded.add(channel);
      return emotesOf(channel);
    }

    setUp(() => loaded = []);

    Widget app(ViewsModel views, Channel primary) => MultiProvider(
          providers: [
            ChangeNotifierProvider<ViewsModel>.value(value: views),
            ChangeNotifierProvider<UserModel>.value(
                value: FakeUserModel(userChannel: kick)),
            ChangeNotifierProvider<StyleModel>.value(
                value: StyleModel.fromJson({})),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: MessageInputWidget(
                    channel: primary, loadEmotes: loadEmotes),
              ),
            ),
          ),
        );

    Future<EmotePickerWidget> openPicker(WidgetTester tester) async {
      await tester.tap(find.byType(IconButton).first);
      await tester.pump();
      return tester.widget<EmotePickerWidget>(find.byType(EmotePickerWidget));
    }

    testWidgets("are the destination's when sending to one other channel",
        (tester) async {
      final views = simulcast()..sendTarget = otherKick.toString();
      await tester.pumpWidget(app(views, twitch));
      await tester.pump();

      expect(loaded, [otherKick]);
      final picker = await openPicker(tester);
      expect(picker.channel, otherKick);
      expect(picker.emotes.map((e) => e.code), ['Kappa', 'emote3']);
    });

    testWidgets("follow the send target when it changes", (tester) async {
      final views = simulcast()..sendTarget = otherKick.toString();
      await tester.pumpWidget(app(views, kick));
      await tester.pump();
      views.sendTarget = kick.toString();
      await tester.pump();
      await tester.pump();

      expect(loaded, [otherKick, kick]);
      final picker = await openPicker(tester);
      expect(picker.channel, kick);
      expect(picker.emotes.map((e) => e.code), ['Kappa', 'emote2']);
    });

    testWidgets("are the primary channel's when sending to it and others",
        (tester) async {
      final views = simulcast()..sendTarget = ViewsModel.allChannels;
      await tester.pumpWidget(app(views, kick));
      await tester.pump();

      expect(loaded, [kick]);
      final picker = await openPicker(tester);
      expect(picker.channel, kick);
    });
  });
}
