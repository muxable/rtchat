import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/send_target_picker.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/models/views.dart';

import '../fakes/fake_user_model.dart';

final twitch = Channel(Providers.twitch, '1', 'TwitchMux');
final kick = Channel(Providers.kick, '2', 'KickMux');
final otherKick = Channel(Providers.kick, '3', 'Friend');

/// [twitch], [kick] and [otherKick] shown together, to a user signed in as
/// [kick].
ViewsModel simulcast() {
  final user = FakeUserModel(userChannel: kick);
  final views = ViewsModel()..update(user);
  addTearDown(views.dispose);
  addTearDown(user.dispose);
  return views
    ..openChannel(twitch)
    ..addChannel(kick)
    ..addChannel(otherKick);
}

void main() {
  group("send targets", () {
    test("are the channels on the platforms the user has accounts on", () {
      final views = simulcast();
      expect(views.postableChannels([kick]), [kick, otherKick]);
      expect(views.postableChannels([twitch]), [twitch]);
      expect(views.postableChannels([]), isEmpty);
      // accounts are independent per platform: a twitch account doesn't have
      // to be the twitch channel being shown.
      expect(
          views.postableChannels([Channel(Providers.twitch, '9', 'me'), kick]),
          [twitch, kick, otherKick]);
    });

    test("default to the first channel the user can post to", () {
      expect(simulcast().sendTargets([kick]), [kick]);
    });

    test("can be one channel or all of them", () {
      final views = simulcast();
      views.sendTarget = otherKick.toString();
      expect(views.sendTargets([kick]), [otherKick]);
      views.sendTarget = ViewsModel.allChannels;
      expect(views.sendTargets([kick]), [kick, otherKick]);
    });

    test("fall back when the chosen channel isn't postable", () {
      final views = simulcast();
      views.sendTarget = twitch.toString();
      expect(views.sendTargets([kick]), [kick]);
    });

    test("pick whose emotes are offered", () {
      final views = simulcast();
      expect(views.emoteChannel([kick], twitch), kick);
      views.sendTarget = otherKick.toString();
      expect(views.emoteChannel([kick], kick), otherKick);
      views.sendTarget = ViewsModel.allChannels;
      expect(views.emoteChannel([kick], otherKick), otherKick);
      expect(views.emoteChannel([kick], twitch), kick);
      expect(views.emoteChannel([], twitch), isNull);
    });

    test("are one setting that survives a restart", () {
      final views = simulcast()..sendTarget = ViewsModel.allChannels;
      views.openChannel(otherKick);
      expect(views.sendTarget, ViewsModel.allChannels);
      final restored = ViewsModel.fromJson(views.toJson());
      expect(restored.sendTarget, ViewsModel.allChannels);
      restored.dispose();
    });
  });

  Widget app(ViewsModel views, Channel userChannel) => MultiProvider(
        providers: [
          ChangeNotifierProvider<ViewsModel>.value(value: views),
          ChangeNotifierProvider<UserModel>(
              create: (context) => FakeUserModel(userChannel: userChannel)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Material(child: SendTargetPicker()),
        ),
      );

  testWidgets("hidden when there's only one place to post", (tester) async {
    await tester.pumpWidget(app(simulcast(), twitch));
    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });

  testWidgets("picks all channels from the menu", (tester) async {
    final views = simulcast();
    await tester.pumpWidget(app(views, kick));
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Friend'), findsOneWidget);
    expect(find.text('TwitchMux'), findsNothing);
    await tester.tap(find.text('Send to all channels'));
    await tester.pumpAndSettle();
    expect(views.sendTarget, ViewsModel.allChannels);
    expect(find.byIcon(Icons.all_inclusive), findsOneWidget);
  });
}
