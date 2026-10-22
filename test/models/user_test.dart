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
      expect(user.userChannel, twitch);
      expect(user.isOwnChannel(twitch), isTrue);
      expect(user.isOwnChannel(kick), isFalse);
      expect(user.accountFor(twitch)?.app.name, '[DEFAULT]');
      expect(Api.forAccount(user.accountFor(twitch)!).app.name, '[DEFAULT]');
      expect(reports.last.single.user.uid, 'twitch-user');

      await user.signOut();
      await settle();

      expect(user.isSignedIn(), isFalse);
      expect(user.userChannels, isEmpty);
      expect(user.userChannel, isNull);
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
        expect(user.userChannel, twitch);
        expect(user.user?.uid, 'twitch-user');
        expect(user.isOwnChannel(twitch), isTrue);
        expect(user.isOwnChannel(kick), isTrue);
        expect(
          user.isOwnChannel(Channel(Providers.kick, '3', 'someone')),
          isFalse,
        );

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
