import 'dart:core';

import 'package:flutter/material.dart';
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

extension _ThemeModeJson on ThemeMode {
  int toJson() {
    switch (this) {
      case ThemeMode.light:
        return 0;
      case ThemeMode.dark:
        return 1;
      case ThemeMode.system:
        return 2;
    }
  }

  static ThemeMode fromJson(dynamic json) {
    switch (json) {
      case 0:
        return ThemeMode.light;
      case 1:
        return ThemeMode.dark;
      case 2:
        return ThemeMode.system;
    }
    return ThemeMode.system;
  }
}

class LayoutModel extends ChangeNotifier {
  double _panelHeight = 300.0;
  double _panelWidth = 300.0;
  bool _isStatsVisible = true;
  bool _locked = false;
  double _onDragStartHeight = 300.0;
  PreferredOrientation _orientationPreference = PreferredOrientation.system;
  bool _isShowNotifications = false;
  bool _isShowPreview = false;
  ThemeMode _themeMode = ThemeMode.system;

  void updatePanelHeight({required double dy}) {
    _panelHeight += dy;
    notifyListeners();
  }

  void updatePanelWidth({required double dx}) {
    _panelWidth += dx;
    notifyListeners();
  }

  set panelHeight(double panelHeight) {
    _panelHeight = panelHeight;
    notifyListeners();
  }

  double get panelHeight => _panelHeight;

  double get panelWidth => _panelWidth;

  set panelWidth(double panelWidth) {
    _panelWidth = panelWidth;
    notifyListeners();
  }

  double get onDragStartHeight => _onDragStartHeight;

  set onDragStartHeight(double onDragStartHeight) {
    _onDragStartHeight = onDragStartHeight;
    notifyListeners();
  }

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

  PreferredOrientation get preferredOrientation => _orientationPreference;

  set preferredOrientation(PreferredOrientation value) {
    _orientationPreference = value;
    _bindOrientationPreference();
    notifyListeners();
  }

  ThemeMode get themeMode => _themeMode;

  set themeMode(ThemeMode value) {
    _themeMode = value;
    notifyListeners();
  }

  bool get isShowNotifications => _isShowNotifications;

  set isShowNotifications(bool value) {
    _isShowPreview = false;
    _isShowNotifications = value;
    notifyListeners();
  }

  bool get isShowPreview => _isShowPreview;

  set isShowPreview(bool value) {
    _isShowNotifications = false;
    _isShowPreview = value;
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
    if (json['orientationPreference'] != null) {
      _orientationPreference =
          _OrientationPreferenceJson.fromJson(json['orientationPreference']);
      _bindOrientationPreference();
    }
    if (json['isShowNotifications'] != null) {
      _isShowNotifications = json['isShowNotifications'];
    }
    if (json['isShowPreview'] != null) {
      _isShowPreview = json['isShowPreview'];
    }
    if (json['themeMode'] != null) {
      _themeMode = _ThemeModeJson.fromJson(json['themeMode']);
    }
  }

  Map<String, dynamic> toJson() => {
        "panelHeight": _panelHeight,
        "panelWidth": _panelWidth,
        "locked": _locked,
        "isStatsVisible": _isStatsVisible,
        "orientationPreference": _orientationPreference.toJson(),
        "isShowNotifications": _isShowNotifications,
        "isShowPreview": _isShowPreview,
        "themeMode": _themeMode.toJson(),
      };
}
