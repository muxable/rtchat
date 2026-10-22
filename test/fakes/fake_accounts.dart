import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/channels.dart';

class FakeFirebaseApp extends Fake implements FirebaseApp {
  @override
  final String name;

  FakeFirebaseApp(this.name);
}

class FakeUser extends Fake implements User {
  @override
  final String uid;

  FakeUser(this.uid);
}

/// Stands in for the auth backend: which user each custom token signs in,
/// and the channel in each user's profile.
class FakeAuthBackend {
  final tokens = <String, String>{};
  final profiles = <String, Channel>{};

  /// Registers an account on [channel], returning its custom token.
  String account(String uid, Channel channel) {
    profiles[uid] = channel;
    tokens['token-$uid'] = uid;
    return 'token-$uid';
  }
}

/// An [AccountSlot] whose session lives in [user], so it survives a new
/// [AccountsModel] the way Firebase's persisted session survives a restart.
class FakeAccountSlot implements AccountSlot {
  @override
  final FirebaseApp app;
  final FakeAuthBackend backend;
  User? user;
  final _changes = StreamController<User?>.broadcast();

  FakeAccountSlot(String name, this.backend) : app = FakeFirebaseApp(name);

  @override
  Stream<User?> authStateChanges() async* {
    yield user;
    yield* _changes.stream;
  }

  void _set(User? user) {
    this.user = user;
    _changes.add(user);
  }

  @override
  Future<void> signInWithCustomToken(String token) async =>
      _set(FakeUser(backend.tokens[token]!));

  @override
  Future<void> signOut() async => _set(null);

  @override
  Stream<Channel?> channelOf(User user) async* {
    yield backend.profiles[user.uid];
  }
}

/// The [DEFAULT] slot and one named slot per provider, sharing a backend.
class FakeSlots {
  final backend = FakeAuthBackend();
  late final primary = FakeAccountSlot('[DEFAULT]', backend);
  late final extra = {
    for (final provider in Providers.all)
      provider: FakeAccountSlot(accountAppName(provider), backend),
  };

  AccountsModel model() => AccountsModel(primary: primary, extra: extra);
}

/// A signed-in account on [channel], for tests that don't need slots.
Account fakeAccount(Channel channel, {String? appName, String? uid}) => Account(
  app: FakeFirebaseApp(appName ?? accountAppName(channel.provider)),
  user: FakeUser(uid ?? '${channel.provider}-user'),
  channel: channel,
);
