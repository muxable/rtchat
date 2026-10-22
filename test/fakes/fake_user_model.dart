import 'package:flutter/foundation.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/user.dart';

import 'fake_accounts.dart';

/// A [UserModel] that does not touch FirebaseAuth, for widget tests. It's
/// signed in to [accounts], or to a single account on [userChannel].
class FakeUserModel extends ChangeNotifier implements UserModel {
  @override
  final List<Account> accounts;

  FakeUserModel({Channel? userChannel, List<Account>? accounts})
    : accounts =
          accounts ??
          [
            if (userChannel != null)
              fakeAccount(userChannel, appName: '[DEFAULT]'),
          ];

  @override
  List<Channel> get userChannels => [
    for (final account in accounts) account.channel,
  ];

  @override
  Channel? get userChannel => userChannels.firstOrNull;

  @override
  bool isOwnChannel(Channel channel) => accountFor(channel) != null;

  @override
  Account? accountFor(Channel channel) =>
      accounts.where((account) => account.channel == channel).firstOrNull;

  @override
  bool get isLoading => false;

  @override
  bool isSignedIn() => accounts.isNotEmpty;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
