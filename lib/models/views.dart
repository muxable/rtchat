import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/user.dart';

// unlike [listEquals], also compares the metadata that can change while the
// channel stays the same, so a renamed channel isn't shown stale.
bool _sameChannelsAndMetadata(List<Channel> a, List<Channel> b) {
  if (!listEquals(a, b)) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i].displayName != b[i].displayName ||
        a[i].language != b[i].language) {
      return false;
    }
  }
  return true;
}

List<Channel> _channelsFromJson(dynamic json) => [
      for (final channel in (json as List?) ?? const [])
        Channel(channel['provider'], channel['channelId'],
            channel['displayName'] ?? '',
            language: channel['language']),
    ];

/// The channels shown in chat, on any providers. The app opens with the
/// default channels (the signed-in user's own channel unless others were
/// picked); channels can then be opened, added and removed. None of this
/// needs an account, so signed-out users can use it too.
class ViewsModel extends ChangeNotifier {
  Channel? _userChannel;

  // the picked default channels; empty means the user's own channel.
  List<Channel> _defaultChannels = const [];

  // the current channels once they've been changed from the defaults. like
  // a channel opened from search before, these aren't remembered across
  // restarts: the app opens with the default channels.
  List<Channel>? _channels;

  // where messages are sent: a channel key, or [allChannels].
  String? _sendTarget;

  /// A send target meaning every channel the user can post to.
  static const allChannels = 'all';

  ViewsModel();

  /// Keeps the user's own channel in sync with the signed-in account.
  void update(UserModel userModel) {
    final channel = userModel.userChannel;
    if (_sameChannelsAndMetadata([if (channel != null) channel],
        [if (_userChannel != null) _userChannel!])) {
      return;
    }
    _userChannel = channel;
    notifyListeners();
  }

  /// The channels the app opens with.
  List<Channel> get defaultChannels => _defaultChannels.isNotEmpty
      ? List.unmodifiable(_defaultChannels)
      : List.unmodifiable([if (_userChannel != null) _userChannel!]);

  /// Whether default channels were picked, rather than being the user's own.
  bool get hasCustomDefaultChannels => _defaultChannels.isNotEmpty;

  set defaultChannels(List<Channel> channels) {
    _defaultChannels = List.unmodifiable(channels.toSet().toList());
    notifyListeners();
  }

  void addDefaultChannel(Channel channel) {
    if (_defaultChannels.contains(channel)) {
      return;
    }
    defaultChannels = [...defaultChannels, channel];
  }

  void removeDefaultChannel(Channel channel) {
    if (!_defaultChannels.contains(channel)) {
      return;
    }
    defaultChannels =
        _defaultChannels.where((other) => other != channel).toList();
  }

  void useCurrentChannelsAsDefault() => defaultChannels = channels;

  /// The channels shown in chat.
  List<Channel> get channels =>
      _channels == null ? defaultChannels : List.unmodifiable(_channels!);

  bool contains(Channel channel) => channels.contains(channel);

  /// The first channel. Features that only support one channel at a time
  /// (for now) use this one.
  Channel? get primaryChannel => channels.firstOrNull;

  void _setChannels(List<Channel> channels) {
    _channels = List.unmodifiable(channels);
    notifyListeners();
  }

  /// Shows just [channel], e.g. one picked from search or a raid.
  void openChannel(Channel channel) => _setChannels([channel]);

  /// Adds [channel] to the channels shown.
  void addChannel(Channel channel) {
    if (contains(channel)) {
      return;
    }
    _setChannels([...channels, channel]);
  }

  /// Removes [channel] from the channels shown, unless it's the only one.
  void removeChannel(Channel channel) {
    if (!contains(channel) || channels.length < 2) {
      return;
    }
    _setChannels(channels.where((other) => other != channel).toList());
  }

  /// Goes back to the default channels.
  void showDefaultChannels() {
    _channels = null;
    notifyListeners();
  }

  /// The channels someone with [accounts] can post to: those on a platform
  /// they have an account on. Accounts are independent per platform.
  List<Channel> postableChannels(List<Channel> accounts) => channels
      .where((channel) =>
          accounts.any((account) => account.provider == channel.provider))
      .toList();

  /// The chosen send target: a channel's key (`provider:id`) or
  /// [allChannels].
  String? get sendTarget => _sendTarget;

  set sendTarget(String? target) {
    _sendTarget = target;
    notifyListeners();
  }

  /// Where to send a message: the chosen target if it's still postable,
  /// otherwise the first postable channel.
  List<Channel> sendTargets(List<Channel> accounts) {
    final postable = postableChannels(accounts);
    final target = sendTarget;
    if (target == allChannels) {
      return postable;
    }
    final chosen =
        postable.where((channel) => channel.toString() == target).firstOrNull;
    return [if (chosen != null) chosen else ...postable.take(1)];
  }

  /// The channel whose emotes to offer when composing a message: the send
  /// target, or when sending to several channels, [primary] if it's one of
  /// them, else the first. Null if the user can't post to any channel.
  Channel? emoteChannel(List<Channel> accounts, Channel? primary) {
    final targets = sendTargets(accounts);
    if (targets.length == 1 || !targets.contains(primary)) {
      return targets.firstOrNull;
    }
    return primary;
  }

  /// The locale of the channel being viewed, falling back to the device's.
  Locale channelLocale(BuildContext context) {
    final language = primaryChannel?.language;
    if (language != null) {
      return Locale(UserModel.normalizeLanguageCode(language));
    }
    return Localizations.localeOf(context);
  }

  // saved views from before are ignored: they never shipped.
  ViewsModel.fromJson(Map<String, dynamic> json) {
    _defaultChannels =
        List.unmodifiable(_channelsFromJson(json['defaultChannels']));
    _sendTarget = json['sendTarget'];
  }

  Map<String, dynamic> toJson() => {
        'defaultChannels':
            _defaultChannels.map((channel) => channel.toJson()).toList(),
        'sendTarget': _sendTarget,
      };
}
