import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

final validateUrl = Uri.https('id.twitch.tv', '/oauth2/validate');

const TWITCH_CLIENT_ID = "edfnh2q85za8phifif9jxt3ey6t9b9";

class Channel {
  String provider;
  String channel;

  Channel(this.provider, this.channel);

  bool operator ==(that) =>
      that is Channel &&
      that.provider == this.provider &&
      that.channel == this.channel;

  int get hashCode => provider.hashCode ^ channel.hashCode;

  @override
  String toString() => "$provider:$channel";
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
        _profileSubscription?.cancel();
        _profileSubscription = FirebaseFirestore.instance
            .collection("profiles")
            .doc(user.uid)
            .snapshots()
            .listen((event) {
          final data = event.data();
          final Set<Channel> channels = {};
          if (data != null && data.containsKey('twitch')) {
            channels.add(Channel("twitch", data['twitch']['login']));
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
    final send = FirebaseFunctions.instance.httpsCallable('send');
    final results = await send({
      "provider": channel.provider,
      "channel": channel.channel,
      "message": message,
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
