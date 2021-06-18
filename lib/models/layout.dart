import 'dart:core';
import 'dart:math';

import 'package:flutter/foundation.dart';

class LayoutModel extends ChangeNotifier {
  double _panelHeight = 100.0;
  double _panelWidth = 100.0;
  bool _isStatsVisible = true;
  bool _isInputLockable = false;
  bool _locked = false;

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

  set isStatsVisible(bool isStatsVisible) {
    _isStatsVisible = isStatsVisible;
    notifyListeners();
  }

  bool get isInputLockable => _isInputLockable;

  set isInputLockable(bool isInputLockable) {
    _isInputLockable = isInputLockable;
    notifyListeners();
  }

  LayoutModel.fromJson(Map<String, dynamic> json) {
    // final tabs = json['tabs'];
    // if (tabs != null) {
    //   for (dynamic tab in tabs) {
    //     addTab(PanelTab.fromJson(tab));
    //   }
    // }
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
      _isInputLockable = json['isInputLockable'];
    }
  }

  Map<String, dynamic> toJson() => {
        // "tabs": _tabs.map((tab) => tab.toJson()).toList(),
        "panelHeight": _panelHeight,
        "panelWidth": _panelWidth,
        "locked": _locked,
        "isStatsVisible": _isStatsVisible,
        "isInputLockable": _isInputLockable,
      };
}
