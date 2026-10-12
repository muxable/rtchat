import 'package:flutter/widgets.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/user.dart';
import 'package:uuid/uuid.dart';

/// A set of channels, on any providers, shown together.
class ChannelView {
  final String id;
  final String name;
  final List<Channel> channels;

  const ChannelView(
      {required this.id, required this.name, required this.channels});

  ChannelView copyWith({String? name, List<Channel>? channels}) => ChannelView(
      id: id, name: name ?? this.name, channels: channels ?? this.channels);

  ChannelView.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'] ?? '',
        channels = [
          for (final channel in (json['channels'] as List?) ?? const [])
            Channel(channel['provider'], channel['channelId'],
                channel['displayName'] ?? '',
                language: channel['language']),
        ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'channels': channels.map((channel) => channel.toJson()).toList(),
      };

  @override
  bool operator ==(other) =>
      other is ChannelView &&
      other.id == id &&
      other.name == name &&
      _sameChannels(other.channels, channels);

  @override
  int get hashCode => id.hashCode;
}

bool _sameChannels(List<Channel> a, List<Channel> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

// unlike [_sameChannels], also compares the metadata that can change while
// the channel stays the same, so a renamed channel isn't shown stale.
bool _sameChannelsAndMetadata(List<Channel> a, List<Channel> b) {
  if (!_sameChannels(a, b)) {
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

/// What the user is looking at: by default the channel they signed in with
/// ("My channel"), a channel they opened from search or a raid, or a view they
/// saved. Views don't need an account, so signed-out users can use them too.
class ViewsModel extends ChangeNotifier {
  static const myChannelsId = 'my-channels';

  List<Channel> _userChannels = const [];
  final List<ChannelView> _savedViews = [];
  String? _savedViewId;

  // a channel opened from search or a raid. like before views existed, this
  // isn't remembered across restarts.
  ChannelView? _openedView;

  // where each view's messages are sent: a channel key, or [allChannels].
  final Map<String, String> _sendTargets = {};

  /// A send target meaning every channel the user can post to.
  static const allChannels = 'all';

  ViewsModel();

  /// Keeps "My channel" in sync with the signed-in account.
  void update(UserModel userModel) {
    final channel = userModel.userChannel;
    final channels = [if (channel != null) channel];
    if (_sameChannelsAndMetadata(channels, _userChannels)) {
      return;
    }
    _userChannels = List.unmodifiable(channels);
    notifyListeners();
  }

  ChannelView get myChannels =>
      ChannelView(id: myChannelsId, name: '', channels: _userChannels);

  List<ChannelView> get savedViews => List.unmodifiable(_savedViews);

  ChannelView get activeView =>
      _openedView ??
      _savedViews.where((view) => view.id == _savedViewId).firstOrNull ??
      myChannels;

  /// The first channel of the active view. Features that only support one
  /// channel at a time (for now) use this one.
  Channel? get primaryChannel => activeView.channels.firstOrNull;

  /// The channels of the active view that someone signed in as [userChannel]
  /// can post to: those on the same platform.
  List<Channel> postableChannels(Channel? userChannel) => activeView.channels
      .where((channel) => channel.provider == userChannel?.provider)
      .toList();

  /// The send target chosen for the active view: a channel's key
  /// (`provider:id`) or [allChannels].
  String? get sendTarget => _sendTargets[activeView.id];

  set sendTarget(String? target) {
    if (target == null) {
      _sendTargets.remove(activeView.id);
    } else {
      _sendTargets[activeView.id] = target;
    }
    notifyListeners();
  }

  /// Where to send a message from the active view: the chosen target if it's
  /// still postable, otherwise the first postable channel.
  List<Channel> sendTargets(Channel? userChannel) {
    final postable = postableChannels(userChannel);
    final target = sendTarget;
    if (target == allChannels) {
      return postable;
    }
    final chosen =
        postable.where((channel) => channel.toString() == target).firstOrNull;
    return [if (chosen != null) chosen else ...postable.take(1)];
  }

  /// Shows a single channel, e.g. one picked from search.
  void openChannel(Channel channel) {
    _openedView = ChannelView(
        id: 'channel:$channel', name: channel.displayName, channels: [channel]);
    notifyListeners();
  }

  void showView(String id) {
    _openedView = null;
    _savedViewId = id == myChannelsId ? null : id;
    notifyListeners();
  }

  void showMyChannels() => showView(myChannelsId);

  ChannelView saveView(String name, List<Channel> channels) {
    final view = ChannelView(
        id: const Uuid().v4(), name: name, channels: List.of(channels));
    _savedViews.add(view);
    notifyListeners();
    return view;
  }

  void updateView(ChannelView view) {
    final index = _savedViews.indexWhere((saved) => saved.id == view.id);
    if (index == -1) {
      return;
    }
    _savedViews[index] = view;
    notifyListeners();
  }

  void deleteView(String id) {
    _savedViews.removeWhere((view) => view.id == id);
    if (_savedViewId == id) {
      _savedViewId = null;
    }
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

  ViewsModel.fromJson(Map<String, dynamic> json) {
    for (final view in (json['views'] as List?) ?? const []) {
      _savedViews.add(ChannelView.fromJson(Map<String, dynamic>.from(view)));
    }
    final id = json['activeViewId'];
    if (_savedViews.any((view) => view.id == id)) {
      _savedViewId = id;
    }
  }

  Map<String, dynamic> toJson() => {
        'views': _savedViews.map((view) => view.toJson()).toList(),
        'activeViewId': _savedViewId,
      };
}
