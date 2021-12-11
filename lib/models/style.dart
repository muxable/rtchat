import 'dart:core';

import 'package:flutter/material.dart';

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

enum CompactMessages { none, withinMessage, acrossMessages }

extension CompactMessagesJson on CompactMessages {
  static fromJson(dynamic value) {
    switch (value) {
      case 0:
        return CompactMessages.none;
      case 1:
        return CompactMessages.withinMessage;
      case 2:
        return CompactMessages.acrossMessages;
      default:
        return CompactMessages.none;
    }
  }

  toJson() {
    switch (this) {
      case CompactMessages.none:
        return 0;
      case CompactMessages.withinMessage:
        return 1;
      case CompactMessages.acrossMessages:
        return 2;
    }
  }
}

class StyleModel extends ChangeNotifier {
  double _fontSize = 20;
  double _lightnessBoost = 0.179;
  bool _isDeletedMessagesVisible = true;
  CompactMessages _compactMessages = CompactMessages.none;
  bool _isDiscoModeAvailable = false;

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

  set isDeletedMessagesVisible(bool isDeletedMessagesVisible) {
    _isDeletedMessagesVisible = isDeletedMessagesVisible;
    notifyListeners();
  }

  bool get isDeletedMessagesVisible => _isDeletedMessagesVisible;

  set compactMessages(CompactMessages compactMessages) {
    _compactMessages = compactMessages;
    notifyListeners();
  }

  CompactMessages get compactMessages => _compactMessages;

  set isDiscoModeAvailable(bool isDiscoModeAvailable) {
    _isDiscoModeAvailable = isDiscoModeAvailable;
    notifyListeners();
  }

  bool get isDiscoModeAvailable => _isDiscoModeAvailable;

  StyleModel.fromJson(Map<String, dynamic> json) {
    if (json['fontSize'] != null) {
      _fontSize = json['fontSize'];
    }
    if (json['lightnessBoost'] != null) {
      _lightnessBoost = json['lightnessBoost'];
    }
    if (json['isDeletedMessagesVisible'] != null) {
      _isDeletedMessagesVisible = json['isDeletedMessagesVisible'];
    }
    if (json['compactMessages'] != null) {
      _compactMessages = CompactMessagesJson.fromJson(json['compactMessages']);
    }
    if (json['isDiscoModeEnabled'] != null) {
      _isDiscoModeAvailable = json['isDiscoModeEnabled'];
    }
  }

  Map<String, dynamic> toJson() => {
        "lightnessBoost": _lightnessBoost,
        "fontSize": _fontSize,
        "isDeletedMessagesVisible": _isDeletedMessagesVisible,
        "compactMessages": _compactMessages.toJson(),
        "isDiscoModeEnabled": _isDiscoModeAvailable,
      };
}
