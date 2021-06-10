import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rtchat/models/layout.dart';

final Map<String, Future<Map<String, dynamic>>> _localCache = {};
Future<Map<String, dynamic>>? _globalCache;

Future<Map<String, dynamic>> getBadgeSets(Uri uri) async {
  final response = await http.get(uri);
  Map<String, dynamic> result = {};

  jsonDecode(response.body)['badge_sets'].forEach((key, badgeSet) {
    badgeSet['versions'].forEach((version, data) {
      result["$key/$version"] = data;
    });
  });

  return result;
}

class TwitchBadgeModel extends ChangeNotifier {
  Map<String, dynamic> localBadgeSets = {};
  Map<String, dynamic> globalBadgeSets = {};
  Set<String> _enabled = {};

  Future<void> bind(Set<Channel> channels) async {
    localBadgeSets.clear();
    globalBadgeSets.clear();
    if (_globalCache == null) {
      final uri =
          Uri.parse("https://badges.twitch.tv/v1/badges/global/display");
      _globalCache = getBadgeSets(uri);
    }
    channels.forEach((channel) {
      if (channel.provider != "twitch") {
        return;
      }
      if (!_localCache.containsKey(channel.channelId)) {
        final uri = Uri.parse(
            "https://badges.twitch.tv/v1/badges/channels/${channel.channelId}/display");
        _localCache[channel.channelId] = getBadgeSets(uri);
      }
    });
    globalBadgeSets.addAll((await _globalCache)!);
    for (final channel in channels) {
      if (channel.provider != "twitch") {
        return;
      }
      localBadgeSets.addAll((await _localCache[channel.channelId])!);
    }

    _enabled = _enabled.intersection(
        globalBadgeSets.keys.toSet().union(localBadgeSets.keys.toSet()));

    notifyListeners();
  }

  Map<String, dynamic> get badgeSets {
    return {...globalBadgeSets, ...localBadgeSets};
  }

  void setAllEnabled(bool enabled) {
    if (enabled) {
      _enabled =
          globalBadgeSets.keys.toSet().union(localBadgeSets.keys.toSet());
    } else {
      _enabled.clear();
    }

    notifyListeners();
  }

  void setEnabled(String key, bool enabled) {
    if (!localBadgeSets.containsKey(key) && !globalBadgeSets.containsKey(key)) {
      return;
    }
    if (enabled) {
      _enabled.add(key);
    } else {
      _enabled.remove(key);
    }

    notifyListeners();
  }

  bool isEnabled(String key) {
    return _enabled.contains(key);
  }

  int get badgeCount {
    return globalBadgeSets.keys
        .toSet()
        .union(localBadgeSets.keys.toSet())
        .length;
  }

  int get enabledCount {
    return _enabled.length;
  }

  TwitchBadgeModel.fromJson(Map<String, dynamic> json) {
    final badges = json['enabled'];
    if (badges != null) {
      for (dynamic badge in badges) {
        setEnabled(badge, true);
      }
    }
  }

  Map<String, dynamic> toJson() => {
        "enabled": _enabled.toList(),
      };
}
