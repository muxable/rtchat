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

/// A view of [twitch], [kick] and [otherKick], seen by a user signed in as
/// [kick].
ViewsModel simulcast() {
  final views = ViewsModel()..update(FakeUserModel(userChannel: kick));
  return views
    ..showView(views.saveView("Simulcast", [twitch, kick, otherKick]).id);
}

void main() {
  group("send targets", () {
    test("are the channels on the signed-in user's platform", () {
      final views = simulcast();
      expect(views.postableChannels(kick), [kick, otherKick]);
      expect(views.postableChannels(twitch), [twitch]);
      expect(views.postableChannels(null), isEmpty);
    });

    test("default to the first channel the user can post to", () {
      expect(simulcast().sendTargets(kick), [kick]);
    });

    test("can be one channel or all of them", () {
      final views = simulcast();
      views.sendTarget = otherKick.toString();
      expect(views.sendTargets(kick), [otherKick]);
      views.sendTarget = ViewsModel.allChannels;
      expect(views.sendTargets(kick), [kick, otherKick]);
    });

    test("fall back when the chosen channel isn't postable", () {
      final views = simulcast();
      views.sendTarget = twitch.toString();
      expect(views.sendTargets(kick), [kick]);
    });

    test("are remembered per view", () {
      final views = simulcast();
      final id = views.activeView.id;
      views.sendTarget = otherKick.toString();
      views.openChannel(otherKick);
      expect(views.sendTarget, isNull);
      views.showView(id);
      expect(views.sendTarget, otherKick.toString());
    });
  });

  Widget app(ViewsModel views, Channel userChannel) => MultiProvider(
        providers: [
          ChangeNotifierProvider<ViewsModel>.value(value: views),
          ChangeNotifierProvider<UserModel>.value(
              value: FakeUserModel(userChannel: userChannel)),
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
