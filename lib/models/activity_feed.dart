import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:rtchat/models/channels.dart';

class ActivityFeedModel extends ChangeNotifier {
  bool _isCustom = false;
  String _customUrl = "";
  Channel? _baseChannel;
  ChannelsModel? _host;

  @override
  void dispose() {
    _host?.removeListener(register);
    super.dispose();
  }

  bool get isCustom => _isCustom;

  set isCustom(bool isCustom) {
    _isCustom = isCustom;
    notifyListeners();
  }

  String get customUrl => _customUrl;

  set customUrl(String customUrl) {
    _customUrl = customUrl;
    notifyListeners();
  }

  bind(ChannelsModel model) {
    _host?.removeListener(register);
    _host = model;
    register();
    model.addListener(register);
  }

  register() {
    final host = _host;
    if (host == null) {
      return;
    }
    if (host.channels.isEmpty) {
      _baseChannel = null;
    } else {
      final base = host.channels.first;
      _baseChannel = base;
    }
    notifyListeners();
  }

  Uri? get url {
    final channel = _baseChannel;
    if (_isCustom) {
      return Uri.tryParse(_customUrl);
    } else if (channel == null) {
      return null;
    }
    switch (channel.provider) {
      case "twitch":
        return Uri.tryParse(
            "https://dashboard.twitch.tv/popout/u/${channel.displayName}/stream-manager/activity-feed");
    }
  }

  ActivityFeedModel.fromJson(Map<String, dynamic> json) {
    if (json['isCustom'] != null) {
      _isCustom = json['isCustom'];
    }
    if (json['customUrl'] != null) {
      _customUrl = json['customUrl'];
    }
  }

  Map<String, dynamic> toJson() => {
        "isCustom": _isCustom,
        "customUrl": _customUrl,
      };
}
