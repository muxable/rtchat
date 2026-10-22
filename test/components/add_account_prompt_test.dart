import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/add_account_prompt.dart';
import 'package:rtchat/components/auth/twitch.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';

import '../fakes/fake_accounts.dart';
import '../fakes/fake_user_model.dart';

final twitch = Channel(Providers.twitch, '1', 'TwitchMux');
final kick = Channel(Providers.kick, '2', 'KickMux');

const kickPrompt =
    'Also stream on Kick? Add your Kick account to chat and moderate both.';

// the twitch icon is an image that flutter's image cache keeps.
final ignoreImages = LeakTesting.settings.withIgnored(
  classes: ['ImageStreamCompleterHandle', '_LiveImage'],
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required UserModel userModel,
    required LayoutModel layoutModel,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserModel>.value(value: userModel),
          ChangeNotifierProvider<LayoutModel>.value(value: layoutModel),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AddAccountPrompt()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  LayoutModel layout(Map<String, dynamic> json) {
    final model = LayoutModel.fromJson(json);
    addTearDown(model.dispose);
    return model;
  }

  testWidgets("offers the missing provider once, until dismissed", (
    tester,
  ) async {
    final userModel = FakeUserModel(userChannel: twitch);
    addTearDown(userModel.dispose);
    final layoutModel = layout({});
    await pump(tester, userModel: userModel, layoutModel: layoutModel);

    expect(find.text(kickPrompt), findsOneWidget);
    final button = tester.widget<SignInButton>(find.byType(SignInButton));
    expect(button.provider, Providers.kick);
    expect(button.target, SignInTarget.addAccount);
    expect(find.text('Add Kick account'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text(kickPrompt), findsNothing);
    expect(layoutModel.isAddAccountPromptDismissed, isTrue);

    // the dismissal is saved, so it isn't shown again after a restart.
    await pump(
      tester,
      userModel: userModel,
      layoutModel: layout(layoutModel.toJson()),
    );

    expect(find.text(kickPrompt), findsNothing);
    expect(find.byType(SignInButton), findsNothing);
  });

  testWidgets(
    "names the missing provider of a kick-only user",
    experimentalLeakTesting: ignoreImages,
    (tester) async {
      final userModel = FakeUserModel(userChannel: kick);
      addTearDown(userModel.dispose);
      await pump(tester, userModel: userModel, layoutModel: layout({}));

      expect(
        find.text(
          'Also stream on Twitch? '
          'Add your Twitch account to chat and moderate both.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<SignInButton>(find.byType(SignInButton)).provider,
        Providers.twitch,
      );
    },
  );

  testWidgets("skipped when every provider has an account", (tester) async {
    final userModel = FakeUserModel(
      accounts: [fakeAccount(twitch, appName: '[DEFAULT]'), fakeAccount(kick)],
    );
    addTearDown(userModel.dispose);
    await pump(tester, userModel: userModel, layoutModel: layout({}));

    expect(find.byType(MaterialBanner), findsNothing);
    expect(find.byType(SignInButton), findsNothing);
  });

  testWidgets("skipped when signed out", (tester) async {
    final userModel = FakeUserModel();
    addTearDown(userModel.dispose);
    await pump(tester, userModel: userModel, layoutModel: layout({}));

    expect(find.byType(MaterialBanner), findsNothing);
    expect(find.byType(SignInButton), findsNothing);
  });
}
