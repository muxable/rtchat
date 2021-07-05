import 'dart:core';

import 'package:flutter/foundation.dart';

class StyleModel extends ChangeNotifier {
  double _fontSize = 20;
  double _lightnessBoost = 0.179;

  double get fontSize {
    return _fontSize;
  }

  set fontSize(double fontSize) {
    _fontSize = fontSize;
    notifyListeners();
  }

  double get lightnessBoost => _lightnessBoost;

  set lightnessBoost(double lightnessBoost) {
    _lightnessBoost = lightnessBoost;
    notifyListeners();
  }

  StyleModel.fromJson(Map<String, dynamic> json) {
    if (json['fontSize'] != null) {
      _fontSize = json['fontSize'];
    }
    if (json['lightnessBoost'] != null) {
      _lightnessBoost = json['lightnessBoost'];
    }
  }

  Map<String, dynamic> toJson() => {
        "lightnessBoost": _lightnessBoost,
        "fontSize": _fontSize,
      };
}
