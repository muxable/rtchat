import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/channels.dart';

import '../fakes/fake_accounts.dart';

final twitch = Channel(Providers.twitch, '1', 'muxfd');
final kick = Channel(Providers.kick, '2', 'muxfd');

/// Lets the slots' streams deliver.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeSlots slots;
  late AccountsModel model;

  setUp(() async {
    slots = FakeSlots();
    model = slots.model();
    await settle();
  });

  tearDown(() => model.dispose());

  List<String> appNames() => [for (final a in model.accounts) a.app.name];

  test('starts signed out once every slot has loaded', () async {
    expect(model.isLoading, isFalse);
    expect(model.accounts, isEmpty);
  });

  test('the first account goes in [DEFAULT]', () async {
    await model.signIn(
      Providers.twitch,
      slots.backend.account('twitch-user', twitch),
    );
    await settle();

    expect(appNames(), ['[DEFAULT]']);
    expect(model.accounts.single.channel, twitch);
    expect(model.accounts.single.provider, Providers.twitch);
    expect(model.accounts.single.user.uid, 'twitch-user');
  });

  test('a second provider goes in its own slot and keeps the first', () async {
    await model.signIn(
      Providers.twitch,
      slots.backend.account('twitch-user', twitch),
    );
    await model.signIn(
      Providers.kick,
      slots.backend.account('kick-user', kick),
    );
    await settle();

    expect(appNames(), ['[DEFAULT]', 'account-kick']);
    expect([for (final a in model.accounts) a.channel], [twitch, kick]);
    expect(slots.primary.user?.uid, 'twitch-user');
    expect(slots.extra[Providers.kick]!.user?.uid, 'kick-user');
    expect(slots.extra[Providers.twitch]!.user, isNull);
  });

  test('signing in on a provider that has an account replaces it', () async {
    await model.signIn(
      Providers.twitch,
      slots.backend.account('twitch-user', twitch),
    );
    await model.signIn(
      Providers.kick,
      slots.backend.account('kick-user', kick),
    );
    await settle();

    // in [DEFAULT].
    final otherTwitch = Channel(Providers.twitch, '3', 'other');
    await model.signIn(
      Providers.twitch,
      slots.backend.account('twitch-2', otherTwitch),
    );
    // in a named slot.
    final otherKick = Channel(Providers.kick, '4', 'other');
    await model.signIn(
      Providers.kick,
      slots.backend.account('kick-2', otherKick),
    );
    await settle();

    expect(appNames(), ['[DEFAULT]', 'account-kick']);
    expect(
      [for (final a in model.accounts) a.channel],
      [otherTwitch, otherKick],
    );
    expect(slots.extra[Providers.twitch]!.user, isNull);
  });

  test('signing out one account leaves the others', () async {
    await model.signIn(
      Providers.twitch,
      slots.backend.account('twitch-user', twitch),
    );
    await model.signIn(
      Providers.kick,
      slots.backend.account('kick-user', kick),
    );
    await settle();

    await model.signOut(model.accountFor(twitch)!);
    await settle();

    expect(appNames(), ['account-kick']);
    expect(model.accountFor(twitch), isNull);
    expect(model.accountFor(kick)?.user.uid, 'kick-user');

    // the next account fills [DEFAULT] again.
    await model.signIn(
      Providers.twitch,
      slots.backend.account('twitch-user', twitch),
    );
    await settle();
    expect(appNames(), ['[DEFAULT]', 'account-kick']);
  });

  test('signing out of all accounts empties every slot', () async {
    await model.signIn(
      Providers.twitch,
      slots.backend.account('twitch-user', twitch),
    );
    await model.signIn(
      Providers.kick,
      slots.backend.account('kick-user', kick),
    );
    await settle();

    await model.signOutAll();
    await settle();

    expect(model.accounts, isEmpty);
    expect(slots.primary.user, isNull);
    expect(slots.extra.values.map((slot) => slot.user), everyElement(isNull));
  });

  test('restores every account after a restart', () async {
    await model.signIn(
      Providers.twitch,
      slots.backend.account('twitch-user', twitch),
    );
    await model.signIn(
      Providers.kick,
      slots.backend.account('kick-user', kick),
    );
    await settle();
    model.dispose();

    model = slots.model();
    expect(model.isLoading, isTrue);
    await settle();

    expect(model.isLoading, isFalse);
    expect(appNames(), ['[DEFAULT]', 'account-kick']);
    expect([for (final a in model.accounts) a.channel], [twitch, kick]);
  });

  test('a restored account in a named slot is replaced in place', () async {
    // e.g. [DEFAULT] was signed out before the restart.
    slots.extra[Providers.kick]!.user = FakeUser('kick-user');
    slots.backend.profiles['kick-user'] = kick;
    model.dispose();
    model = slots.model();
    await settle();
    expect(appNames(), ['account-kick']);

    final otherKick = Channel(Providers.kick, '4', 'other');
    await model.signIn(
      Providers.kick,
      slots.backend.account('kick-2', otherKick),
    );
    await settle();

    expect(appNames(), ['account-kick']);
    expect(model.accounts.single.channel, otherKick);
    expect(slots.primary.user, isNull);
  });

  test('accountFor only matches the account\'s own channel', () async {
    await model.signIn(
      Providers.twitch,
      slots.backend.account('twitch-user', twitch),
    );
    await settle();

    expect(model.accountFor(twitch)?.app.name, '[DEFAULT]');
    expect(model.accountFor(Channel(Providers.twitch, '9', 'someone')), isNull);
    expect(model.accountFor(kick), isNull);
  });

  test('a user without a channel in their profile isn\'t an account', () async {
    slots.backend.tokens['token-nobody'] = 'nobody';
    await model.signIn(Providers.twitch, 'token-nobody');
    await settle();

    expect(model.isLoading, isFalse);
    expect(model.accounts, isEmpty);
  });
}
