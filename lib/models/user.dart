import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/models/accounts.dart';
import 'package:rtchat/models/channels.dart';

/// Tells Analytics and Crashlytics who's signed in: the first account, plus
/// `user_providers` listing every account's provider.
void reportAccounts(List<Account> accounts) {
  final account = accounts.firstOrNull;
  FirebaseCrashlytics.instance.setUserIdentifier(account?.user.uid ?? "");
  FirebaseAnalytics.instance.setUserId(id: account?.user.uid);
  FirebaseAnalytics.instance.setUserProperty(
    name: "user_providers",
    value: accounts.map((account) => account.provider).join(","),
  );
  if (account != null) {
    final channel = account.channel;
    FirebaseAnalytics.instance.setUserProperty(
      name: "user_provider",
      value: channel.provider,
    );
    FirebaseAnalytics.instance.setUserProperty(
      name: "user_channel_id",
      value: channel.channelId,
    );
    FirebaseAnalytics.instance.setUserProperty(
      name: "user_display_name",
      value: channel.displayName,
    );
  }
}

/// The signed-in user, who can have one account on each provider.
class UserModel extends ChangeNotifier {
  final AccountsModel _accounts;
  final void Function(List<Account> accounts) _report;

  // what was last reported, so it's only reported again on changes.
  String? _reported;

  UserModel(
    this._accounts, {
    void Function(List<Account>) report = reportAccounts,
  }) : _report = report {
    _accounts.addListener(_onAccountsChanged);
    _onAccountsChanged();
  }

  void _onAccountsChanged() {
    if (!isLoading) {
      final reported = [
        for (final account in accounts)
          "${account.user.uid}:${account.channel}:${account.channel.displayName}",
      ].join(",");
      if (reported != _reported) {
        _reported = reported;
        _report(accounts);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _accounts.removeListener(_onAccountsChanged);
    super.dispose();
  }

  /// The signed-in accounts, at most one per provider.
  List<Account> get accounts => _accounts.accounts;

  bool isSignedIn() => accounts.isNotEmpty;

  /// The first account's user.
  User? get user => accounts.firstOrNull?.user;

  /// The signed-in accounts' own channels.
  List<Channel> get userChannels => [
    for (final account in accounts) account.channel,
  ];

  bool isOwnChannel(Channel channel) => accountFor(channel) != null;

  /// The account to act on [channel] as: the one whose own channel it is.
  Account? accountFor(Channel channel) => _accounts.accountFor(channel);

  /// The account on [provider], which can also chat in others' channels there.
  Account? accountOn(String provider) =>
      accounts.where((account) => account.provider == provider).firstOrNull;

  /// The [Api] to call as the user on [provider]. Calls that only read are
  /// made as another account, or [DEFAULT], if there's none on [provider].
  Api apiOn(String provider) {
    final account = accountOn(provider) ?? accounts.firstOrNull;
    return account == null
        ? Api.forApp(Firebase.app())
        : Api.forAccount(account);
  }

  static String normalizeLanguageCode(String? twitchLang) {
    final mappings = {
      'en': 'en',
      'es': 'es',
      'fr': 'fr',
      'de': 'de',
      'it': 'it',
      'ar': 'ar',
      'bn': 'bn',
      'ja': 'ja',
      'ko': 'ko',
      'nl': 'nl',
      'pl': 'pl',
      'pt': 'pt',
      'ru': 'ru',
      'sv': 'sv',
      'uk': 'uk',
      'zh': 'zh',
      'zh-Hant': 'zh',
    };
    return mappings[twitchLang] ?? 'en';
  }

  bool get isLoading => _accounts.isLoading;

  /// Signs out of every account.
  Future<void> signOut() => _accounts.signOutAll();

  /// Signs in to the [provider] account [token] is for, replacing the one
  /// signed in on [provider] if there is one.
  Future<void> signIn(String provider, String token) =>
      _accounts.signIn(provider, token);
}

/// The activity feed of [channel], for the streamer whose channel it is.
Uri? activityFeedUriOf(Channel channel) {
  switch (channel.provider) {
    case Providers.twitch:
      return Uri.tryParse(
        "https://dashboard.twitch.tv/popout/u/${channel.displayName}/stream-manager/activity-feed",
      );
  }
  return null;
}

extension OwnChannels on UserModel {
  /// The activity feed of the first of the user's own channels that has one.
  Uri? get activityFeedUri =>
      userChannels.map(activityFeedUriOf).nonNulls.firstOrNull;

  /// Whether [username] is the name of one of the user's accounts, so a
  /// mention of it is of the user.
  bool isOwnName(String username) => userChannels.any(
    (channel) => channel.displayName.toLowerCase() == username.toLowerCase(),
  );
}
