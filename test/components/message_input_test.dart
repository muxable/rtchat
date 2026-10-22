import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/components/message_input.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/models/views.dart';

import '../fakes/fake_accounts.dart';
import '../fakes/fake_api.dart';
import '../fakes/fake_user_model.dart';

final twitch = Channel(Providers.twitch, '1', 'TwitchMux');
final kick = Channel(Providers.kick, '2', 'KickMux');

List<Emote> emotesOf(Channel channel) => [
  Emote(
    provider: 'twitch',
    category: null,
    id: 'global',
    code: 'Kappa',
    imageUrl: 'https://example.com/kappa.png',
  ),
  Emote(
    provider: '7tv',
    category: channel.displayName,
    id: channel.channelId,
    code: 'emote${channel.channelId}',
    imageUrl: 'https://example.com/${channel.channelId}.png',
  ),
];

void main() {
  setUp(() {
    // the input listens for text shared to the app.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.rtirl.chat/share'),
          (call) async => '',
        );
  });

  late List<Channel> loaded;

  Future<List<Emote>> loadEmotes(Channel channel) async {
    loaded.add(channel);
    return emotesOf(channel);
  }

  setUp(() => loaded = []);

  // the emote picker shows real network images that flutter's image cache
  // keeps.
  final ignoreImages = LeakTesting.settings.withIgnored(
    classes: ['ImageStreamCompleterHandle', '_LiveImage'],
  );

  Widget app(Channel? channel, {Channel? account, List<Account>? accounts}) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserModel>(
            create:
                (context) =>
                    FakeUserModel(userChannel: account, accounts: accounts),
          ),
          ChangeNotifierProvider<StyleModel>(
            create: (context) => StyleModel.fromJson({}),
          ),
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
                loadEmotes: loadEmotes,
              ),
            ),
          ),
        ),
      );

  // wired up like the home screen: sends to the channel picked in [views].
  Widget pickerApp(
    ViewsModel views,
    List<Account> accounts, {
    Key key = const ValueKey('input'),
  }) => MultiProvider(
    providers: [
      ChangeNotifierProvider<UserModel>(
        create: (context) => FakeUserModel(accounts: accounts),
      ),
      ChangeNotifierProvider<StyleModel>(
        create: (context) => StyleModel.fromJson({}),
      ),
      ChangeNotifierProvider<ViewsModel>.value(value: views),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Consumer<ViewsModel>(
            builder:
                (context, views, child) => MessageInputWidget(
                  key: key,
                  channel: views.sendChannel,
                  channels: views.sendableChannels,
                  onChannelSelected: (channel) => views.sendChannel = channel,
                  loadEmotes: loadEmotes,
                ),
          ),
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
    testWidgets(
      "are the channel's messages are sent to",
      experimentalLeakTesting: ignoreImages,
      (tester) async {
        await tester.pumpWidget(app(kick, account: kick));
        await tester.pump();

        expect(loaded, [kick]);
        final picker = await openPicker(tester);
        expect(picker.channel, kick);
        expect(picker.emotes.map((e) => e.code), ['Kappa', 'emote2']);
      },
    );

    testWidgets(
      "follow the channel when it changes",
      experimentalLeakTesting: ignoreImages,
      (tester) async {
        await tester.pumpWidget(app(twitch, account: twitch));
        await tester.pump();
        await tester.pumpWidget(app(kick, account: twitch));
        await tester.pump();

        expect(loaded, [twitch, kick]);
        final picker = await openPicker(tester);
        expect(picker.channel, kick);
        expect(picker.emotes.map((e) => e.code), ['Kappa', 'emote2']);
      },
    );

    testWidgets(
      "aren't reloaded while the channel stays the same",
      experimentalLeakTesting: ignoreImages,
      (tester) async {
        await tester.pumpWidget(app(kick, account: kick));
        await tester.pump();
        await tester.pumpWidget(
          app(Channel(kick.provider, kick.channelId, 'new'), account: kick),
        );
        await tester.pump();

        expect(loaded, [kick]);
      },
    );
  });

  group("without a channel to send to", () {
    testWidgets(
      "the input is disabled with a hint naming the account",
      experimentalLeakTesting: ignoreImages,
      (tester) async {
        await tester.pumpWidget(app(null, account: twitch));
        await tester.pump();

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.enabled, isFalse);
        expect(
          find.text("Your Twitch account can't chat here"),
          findsOneWidget,
        );
        for (final button in tester.widgetList<IconButton>(
          find.byType(IconButton),
        )) {
          expect(button.onPressed, isNull);
        }
        expect(loaded, isEmpty);
      },
    );

    testWidgets(
      "the input is enabled again once there is one",
      experimentalLeakTesting: ignoreImages,
      (tester) async {
        await tester.pumpWidget(app(null, account: twitch));
        await tester.pump();
        await tester.pumpWidget(app(twitch, account: twitch));
        await tester.pump();

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.enabled, isTrue);
        expect(find.text("Your Twitch account can't chat here"), findsNothing);
        expect(loaded, [twitch]);
      },
    );
  });

  group("sending", () {
    late FakeFunctions twitchApi, kickApi;
    late List<Account> accounts;

    setUp(() {
      final twitchAccount = fakeAccount(twitch, appName: '[DEFAULT]');
      final kickAccount = fakeAccount(kick);
      twitchApi = fakeApiFor(twitchAccount);
      kickApi = fakeApiFor(kickAccount);
      accounts = [twitchAccount, kickAccount];
    });

    tearDown(Api.debugReset);

    Future<void> send(WidgetTester tester, Channel channel) async {
      await tester.pumpWidget(app(channel, accounts: accounts));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets(
      "goes through the channel's own account",
      experimentalLeakTesting: ignoreImages,
      (tester) async {
        await send(tester, kick);

        expect(twitchApi.calls, isEmpty);
        expect(kickApi.calls.single.name, 'send');
        expect(kickApi.calls.single.data, {
          'provider': 'kick',
          'channelId': '2',
          'message': 'hello',
        });
      },
    );

    testWidgets(
      "to someone else's channel goes through its provider's account",
      experimentalLeakTesting: ignoreImages,
      (tester) async {
        await send(tester, Channel(Providers.twitch, '99', 'someone'));

        expect(kickApi.calls, isEmpty);
        expect(twitchApi.calls.single.name, 'send');
        expect(twitchApi.calls.single.data['channelId'], '99');
      },
    );
  });

  group("destination picker", () {
    late FakeFunctions twitchApi, kickApi;
    late List<Account> accounts;
    late ViewsModel views;

    setUp(() {
      final twitchAccount = fakeAccount(twitch, appName: '[DEFAULT]');
      final kickAccount = fakeAccount(kick);
      twitchApi = fakeApiFor(twitchAccount);
      kickApi = fakeApiFor(kickAccount);
      accounts = [twitchAccount, kickAccount];
      views = ViewsModel()..update(FakeUserModel(accounts: accounts));
    });

    tearDown(() {
      views.dispose();
      Api.debugReset();
    });

    Finder picker() => find.byType(PopupMenuButton<Channel>);

    Channel? picked(WidgetTester tester) =>
        tester.widget<PopupMenuButton<Channel>>(picker()).initialValue;

    Future<void> pick(WidgetTester tester, String name) async {
      await tester.tap(picker());
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    Future<void> send(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(seconds: 1));
    }

    int? maxLength(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).maxLength;

    testWidgets(
      "is hidden with one channel to send to",
      experimentalLeakTesting: ignoreImages,
      (tester) async {
        views.removeChannel(kick);
        await tester.pumpWidget(pickerApp(views, accounts));
        await tester.pump();

        expect(picker(), findsNothing);
        expect(find.textContaining('Send a message to'), findsNothing);
      },
    );

    testWidgets(
      "shows the first channel until another is picked",
      experimentalLeakTesting: ignoreImages,
      (tester) async {
        await tester.pumpWidget(pickerApp(views, accounts));
        await tester.pump();

        expect(picked(tester), twitch);
        expect(find.text('Send a message to TwitchMux...'), findsOneWidget);
        expect(maxLength(tester), isNull);
        await send(tester, 'hello');

        expect(kickApi.calls, isEmpty);
        expect(twitchApi.calls.single.data, {
          'provider': 'twitch',
          'channelId': '1',
          'message': 'hello',
        });
      },
    );

    testWidgets(
      "sends only to the channel picked, with its emotes and limit",
      experimentalLeakTesting: ignoreImages,
      (tester) async {
        await tester.pumpWidget(pickerApp(views, accounts));
        await tester.pump();
        await pick(tester, 'KickMux');

        expect(picked(tester), kick);
        expect(find.text('Send a message to KickMux...'), findsOneWidget);
        expect(maxLength(tester), 500);
        expect(loaded, [twitch, kick]);
        final emotes = await openPicker(tester);
        expect(emotes.channel, kick);
        expect(emotes.emotes.map((e) => e.code), ['Kappa', 'emote2']);
        await tester.tap(find.byIcon(Icons.keyboard_rounded));
        await tester.pump();

        await send(tester, 'hello');
        expect(twitchApi.calls, isEmpty);
        expect(kickApi.calls.single.data, {
          'provider': 'kick',
          'channelId': '2',
          'message': 'hello',
        });
      },
    );

    testWidgets(
      "slash commands go to the channel picked",
      experimentalLeakTesting: ignoreImages,
      (tester) async {
        await tester.pumpWidget(pickerApp(views, accounts));
        await tester.pump();
        await pick(tester, 'KickMux');
        await send(tester, '/slow');

        expect(twitchApi.calls, isEmpty);
        expect(kickApi.calls.single.data['message'], '/slow');
      },
    );

    testWidgets(
      "remembers the channel picked",
      experimentalLeakTesting: ignoreImages,
      (tester) async {
        await tester.pumpWidget(pickerApp(views, accounts));
        await tester.pump();
        await pick(tester, 'KickMux');
        // a new input, e.g. after switching layouts.
        await tester.pumpWidget(
          pickerApp(views, accounts, key: const ValueKey('other')),
        );
        await tester.pump();

        expect(picked(tester), kick);
        await send(tester, 'hello');
        expect(twitchApi.calls, isEmpty);
        expect(kickApi.calls.single.name, 'send');
      },
    );
  });
}
