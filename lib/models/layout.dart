import 'dart:core';
import 'dart:math';

import 'package:flutter/foundation.dart';

class PanelTab {
  final String label;
  final Uri uri;

  PanelTab({required String label, required Uri uri})
      : label = label,
        uri = uri;

  PanelTab.fromJson(Map<String, dynamic> json)
      : label = json['label'],
        uri = Uri.parse(json['uri']);

  Map<String, dynamic> toJson() => {
        "label": label,
        "uri": uri.toString(),
      };
}

class LayoutModel extends ChangeNotifier {
  final List<PanelTab> _tabs = [];
  double _fontSize = 18;
  double _panelHeight = 100.0;

  Future<void> setFontSize(double fontSize) async {
    _fontSize = fontSize;
    notifyListeners();
  }

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
    notifyListeners();
  }

  double get fontSize {
    return _fontSize;
  }

  double get panelHeight {
    return _panelHeight;
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
    if (json['fontSize'] != null) {
      _fontSize = json['fontSize'];
    }
  }

  Map<String, dynamic> toJson() => {
        "tabs": _tabs.map((tab) => tab.toJson()).toList(),
        "panelHeight": _panelHeight,
        "fontSize": _fontSize,
      };
}
