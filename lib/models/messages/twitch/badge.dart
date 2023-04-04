import 'dart:async';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:rtchat/models/adapters/chat_state.dart';
import 'package:rtchat/models/channels.dart';

class TwitchBadgeModel extends ChangeNotifier {
  StreamSubscription<void>? _globalBadgeSubscription;
  StreamSubscription<void>? _localBadgeSubscription;

  List<TwitchBadgeInfo> localBadgeSets = [];
  List<TwitchBadgeInfo> globalBadgeSets = [];
  Set<String> _enabled = {};
  bool _isAllEnabled = false;

  set channel(Channel? channel) {
    localBadgeSets.clear();
    globalBadgeSets.clear();
    _globalBadgeSubscription?.cancel();
    _localBadgeSubscription?.cancel();

    _globalBadgeSubscription = ChatStateAdapter.instance
        .getTwitchBadges()
        .asStream()
        .listen((badgeSets) {
      globalBadgeSets = badgeSets;
      notifyListeners();
    });
    if (channel != null) {
      if (channel.provider != "twitch") {
        return;
      }
      _localBadgeSubscription = ChatStateAdapter.instance
          .getTwitchBadges(channelId: channel.channelId)
          .asStream()
          .listen((badgeSets) {
        localBadgeSets = badgeSets;
        notifyListeners();
      });
    }
  }

  List<TwitchBadgeInfo> get badgeSets {
    return [...globalBadgeSets, ...localBadgeSets];
  }

  void setAllEnabled(bool enabled) {
    if (enabled) {
      _enabled = badgeSets.map((e) => e.setId).toSet();
      _isAllEnabled = true;
    } else {
      _enabled.clear();
      _isAllEnabled = false;
    }

    notifyListeners();
  }

  void setEnabled(String key, bool enabled) {
    if (enabled) {
      _enabled.add(key);
    } else {
      _enabled.remove(key);
    }
    if (_enabled.length == badgeSets.length) {
      _isAllEnabled = true;
    } else {
      _isAllEnabled = false;
    }

    notifyListeners();
  }

  bool isEnabled(String setId) => _enabled.contains(setId) || _isAllEnabled;

  int get badgeCount {
    final globalKeys = globalBadgeSets.map((e) => e.setId).toSet();
    final localKeys = localBadgeSets.map((e) => e.setId).toSet();
    return globalKeys.union(localKeys).length;
  }

  int get enabledCount => _enabled.length;

  TwitchBadgeModel.fromJson(Map<String, dynamic> json) {
    final badges = json['enabled'];
    if (badges != null) {
      for (dynamic badge in badges) {
        _enabled.add(badge);
      }
      notifyListeners();
    }
  }

  Map<String, dynamic> toJson() => {
        "enabled": _enabled.toList(),
      };
}
