import 'dart:core';

import 'package:flutter/material.dart';

class StreamPreviewModel extends ChangeNotifier {
  var _isHighDefinition = false;
  var _volume = 0;
  var _showBatteryPrompt = true;
  var _quality = '160p';

  List<String> _availableQualities = [];

  bool _canSwitchQuality = false;

  String get quality => _quality;

  set quality(String value) {
    _quality = value;
    notifyListeners();
  }

  set availableQualities(List<String> qualities) {
    _availableQualities = qualities;

    _canSwitchQuality = qualities.length > 1;
    notifyListeners();
  }

  set canSwitchQuality(bool value) {
    if (_canSwitchQuality != value) {
      _canSwitchQuality = value;
      notifyListeners();
    }
  }

  bool get isHighDefinition => _isHighDefinition;

  List<String> get availableQualities => List.unmodifiable(_availableQualities);

  bool get canSwitchQuality => _canSwitchQuality;

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
    if (json['quality'] != null) {
      _quality = json['quality'];
    }

    if (json['isHighDefinition'] != null) {
      _isHighDefinition = json['isHighDefinition'];
    }
    if (json['volume'] != null) {
      _volume = json['volume'];
    }
    if (json['showBatteryPrompt'] != null) {
      _showBatteryPrompt = json['showBatteryPrompt'];
    }

    if (json['availableQualities'] != null) {
      final list = json['availableQualities'] as List<dynamic>;
      _availableQualities = list.map((e) => e.toString()).toList();
      _canSwitchQuality =
          json['canSwitchQuality'] as bool? ?? (_availableQualities.length > 1);
    }
  }

  Map<String, dynamic> toJson() => {
        'isHighDefinition': _isHighDefinition,
        'volume': _volume,
        'showBatteryPrompt': _showBatteryPrompt,
        'availableQualities': _availableQualities,
        'canSwitchQuality': _canSwitchQuality,
        'quality': _quality
      };
}
