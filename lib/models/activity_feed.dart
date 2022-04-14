import 'dart:core';

import 'package:flutter/foundation.dart';

class ActivityFeedModel extends ChangeNotifier {
  bool _isEnabled = false;
  bool _isCustom = false;
  String _customUrl = "";

  bool get isCustom => _isCustom;

  set isCustom(bool isCustom) {
    _isCustom = isCustom;
    notifyListeners();
  }

  bool get isEnabled => _isEnabled;

  set isEnabled(bool isEnabled) {
    _isEnabled = isEnabled;
    notifyListeners();
  }

  String get customUrl => _customUrl;

  set customUrl(String customUrl) {
    _customUrl = customUrl;
    notifyListeners();
  }

  ActivityFeedModel.fromJson(Map<String, dynamic> json) {
    if (json['isCustom'] != null) {
      _isCustom = json['isCustom'];
    }
    if (json['customUrl'] != null) {
      _customUrl = json['customUrl'];
    }
    if (json['isEnabled'] != null) {
      _isEnabled = json['isEnabled'];
    } else if (json['isCustom'] != null) {
      _isEnabled =
          true; // to migrate users from old activity feed default true.
    }
  }

  Map<String, dynamic> toJson() => {
        "isCustom": _isCustom,
        "customUrl": _customUrl,
        "isEnabled": _isEnabled,
      };
}
