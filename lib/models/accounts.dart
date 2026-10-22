import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/firebase_options.dart';
import 'package:rtchat/models/adapters/profiles.dart';
import 'package:rtchat/models/channels.dart';

/// The name of the [FirebaseApp] that holds an extra [provider] account.
String accountAppName(String provider) => 'account-$provider';

/// An account the app is signed in to. Each one is its own Firebase user in
/// its own [FirebaseApp], so calls made through [app] act as that account.
class Account {
  final FirebaseApp app;
  final User user;

  /// The account's own channel, from its profile.
  final Channel channel;

  const Account({required this.app, required this.user, required this.channel});

  String get provider => channel.provider;

  @override
  String toString() => 'Account(${app.name}, $channel)';
}

/// A [FirebaseApp] that an account can be signed in on.
abstract class AccountSlot {
  FirebaseApp get app;

  /// Emits the signed-in user on listen, then on every change.
  Stream<User?> authStateChanges();

  Future<void> signInWithCustomToken(String token);

  Future<void> signOut();

  /// The channel in [user]'s profile. Profiles are owner-only, so this is
  /// read as [user], through [app].
  Stream<Channel?> channelOf(User user);
}

class FirebaseAccountSlot implements AccountSlot {
  @override
  final FirebaseApp app;

  FirebaseAccountSlot(this.app);

  FirebaseAuth get _auth => FirebaseAuth.instanceFor(app: app);

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<void> signInWithCustomToken(String token) =>
      _auth.signInWithCustomToken(token);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Stream<Channel?> channelOf(User user) =>
      ProfilesAdapter.forApp(app).getChannel(userId: user.uid);
}

class _SlotState {
  final AccountSlot slot;
  StreamSubscription<void>? authSubscription;
  StreamSubscription<void>? profileSubscription;
  User? user;
  Channel? channel;
  bool isLoading = true;

  _SlotState(this.slot);

  Account? get account {
    final user = this.user, channel = this.channel;
    if (user == null || channel == null) {
      return null;
    }
    return Account(app: slot.app, user: user, channel: channel);
  }
}

/// The accounts the app is signed in to, at most one per provider.
///
/// [DEFAULT] holds the first account, as it did before there could be more
/// than one, and each provider has a named `account-{provider}` app for an
/// extra account. Firebase keeps each app's session separately, so every
/// account stays signed in across restarts.
class AccountsModel extends ChangeNotifier {
  final AccountSlot _primary;
  final Map<String, AccountSlot> _extra;
  late final List<_SlotState> _slots;
  final _loaded = Completer<void>();

  /// [primary] is the [DEFAULT] slot and [extra] the named slot for each
  /// provider.
  AccountsModel(
      {required AccountSlot primary, required Map<String, AccountSlot> extra})
      : _primary = primary,
        _extra = extra {
    _slots = [
      _SlotState(primary),
      for (final slot in extra.values) _SlotState(slot)
    ];
    for (final state in _slots) {
      state.authSubscription =
          state.slot.authStateChanges().listen((user) => _onUser(state, user));
    }
  }

  /// The slots on the apps from [initializeApps].
  AccountsModel.fromFirebase()
      : this(primary: FirebaseAccountSlot(Firebase.app()), extra: {
          for (final provider in Providers.all)
            provider:
                FirebaseAccountSlot(Firebase.app(accountAppName(provider))),
        });

  /// Initializes the named app for each provider. [DEFAULT] must already be
  /// initialized.
  static Future<List<FirebaseApp>> initializeApps() async {
    final apps = <FirebaseApp>[];
    for (final provider in Providers.all) {
      final app = await Firebase.initializeApp(
          name: accountAppName(provider),
          options: DefaultFirebaseOptions.currentPlatform);
      // like [DEFAULT]'s, these are only read as event streams.
      FirebaseFirestore.instanceFor(app: app).settings =
          const Settings(persistenceEnabled: false);
      apps.add(app);
    }
    return apps;
  }

  void _onUser(_SlotState state, User? user) {
    state.profileSubscription?.cancel();
    state.user = user;
    state.channel = null;
    if (user == null) {
      _setLoaded(state);
      return;
    }
    state.profileSubscription = state.slot.channelOf(user).listen((channel) {
      state.channel = channel;
      _setLoaded(state);
    }, onError: (Object error) {
      // without a readable profile, the user isn't a usable account.
      state.channel = null;
      _setLoaded(state);
    });
  }

  void _setLoaded(_SlotState state) {
    state.isLoading = false;
    if (!isLoading && !_loaded.isCompleted) {
      _loaded.complete();
    }
    notifyListeners();
  }

  /// Whether a slot hasn't restored its account yet.
  bool get isLoading => _slots.any((state) => state.isLoading);

  /// The signed-in accounts, [DEFAULT]'s first.
  List<Account> get accounts {
    final providers = <String>{};
    return [
      for (final state in _slots)
        if (state.account case final account?)
          if (providers.add(account.provider)) account,
    ];
  }

  /// The account whose own channel is [channel], if it's signed in.
  Account? accountFor(Channel channel) =>
      accounts.where((account) => account.channel == channel).firstOrNull;

  _SlotState _stateOf(FirebaseApp app) =>
      _slots.firstWhere((state) => state.slot.app.name == app.name);

  /// Signs in to the [provider] account that [customToken] is for. It replaces
  /// the signed-in account on [provider] if there is one. Otherwise it goes in
  /// [DEFAULT] if that's empty, or else in [provider]'s own slot.
  Future<void> signIn(String provider, String customToken) async {
    await _loaded.future;
    final current = accounts.where((a) => a.provider == provider).firstOrNull;
    final AccountSlot slot;
    if (current != null) {
      slot = _stateOf(current.app).slot;
    } else if (_slots.first.account == null) {
      slot = _primary;
    } else {
      slot = _extra[provider]!;
    }
    await slot.signInWithCustomToken(customToken);
  }

  Future<void> signOut(Account account) => _stateOf(account.app).slot.signOut();

  Future<void> signOutAll() async {
    await Future.wait([for (final state in _slots) state.slot.signOut()]);
  }

  @override
  void dispose() {
    for (final state in _slots) {
      state.authSubscription?.cancel();
      state.profileSubscription?.cancel();
    }
    super.dispose();
  }
}
