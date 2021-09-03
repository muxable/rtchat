import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum OrientationPreference {
  portrait,
  landscape,
  system,
}

extension _OrientationPreferenceJson on OrientationPreference {
  int toJson() {
    switch (this) {
      case OrientationPreference.portrait:
        return 0;
      case OrientationPreference.landscape:
        return 1;
      case OrientationPreference.system:
        return 2;
    }
  }

  static OrientationPreference fromJson(dynamic json) {
    switch (json) {
      case 0:
        return OrientationPreference.portrait;
      case 1:
        return OrientationPreference.landscape;
      case 2:
        return OrientationPreference.system;
    }
    return OrientationPreference.system;
  }
}

class LayoutModel extends ChangeNotifier {
  double _panelHeight = 100.0;
  double _panelWidth = 100.0;
  bool _isStatsVisible = true;
  bool _isInteractionLockable = false;
  bool _locked = false;
  OrientationPreference _orientationPreference = OrientationPreference.system;

  void updatePanelHeight({required double dy}) {
    _panelHeight += dy;
    notifyListeners();
  }

  void updatePanelWidth({required double dx}) {
    _panelWidth += dx;
    notifyListeners();
  }

  double get panelHeight => _panelHeight;

  double get panelWidth => _panelWidth;

  bool get locked => _locked;

  set locked(bool locked) {
    _locked = locked;
    notifyListeners();
  }

  bool get isStatsVisible => _isStatsVisible;

  set isStatsVisible(bool value) {
    _isStatsVisible = value;
    notifyListeners();
  }

  bool get isInteractionLockable => _isInteractionLockable;

  set isInteractionLockable(bool value) {
    _isInteractionLockable = value;
    notifyListeners();
  }

  OrientationPreference get orientationPreference => _orientationPreference;

  set orientationPreference(OrientationPreference value) {
    _orientationPreference = value;
    _bindOrientationPreference();
    notifyListeners();
  }

  void _bindOrientationPreference() {
    switch (_orientationPreference) {
      case OrientationPreference.portrait:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        break;
      case OrientationPreference.landscape:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case OrientationPreference.system:
        SystemChrome.setPreferredOrientations([]);
        break;
    }
  }

  LayoutModel.fromJson(Map<String, dynamic> json) {
    if (json['panelHeight'] != null) {
      _panelHeight = json['panelHeight'];
    }
    if (json['panelWidth'] != null) {
      _panelWidth = json['panelWidth'];
    }
    if (json['locked'] != null) {
      _locked = json['locked'];
    }
    if (json['isStatsVisible'] != null) {
      _isStatsVisible = json['isStatsVisible'];
    }
    if (json['isInputLockable'] != null) {
      _isInteractionLockable = json['isInputLockable'];
    }
    if (json['orientationPreference'] != null) {
      _orientationPreference =
          _OrientationPreferenceJson.fromJson(json['orientationPreference']);
      _bindOrientationPreference();
    }
  }

  Map<String, dynamic> toJson() => {
        "panelHeight": _panelHeight,
        "panelWidth": _panelWidth,
        "locked": _locked,
        "isStatsVisible": _isStatsVisible,
        "isInputLockable": _isInteractionLockable,
        "orientationPreference": _orientationPreference.toJson(),
      };
}
