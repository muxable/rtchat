import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/adapters/profiles.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rxdart/rxdart.dart';

class UserModel extends ChangeNotifier {
  User? _user = FirebaseAuth.instance.currentUser;
  late final StreamSubscription<void> _subscription;

  Channel? _userChannel;

  UserModel() {
    _subscription = FirebaseAuth.instance
        .authStateChanges()
        .doOnData((user) async {
          _user = user;
          notifyListeners();
          await FirebaseCrashlytics.instance.setUserIdentifier(user?.uid ?? "");
          await FirebaseAnalytics.instance.setUserId(id: user?.uid);
          await FirebaseAnalytics.instance
              .setUserProperty(name: "provider", value: "twitch");
        })
        .switchMap((user) => user == null
            ? Stream.value(null)
            : ProfilesAdapter.instance
                .getChannel(userId: user.uid, provider: "twitch"))
        .listen((channel) {
          if (_userChannel != null && channel == null) {
            // we've lost channel data (likely invalid auth) so sign the user out.
            FirebaseAuth.instance.signOut();
          }
          _userChannel = channel;
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  bool isSignedIn() => _user != null;

  Channel? get userChannel => _userChannel;

  Future<void> signOut() => FirebaseAuth.instance.signOut();

  Future<UserCredential> signIn(String token) =>
      FirebaseAuth.instance.signInWithCustomToken(token);
}
