import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/adapters/profiles.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rxdart/rxdart.dart';

class UserModel extends ChangeNotifier {
  late final StreamSubscription<void> _subscription;
  Channel? _userChannel;

  UserModel() {
    _subscription = FirebaseAuth.instance
        .authStateChanges()
        .doOnData((user) {
          FirebaseCrashlytics.instance.setUserIdentifier(user?.uid ?? "");
        })
        .switchMap((user) => user == null
            ? Stream.value(null)
            : ProfilesAdapter.instance.getChannel(userId: user.uid))
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

  bool isSignedIn() => _userChannel != null;

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

  Channel? get userChannel => _userChannel;

  Future<void> signOut() => FirebaseAuth.instance.signOut();

  Future<UserCredential> signIn(String token) =>
      FirebaseAuth.instance.signInWithCustomToken(token);
}
