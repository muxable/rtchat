import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rtchat/models/channels.dart';

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
  StreamSubscription<void>? _globalBadgeSubscription;
  StreamSubscription<void>? _localBadgeSubscription;

  Map<String, dynamic> localBadgeSets = {};
  Map<String, dynamic> globalBadgeSets = {};
  Set<String> _enabled = {};

  set channel(Channel? channel) {
    localBadgeSets.clear();
    globalBadgeSets.clear();
    _globalBadgeSubscription?.cancel();
    _localBadgeSubscription?.cancel();

    _globalBadgeSubscription = getBadgeSets(
            Uri.parse("https://badges.twitch.tv/v1/badges/global/display"))
        .asStream()
        .listen((badgeSets) {
      globalBadgeSets = badgeSets;
      notifyListeners();
    });
    if (channel != null) {
      if (channel.provider != "twitch") {
        return;
      }
      _localBadgeSubscription = getBadgeSets(Uri.parse(
              "https://badges.twitch.tv/v1/badges/channels/${channel.channelId}/display"))
          .asStream()
          .listen((badgeSets) {
        localBadgeSets = badgeSets;
        notifyListeners();
      });
    }
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
    if (enabled) {
      _enabled.add(key);
    } else {
      _enabled.remove(key);
    }

    notifyListeners();
  }

  bool isEnabled(String key) => _enabled.contains(key);

  int get badgeCount {
    return globalBadgeSets.keys
        .toSet()
        .union(localBadgeSets.keys.toSet())
        .length;
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
