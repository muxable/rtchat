import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum PreferredOrientation {
  portrait,
  landscape,
  system,
}

extension _OrientationPreferenceJson on PreferredOrientation {
  int toJson() {
    switch (this) {
      case PreferredOrientation.portrait:
        return 0;
      case PreferredOrientation.landscape:
        return 1;
      case PreferredOrientation.system:
        return 2;
    }
  }

  static PreferredOrientation fromJson(dynamic json) {
    switch (json) {
      case 0:
        return PreferredOrientation.portrait;
      case 1:
        return PreferredOrientation.landscape;
      case 2:
        return PreferredOrientation.system;
    }
    return PreferredOrientation.system;
  }
}

class LayoutModel extends ChangeNotifier {
  double _panelHeight = 100.0;
  double _panelWidth = 100.0;
  bool _isStatsVisible = true;
  bool _isInteractionLockable = false;
  bool _locked = false;
  PreferredOrientation _orientationPreference = PreferredOrientation.system;

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

  PreferredOrientation get preferredOrientation => _orientationPreference;

  set preferredOrientation(PreferredOrientation value) {
    _orientationPreference = value;
    _bindOrientationPreference();
    notifyListeners();
  }

  void _bindOrientationPreference() async {
    switch (_orientationPreference) {
      case PreferredOrientation.portrait:
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        break;
      case PreferredOrientation.landscape:
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case PreferredOrientation.system:
        await SystemChrome.setPreferredOrientations([]);
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
