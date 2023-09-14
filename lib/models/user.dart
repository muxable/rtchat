import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/adapters/channels.dart';
import 'package:rtchat/models/adapters/profiles.dart';
import 'package:rtchat/models/adapters/tokens.dart';
import 'package:rtchat/models/channels.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class UserModel extends ChangeNotifier {
  bool _isLoading = true;

  late final StreamSubscription<void> _userSubscription;
  StreamSubscription<void>? _profileSubscription;

  User? _user;
  Channel? _userChannel;
  Channel? _activeChannel;

  UserModel() {
    _userSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) async {
      _user = user;
      _profileSubscription?.cancel();
      await FirebaseCrashlytics.instance.setUserIdentifier(user?.uid ?? "");
      await FirebaseAnalytics.instance.setUserId(id: user?.uid);
      if (user == null) {
        _userChannel = null;
        _isLoading = false;
        notifyListeners();
        return;
      }
      _profileSubscription = ProfilesAdapter.instance
          .getChannel(userId: user.uid, provider: "twitch")
          .listen((channel) {
        _userChannel = channel;
        _isLoading = false;
        notifyListeners();
        if (channel != null) {
          FirebaseAnalytics.instance
              .setUserProperty(name: "user_provider", value: channel.provider);
          FirebaseAnalytics.instance.setUserProperty(
              name: "user_channel_id", value: channel.channelId);
          FirebaseAnalytics.instance.setUserProperty(
              name: "user_display_name", value: channel.displayName);
        }
      });
    });
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _userSubscription.cancel();
    super.dispose();
  }

  bool isSignedIn() => _user != null;

  User? get user => _user;

  Channel? get userChannel => _userChannel;

  Channel? get activeChannel => _activeChannel ?? _userChannel;

  set activeChannel(Channel? channel) {
    _activeChannel = channel;
    notifyListeners();
  }

  Uri? get activityFeedUri {
    final channel = _userChannel;
    if (channel == null) {
      return null;
    }
    switch (channel.provider) {
      case "twitch":
        return Uri.tryParse(
            "https://dashboard.twitch.tv/popout/u/${channel.displayName}/stream-manager/activity-feed");
    }
    return null;
  }

  bool get isLoading => _isLoading;

  Future<void> signOut() => FirebaseAuth.instance.signOut();

  Future<UserCredential> signIn(String token) =>
      FirebaseAuth.instance.signInWithCustomToken(token);

  Future<void> send(Channel channel, String message) async {
    final uid = _user?.uid;
    final userChannel = _userChannel;
    if (uid == null || userChannel == null) {
      return;
    }

    final ws = WebSocketChannel.connect(
      Uri.parse('wss://irc-ws.chat.twitch.tv:443'),
    );

    final token = await TokensAdapter.instance
        .getAccessToken(userId: uid, provider: channel.provider);
    final userLogin = await ChannelsAdapter.instance.getLogin(userChannel);
    final channelLogin = await ChannelsAdapter.instance.getLogin(channel);

    ws.sink.add('CAP REQ :twitch.tv/commands');
    ws.sink.add('PASS oauth:$token');
    ws.sink.add('NICK $userLogin');
    ws.sink.add('PRIVMSG #$channelLogin :$message');
    ws.sink.close();
  }
}
