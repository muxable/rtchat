import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/channels.dart';

class UserModel extends ChangeNotifier {
  User? _user = FirebaseAuth.instance.currentUser;
  late StreamSubscription<User?> _userSubscription;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;
  Channel? _userChannel;

  UserModel() {
    _userSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();

      // bind profile
      if (user != null) {
        FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
        _profileSubscription?.cancel();
        _profileSubscription = FirebaseFirestore.instance
            .collection("profiles")
            .doc(user.uid)
            .snapshots()
            .listen((event) {
          final data = event.data();
          if (data != null && data.containsKey('twitch')) {
            _userChannel = Channel(
                "twitch", data['twitch']['id'], data['twitch']['displayName']);
          } else {
            _userChannel = null;
          }
          notifyListeners();
        });
      }
    });
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  bool isSignedIn() => _user != null;

  Future<void> send(Channel channel, String message) async {
    final call = FirebaseFunctions.instance.httpsCallable('send');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "message": message,
    });
  }

  Future<void> ban(Channel channel, String username, String reason) async {
    final call = FirebaseFunctions.instance.httpsCallable('ban');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
      "reason": reason,
    });
  }

  Future<void> unban(Channel channel, String username) async {
    final call = FirebaseFunctions.instance.httpsCallable('unban');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
    });
  }

  Future<void> timeout(Channel channel, String username, String reason,
      Duration duration) async {
    final call = FirebaseFunctions.instance.httpsCallable('timeout');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
      "reason": reason,
      "length": duration.inSeconds,
    });
  }

  Future<void> delete(Channel channel, String messageId) async {
    final call = FirebaseFunctions.instance.httpsCallable('deleteMessage');
    await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "messageId": messageId,
    });
  }

  User? get user => _user;

  Channel? get userChannel => _userChannel;

  Future<void> signOut() => FirebaseAuth.instance.signOut();

  Future<UserCredential> signIn(String token) =>
      FirebaseAuth.instance.signInWithCustomToken(token);
}
