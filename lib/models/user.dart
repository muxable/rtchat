import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

final validateUrl = Uri.https('id.twitch.tv', '/oauth2/validate');

const TWITCH_CLIENT_ID = "edfnh2q85za8phifif9jxt3ey6t9b9";

class Channel {
  String provider;
  String channelId;
  String displayName;

  Channel(this.provider, this.channelId, this.displayName);

  bool operator ==(that) =>
      that is Channel &&
      that.provider == this.provider &&
      that.channelId == this.channelId;

  int get hashCode => provider.hashCode ^ channelId.hashCode;

  @override
  String toString() => "$provider:$channelId";
}

class UserModel extends ChangeNotifier {
  User? _user = FirebaseAuth.instance.currentUser;
  Set<Channel> _channels = {};
  late StreamSubscription<User?> _userSubscription;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;

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
          final Set<Channel> channels = {};
          if (data != null && data.containsKey('twitch')) {
            channels.add(Channel(
                "twitch", data['twitch']['id'], data['twitch']['displayName']));
          }
          _channels = channels;
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

  bool isSignedIn() {
    return _user != null;
  }

  Future<void> send(Channel channel, String message) async {
    final call = FirebaseFunctions.instance.httpsCallable('send');
    final results = await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "message": message,
    });
    print(results);
  }

  Future<void> ban(Channel channel, String username, String reason) async {
    final call = FirebaseFunctions.instance.httpsCallable('ban');
    final results = await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
      "reason": reason,
    });
    print(results);
  }

  Future<void> unban(Channel channel, String username) async {
    final call = FirebaseFunctions.instance.httpsCallable('unban');
    final results = await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
    });
    print(results);
  }

  Future<void> timeout(Channel channel, String username, String reason,
      Duration duration) async {
    final call = FirebaseFunctions.instance.httpsCallable('timeout');
    final results = await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "username": username,
      "reason": reason,
      "length": duration.inSeconds,
    });
    print(results);
  }

  Future<void> delete(Channel channel, String messageId) async {
    final call = FirebaseFunctions.instance.httpsCallable('deleteMessage');
    final results = await call({
      "provider": channel.provider,
      "channelId": channel.channelId,
      "messageId": messageId,
    });
    print(results);
  }

  Set<Channel> get channels {
    return _channels;
  }

  User? get user {
    return _user;
  }

  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  void signIn(String token) {
    FirebaseAuth.instance.signInWithCustomToken(token);
  }
}
