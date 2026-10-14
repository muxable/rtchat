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
Channel? channelReplacedBy(List<Channel> channels, Channel channel) => channels
    .where((other) => other.provider == channel.provider && other != channel)
    .firstOrNull;

/// [channels] with [channel] added, in place of the one on its provider.
List<Channel> _withChannel(List<Channel> channels, Channel channel) {
  final index =
      channels.indexWhere((other) => other.provider == channel.provider);
  if (index == -1) {
    return [...channels, channel];
  }
  return [...channels]..[index] = channel;
}

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

  // the key of the channel picked to preview.
  String? _previewTarget;

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
    _defaultChannels = List.unmodifiable(_onePerProvider(channels));
    notifyListeners();
  }

  /// Adds [channel] to the default channels, replacing the one on its
  /// provider.
  void addDefaultChannel(Channel channel) {
    if (_defaultChannels.contains(channel)) {
      return;
    }
    defaultChannels = _withChannel(defaultChannels, channel);
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

  /// The channel messages are sent to: the first one shown on [account]'s
  /// provider, as an account can only post on its own provider. Null if no
  /// channel shown is on it, or there's no account.
  Channel? sendChannel(Channel? account) => account == null
      ? null
      : channels
          .where((channel) => channel.provider == account.provider)
          .firstOrNull;

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

  // saved views from before are ignored: they never shipped. defaults saved
  // with several channels on one provider keep only the first of them.
  ViewsModel.fromJson(Map<String, dynamic> json) {
    _defaultChannels = List.unmodifiable(
        _onePerProvider(_channelsFromJson(json['defaultChannels'])));
  }

  Map<String, dynamic> toJson() => {
        'defaultChannels':
            _defaultChannels.map((channel) => channel.toJson()).toList(),
      };
}
