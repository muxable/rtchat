import 'dart:async';

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
        .doOnData((user) {
          _user = user;
          notifyListeners();
          FirebaseCrashlytics.instance.setUserIdentifier(user?.uid ?? "");
        })
        .switchMap((user) => user == null
            ? Stream.value(null)
            : ProfilesAdapter.instance
                .getChannel(userId: user.uid, provider: "twitch")
                .doOnData((profile) {
                if (profile == null) {
                  FirebaseAuth.instance.signOut();
                }
              }))
        .listen((channel) {
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
