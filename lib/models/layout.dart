import 'dart:core';
import 'dart:math';

import 'package:flutter/foundation.dart';

class PanelTab {
  final String label;
  final String uri;

  PanelTab({required String label, required String uri})
      : label = label,
        uri = uri;

  PanelTab.fromJson(Map<String, dynamic> json)
      : label = json['label'],
        uri = json['uri'];

  Map<String, dynamic> toJson() => {
        "label": label,
        "uri": uri,
      };
}

class LayoutModel extends ChangeNotifier {
  final List<PanelTab> _tabs = [];
  double _fontSize = 20;
  double _panelHeight = 100.0;
  double _panelWidth = 100.0;
  double _lightnessBoost = 0.179;
  bool _isStatsVisible = true;
  bool _isInputLockable = false;
  bool _locked = false;

  List<PanelTab> get tabs {
    return _tabs;
  }

  void addTab(PanelTab tab) {
    _tabs.add(tab);
    notifyListeners();
  }

  void removeTab(int index) {
    _tabs.removeAt(index);
    notifyListeners();
  }

  void updatePanelHeight({required double dy}) {
    _panelHeight += dy;
    _panelHeight = max(_panelHeight, 1);
    _panelHeight = min(_panelHeight, 400);
    notifyListeners();
  }

  double get fontSize {
    return _fontSize;
  }

  set fontSize(double fontSize) {
    _fontSize = fontSize;
    notifyListeners();
  }

  double get panelHeight {
    return _panelHeight;
  }

  double get panelWidth {
    return _panelWidth;
  }

  double get lightnessBoost {
    return _lightnessBoost;
  }

  set lightnessBoost(double lightnessBoost) {
    _lightnessBoost = lightnessBoost;
    notifyListeners();
  }

  bool get locked {
    return _locked;
  }

  set locked(bool locked) {
    _locked = locked;
    notifyListeners();
  }

  bool get isStatsVisible {
    return _isStatsVisible;
  }

  set isStatsVisible(bool isStatsVisible) {
    _isStatsVisible = isStatsVisible;
    notifyListeners();
  }

  bool get isInputLockable {
    return _isInputLockable;
  }

  set isInputLockable(bool isInputLockable) {
    _isInputLockable = isInputLockable;
    notifyListeners();
  }

  LayoutModel.fromJson(Map<String, dynamic> json) {
    final tabs = json['tabs'];
    if (tabs != null) {
      for (dynamic tab in tabs) {
        addTab(PanelTab.fromJson(tab));
      }
    }
    if (json['panelHeight'] != null) {
      _panelHeight = json['panelHeight'];
    }
    if (json['panelWidth'] != null) {
      _panelWidth = json['panelWidth'];
    }
    if (json['lightnessBoost'] != null) {
      _lightnessBoost = json['lightnessBoost'];
    }
    if (json['fontSize'] != null) {
      _fontSize = json['fontSize'];
    }
    if (json['locked'] != null) {
      _locked = json['locked'];
    }
    if (json['isStatsVisible'] != null) {
      _isStatsVisible = json['isStatsVisible'];
    }
    if (json['isInputLockable'] != null) {
      _isInputLockable = json['isInputLockable'];
    }
  }

  Map<String, dynamic> toJson() => {
        "tabs": _tabs.map((tab) => tab.toJson()).toList(),
        "panelHeight": _panelHeight,
        "panelWidth": _panelWidth,
        "lightnessBoost": _lightnessBoost,
        "fontSize": _fontSize,
        "locked": _locked,
        "isStatsVisible": _isStatsVisible,
        "isInputLockable": _isInputLockable,
      };
}
