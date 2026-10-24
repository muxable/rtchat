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
    Channel(
      channel['provider'],
      channel['channelId'],
      channel['displayName'] ?? '',
      language: channel['language'],
    ),
];

/// [channels] without any after the first on each provider.
List<Channel> _onePerProvider(List<Channel> channels) {
  final providers = <String>{};
  return [
    for (final channel in channels)
      if (providers.add(channel.provider)) channel,
  ];
}

/// The channel in [channels] on [channel]'s provider, which adding [channel]
/// replaces. An account is bound to one provider, so at most one channel per
/// provider is shown at a time.
Channel? channelReplacedBy(List<Channel> channels, Channel channel) =>
    channels
        .where(
          (other) => other.provider == channel.provider && other != channel,
        )
        .firstOrNull;

/// [channels] with [channel] added, in place of the one on its provider.
List<Channel> _withChannel(List<Channel> channels, Channel channel) {
  final index = channels.indexWhere(
    (other) => other.provider == channel.provider,
  );
  if (index == -1) {
    return [...channels, channel];
  }
  return [...channels]..[index] = channel;
}

/// The channels shown in chat, on any providers. The app opens with the
/// default channels: those of every signed-in account, so a simulcaster
/// opens to merged chat. Channels can then be opened, added and removed for
/// the session. None of this needs an account, so signed-out users can use it
/// too.
class ViewsModel extends ChangeNotifier {
  // the signed-in accounts' own channels, one per provider.
  List<Channel> _userChannels = const [];

  // the current channels once they've been changed from the defaults. like
  // a channel opened from search before, these aren't remembered across
  // restarts: the app opens with the default channels.
  List<Channel>? _channels;

  // the key of the channel picked to preview.
  String? _previewTarget;

  // the channel last picked to send messages to.
  Channel? _sendTarget;

  ViewsModel();

  /// Keeps the user's own channels in sync with the signed-in accounts.
  void update(UserModel userModel) {
    final channels = _onePerProvider(userModel.userChannels);
    if (_sameChannelsAndMetadata(channels, _userChannels)) {
      return;
    }
    _userChannels = List.unmodifiable(channels);
    notifyListeners();
  }

  /// The channels the app opens with: those of every signed-in account, in
  /// the order the accounts are listed.
  List<Channel> get defaultChannels => _userChannels;

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

  /// Adds [channel] to the channels shown, replacing the one on its
  /// provider.
  void addChannel(Channel channel) {
    if (contains(channel)) {
      return;
    }
    _setChannels(_withChannel(channels, channel));
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

  /// The channels shown that messages can be sent to: those on a provider
  /// the user has an account on, as an account can chat in any channel on
  /// its own provider. At most one channel per provider is shown, so each
  /// is sent to by a different account.
  List<Channel> get sendableChannels {
    final providers = {for (final channel in _userChannels) channel.provider};
    return List.unmodifiable(
      channels.where((channel) => providers.contains(channel.provider)),
    );
  }

  /// The channel messages are sent to: the one last picked, while it can
  /// be sent to, otherwise the first of [sendableChannels].
  Channel? get sendChannel {
    final channels = sendableChannels;
    return channels.where((channel) => channel == _sendTarget).firstOrNull ??
        channels.firstOrNull;
  }

  set sendChannel(Channel? channel) {
    if (channel == _sendTarget) {
      return;
    }
    _sendTarget = channel;
    notifyListeners();
  }

  /// The channel whose stream is previewed: the one picked, while it's
  /// shown, otherwise the first channel.
  Channel? get previewChannel =>
      channels
          .where((channel) => channel.toString() == _previewTarget)
          .firstOrNull ??
      primaryChannel;

  set previewChannel(Channel? channel) {
    _previewTarget = channel?.toString();
    notifyListeners();
  }

  /// The locale of the channel being viewed, falling back to the device's.
  Locale channelLocale(BuildContext context) {
    final language = primaryChannel?.language;
    if (language != null) {
      return Locale(UserModel.normalizeLanguageCode(language));
    }
    return Localizations.localeOf(context);
  }

  // saved views and picked default channels from before are ignored: the
  // defaults are now always the signed-in accounts' channels. they're dropped
  // from what's saved next.
  ViewsModel.fromJson(Map<String, dynamic> json) {
    _sendTarget =
        _channelsFromJson([
          if (json['sendChannel'] != null) json['sendChannel'],
        ]).firstOrNull;
  }

  Map<String, dynamic> toJson() => {
    if (_sendTarget != null) 'sendChannel': _sendTarget!.toJson(),
  };
}
