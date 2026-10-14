import 'package:flutter/foundation.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/user.dart';

/// A [UserModel] that does not touch FirebaseAuth, for widget tests.
class FakeUserModel extends ChangeNotifier implements UserModel {
  @override
  final Channel? userChannel;

  @override
  final List<Channel> userChannels;

  /// Signed in as [userChannel], plus any other accounts in [userChannels].
  FakeUserModel({this.userChannel, List<Channel>? userChannels})
      : userChannels = userChannels ?? [if (userChannel != null) userChannel];

  @override
  bool get isLoading => false;

  @override
  bool isSignedIn() => userChannel != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
