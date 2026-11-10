import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/user.dart';

import '../fakes/fake_accounts.dart';

/// Lets the slots' streams deliver.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  group("normalizeLanguageCode", () {
    test("supported codes map to themselves", () {
      for (final code in ["en", "es", "fr", "de", "ja", "ko", "zh", "uk"]) {
        expect(UserModel.normalizeLanguageCode(code), code);
      }
    });

    test("zh-Hant maps to zh", () {
      expect(UserModel.normalizeLanguageCode("zh-Hant"), "zh");
    });

    test("unknown, null and differently-cased codes fall back to en", () {
      expect(UserModel.normalizeLanguageCode("xx"), "en");
      expect(UserModel.normalizeLanguageCode(null), "en");
      expect(UserModel.normalizeLanguageCode("FR"), "en");
      expect(UserModel.normalizeLanguageCode("other"), "en");
    });
  });

  group("accounts", () {
    final twitch = Channel(Providers.twitch, '1', 'muxfd');
    final kick = Channel(Providers.kick, '2', 'muxfd');

    late FakeSlots slots;
    late AccountsModel accounts;
    late UserModel user;
    late List<List<Account>> reports;

    setUp(() async {
      slots = FakeSlots();
      accounts = slots.model();
      reports = [];
      user = UserModel(accounts, report: reports.add);
      await settle();
    });

    tearDown(() {
      user.dispose();
      accounts.dispose();
    });

    test("a single account behaves as before", () async {
      expect(user.isLoading, isFalse);
      expect(user.isSignedIn(), isFalse);

      await user.signIn(
        Providers.twitch,
        slots.backend.account('twitch-user', twitch),
      );
      await settle();

      expect(user.isSignedIn(), isTrue);
      expect(user.user?.uid, 'twitch-user');
      expect(user.userChannels, [twitch]);
      expect(user.isOwnChannel(twitch), isTrue);
      expect(user.isOwnChannel(kick), isFalse);
      expect(user.accountFor(twitch)?.app.name, '[DEFAULT]');
      expect(Api.forAccount(user.accountFor(twitch)!).app.name, '[DEFAULT]');
      expect(reports.last.single.user.uid, 'twitch-user');

      await user.signOut();
      await settle();

      expect(user.isSignedIn(), isFalse);
      expect(user.userChannels, isEmpty);
      expect(reports.last, isEmpty);
    });

    test(
      "a twitch and kick user has both channels, each with its own api",
      () async {
        await user.signIn(
          Providers.twitch,
          slots.backend.account('twitch-user', twitch),
        );
        await user.signIn(
          Providers.kick,
          slots.backend.account('kick-user', kick),
        );
        await settle();

        expect(user.userChannels, [twitch, kick]);
        expect(user.user?.uid, 'twitch-user');
        expect(user.isOwnChannel(twitch), isTrue);
        expect(user.isOwnChannel(kick), isTrue);
        expect(
          user.isOwnChannel(Channel(Providers.kick, '3', 'someone')),
          isFalse,
        );

        // mentions of either account are of the user.
        expect(user.isOwnName(twitch.displayName.toUpperCase()), isTrue);
        expect(user.isOwnName(kick.displayName), isTrue);
        expect(user.isOwnName('someone'), isFalse);
        // the activity feed is the first channel's that has one.
        expect(user.activityFeedUri?.host, 'dashboard.twitch.tv');

        final twitchApi = Api.forAccount(user.accountFor(twitch)!);
        final kickApi = Api.forAccount(user.accountFor(kick)!);
        expect(twitchApi.app.name, "[DEFAULT]");
        expect(kickApi.app.name, "account-kick");
        expect(twitchApi, isNot(same(kickApi)));

        // analytics is told about the first account and every provider.
        expect(reports.last.first.user.uid, 'twitch-user');
        expect(reports.last.map((account) => account.provider), [
          Providers.twitch,
          Providers.kick,
        ]);
      },
    );

    test("acts on a provider as its account", () async {
      await user.signIn(
        Providers.twitch,
        slots.backend.account('twitch-user', twitch),
      );
      await user.signIn(
        Providers.kick,
        slots.backend.account('kick-user', kick),
      );
      await settle();

      // someone else's channel is acted on as the account on its provider.
      final other = Channel(Providers.kick, '3', 'someone');
      expect(user.accountFor(other), isNull);
      expect(user.accountOn(other.provider)?.user.uid, 'kick-user');
      expect(user.apiOn(Providers.kick).app.name, 'account-kick');
      expect(user.apiOn(Providers.twitch).app.name, '[DEFAULT]');
    });

    test("reads on a provider without an account as another one", () async {
      await user.signIn(
        Providers.twitch,
        slots.backend.account('twitch-user', twitch),
      );
      await user.signIn(
        Providers.kick,
        slots.backend.account('kick-user', kick),
      );
      await settle();
      await accounts.signOut(user.accountOn(Providers.twitch)!);
      await settle();

      // [DEFAULT] is signed out, so reads go through kick's slot.
      expect(user.accountOn(Providers.twitch), isNull);
      expect(user.apiOn(Providers.twitch).app.name, 'account-kick');
    });

    test("notifies when an account changes", () async {
      var notified = 0;
      user.addListener(() => notified++);
      await user.signIn(
        Providers.kick,
        slots.backend.account('kick-user', kick),
      );
      await settle();

      expect(notified, greaterThan(0));
      expect(user.userChannels, [kick]);
    });
  });
}
