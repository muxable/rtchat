import 'dart:core';

import 'package:flutter/foundation.dart';

class ActivityFeedModel extends ChangeNotifier {
  bool _isCustom = false;
  String _customUrl = "";

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
