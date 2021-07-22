import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness) * (1 - amount));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness) * (1 - amount) + amount);

  return hslLight.toColor();
}

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

  Color applyLightnessBoost(BuildContext context, Color color) {
    switch (Theme.of(context).brightness) {
      case Brightness.dark:
        return lighten(color, lightnessBoost);
      case Brightness.light:
        return darken(color, lightnessBoost);
    }
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
