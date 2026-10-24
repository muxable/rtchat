import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/accounts.dart';

/// Keeps callable requests (including Firebase auth and error handling) on our, own hostname so the backend can move without another app release.
class Api {
  Api(this._functions);

  static const String _apiBaseUrl = 'https://rtchat-api.rtirl.com';
  static final Map<String, Api> _forApp = {};

  /// Calls as the user signed in on [app].
  static Api forApp(FirebaseApp app) =>
      _forApp[app.name] ??= Api(FirebaseFunctions.instanceFor(app: app));

  /// Calls as [account], so the backend acts on that account's channel.
  static Api forAccount(Account account) => forApp(account.app);

  /// Makes [forApp] return [api] for [app], so tests can see which account
  /// a call is made as.
  @visibleForTesting
  static void debugOverride(FirebaseApp app, Api api) =>
      _forApp[app.name] = api;

  @visibleForTesting
  static void debugReset() => _forApp.clear();

  final FirebaseFunctions _functions;
  bool _useEmulator = false;

  FirebaseApp get app => _functions.app;

  HttpsCallable callable(String name) {
    if (_useEmulator) {
      return _functions.httpsCallable(name);
    }
    return _functions.httpsCallableFromUrl('$_apiBaseUrl/$name');
  }

  /// Use named calls for the emulator, which expects /project/region/function, rather than the public API path. This also keeps integration tests local.
  void useEmulator(String host, int port) {
    _functions.useFunctionsEmulator(host, port);
    _useEmulator = true;
  }
}
