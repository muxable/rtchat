import 'dart:core';

import 'package:flutter/material.dart';

class StreamPreviewModel extends ChangeNotifier {
  var _isHighDefinition = false;
  var _volume = 0;
  var _showBatteryPrompt = true;

  bool get isHighDefinition => _isHighDefinition;

  set isHighDefinition(bool value) {
    _isHighDefinition = value;
    notifyListeners();
  }

  int get volume => _volume;

  set volume(int value) {
    _volume = value;
    notifyListeners();
  }

  bool get showBatteryPrompt => _showBatteryPrompt;

  set showBatteryPrompt(bool value) {
    _showBatteryPrompt = value;
    notifyListeners();
  }

  StreamPreviewModel.fromJson(Map<String, dynamic> json) {
    if (json['isHighDefinition'] != null) {
      _isHighDefinition = json['isHighDefinition'];
    }
    if (json['volume'] != null) {
      _volume = json['volume'];
    }
    if (json['showBatteryPrompt'] != null) {
      _showBatteryPrompt = json['showBatteryPrompt'];
    }
  }

  Map<String, dynamic> toJson() => {
        'isHighDefinition': _isHighDefinition,
        'volume': _volume,
        'showBatteryPrompt': _showBatteryPrompt,
      };
}
