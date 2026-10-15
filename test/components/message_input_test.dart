import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/components/message_input.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/user.dart';

import '../fakes/fake_user_model.dart';

final twitch = Channel(Providers.twitch, '1', 'TwitchMux');
final kick = Channel(Providers.kick, '2', 'KickMux');

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

  late List<Channel> loaded;

  Future<List<Emote>> loadEmotes(Channel channel) async {
    loaded.add(channel);
    return emotesOf(channel);
  }

  setUp(() => loaded = []);

  // the emote picker shows real network images that flutter's image cache
  // keeps.
  final ignoreImages = LeakTesting.settings
      .withIgnored(classes: ['ImageStreamCompleterHandle', '_LiveImage']);

  Widget app(Channel? channel, {Channel? account}) => MultiProvider(
        providers: [
          ChangeNotifierProvider<UserModel>(
              create: (context) => FakeUserModel(userChannel: account)),
          ChangeNotifierProvider<StyleModel>(
              create: (context) => StyleModel.fromJson({})),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MessageInputWidget(
                  key: const ValueKey('input'),
                  channel: channel,
                  loadEmotes: loadEmotes),
            ),
          ),
        ),
      );

  Future<EmotePickerWidget> openPicker(WidgetTester tester) async {
    await tester.tap(find.byType(IconButton).first);
    await tester.pump();
    return tester.widget<EmotePickerWidget>(find.byType(EmotePickerWidget));
  }

  group("emotes", () {
    testWidgets("are the channel's messages are sent to",
        experimentalLeakTesting: ignoreImages, (tester) async {
      await tester.pumpWidget(app(kick, account: kick));
      await tester.pump();

      expect(loaded, [kick]);
      final picker = await openPicker(tester);
      expect(picker.channel, kick);
      expect(picker.emotes.map((e) => e.code), ['Kappa', 'emote2']);
    });

    testWidgets("follow the channel when it changes",
        experimentalLeakTesting: ignoreImages, (tester) async {
      await tester.pumpWidget(app(twitch, account: twitch));
      await tester.pump();
      await tester.pumpWidget(app(kick, account: twitch));
      await tester.pump();

      expect(loaded, [twitch, kick]);
      final picker = await openPicker(tester);
      expect(picker.channel, kick);
      expect(picker.emotes.map((e) => e.code), ['Kappa', 'emote2']);
    });

    testWidgets("aren't reloaded while the channel stays the same",
        experimentalLeakTesting: ignoreImages, (tester) async {
      await tester.pumpWidget(app(kick, account: kick));
      await tester.pump();
      await tester.pumpWidget(
          app(Channel(kick.provider, kick.channelId, 'new'), account: kick));
      await tester.pump();

      expect(loaded, [kick]);
    });
  });

  group("without a channel to send to", () {
    testWidgets("the input is disabled with a hint naming the account",
        experimentalLeakTesting: ignoreImages, (tester) async {
      await tester.pumpWidget(app(null, account: twitch));
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
      expect(find.text("Your Twitch account can't chat here"), findsOneWidget);
      for (final button
          in tester.widgetList<IconButton>(find.byType(IconButton))) {
        expect(button.onPressed, isNull);
      }
      expect(loaded, isEmpty);
    });

    testWidgets("the input is enabled again once there is one",
        experimentalLeakTesting: ignoreImages, (tester) async {
      await tester.pumpWidget(app(null, account: twitch));
      await tester.pump();
      await tester.pumpWidget(app(twitch, account: twitch));
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isTrue);
      expect(find.text("Your Twitch account can't chat here"), findsNothing);
      expect(loaded, [twitch]);
    });
  });
}
