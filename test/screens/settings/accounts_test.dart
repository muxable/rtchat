import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/auth/twitch.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/screens/settings/accounts.dart';

import '../../fakes/fake_accounts.dart';

final twitch = Channel(Providers.twitch, '1', 'TwitchMux');
final kick = Channel(Providers.kick, '2', 'KickMux');

// the avatars and the twitch icon are images that flutter's image cache keeps.
final ignoreImages = LeakTesting.settings.withIgnored(
  classes: ['ImageStreamCompleterHandle', '_LiveImage'],
);

void main() {
  late FakeSlots slots;
  late AccountsModel model;

  setUp(() {
    slots = FakeSlots();
  });

  Future<void> pump(WidgetTester tester) async {
    model = slots.model();
    addTearDown(model.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AccountsModel>.value(
        value: model,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> signOutWith(WidgetTester tester, Finder button) async {
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    "signed out, offers to add an account on every provider",
    experimentalLeakTesting: ignoreImages,
    (tester) async {
      await pump(tester);

      for (final provider in Providers.all) {
        final button = find.widgetWithText(
          SignInButton,
          'Add ${providerName(provider)} account',
        );
        expect(button, findsOneWidget);
        final widget = tester.widget<SignInButton>(button);
        expect(widget.provider, provider);
        expect(widget.target, SignInTarget.addAccount);
      }
      expect(find.text('Sign out of all accounts'), findsNothing);
    },
  );

  testWidgets(
    "lists the accounts and offers the missing provider",
    experimentalLeakTesting: ignoreImages,
    (tester) async {
      await slots.primary.signInWithCustomToken(
        slots.backend.account('t', twitch),
      );
      await pump(tester);

      expect(find.text('TwitchMux'), findsOneWidget);
      expect(find.text('Twitch'), findsOneWidget);
      expect(find.text('Add Twitch account'), findsNothing);
      expect(find.text('Add Kick account'), findsOneWidget);
      expect(find.text('Sign out of all accounts'), findsOneWidget);

      // adding kick goes in its own slot and replaces the add button.
      await model.signIn(Providers.kick, slots.backend.account('k', kick));
      await tester.pumpAndSettle();

      expect(find.text('TwitchMux'), findsOneWidget);
      expect(find.text('KickMux'), findsOneWidget);
      expect(find.byType(SignInButton), findsNothing);
      expect(slots.extra[Providers.kick]!.user?.uid, 'k');
    },
  );

  testWidgets(
    "signs out of one account, keeping the other",
    experimentalLeakTesting: ignoreImages,
    (tester) async {
      await slots.primary.signInWithCustomToken(
        slots.backend.account('t', twitch),
      );
      await slots.extra[Providers.kick]!.signInWithCustomToken(
        slots.backend.account('k', kick),
      );
      await pump(tester);

      final kickTile = find.widgetWithText(ListTile, 'KickMux');
      await tester.tap(
        find.descendant(
          of: kickTile,
          matching: find.byIcon(Icons.logout_outlined),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sign out of KickMux on Kick?'), findsOneWidget);

      // cancelling keeps it.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('KickMux'), findsOneWidget);

      await signOutWith(
        tester,
        find.descendant(
          of: kickTile,
          matching: find.byIcon(Icons.logout_outlined),
        ),
      );

      expect(find.text('KickMux'), findsNothing);
      expect(find.text('TwitchMux'), findsOneWidget);
      expect(find.text('Add Kick account'), findsOneWidget);
      expect(slots.primary.user?.uid, 't');
    },
  );

  testWidgets(
    "signs out of all accounts",
    experimentalLeakTesting: ignoreImages,
    (tester) async {
      await slots.primary.signInWithCustomToken(
        slots.backend.account('t', twitch),
      );
      await slots.extra[Providers.kick]!.signInWithCustomToken(
        slots.backend.account('k', kick),
      );
      await pump(tester);

      await signOutWith(tester, find.text('Sign out of all accounts'));

      expect(model.accounts, isEmpty);
      expect(find.text('TwitchMux'), findsNothing);
      expect(find.text('KickMux'), findsNothing);
      expect(find.text('Add Twitch account'), findsOneWidget);
      expect(find.text('Add Kick account'), findsOneWidget);
      expect(find.text('Sign out of all accounts'), findsNothing);
    },
  );
}
