import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class QuickLinkSource {
  final String icon;
  final Uri url;
  final String label;

  QuickLinkSource(this.icon, this.url, this.label);

  @override
  bool operator ==(other) =>
      other is QuickLinkSource && other.url == url && other.label == label;

  @override
  int get hashCode => url.hashCode;

  QuickLinkSource.fromJson(Map<String, dynamic> json)
      : icon = json['icon'],
        url = Uri.parse(json['url']),
        label = json['label'] ?? json['url']; // null coalescing for migration.

  Map<String, dynamic> toJson() => {
        "url": url.toString(),
        "icon": icon,
        "label": label,
      };

  @override
  String toString() => url.toString();
}

class QuickLinksModel extends ChangeNotifier {
  final List<QuickLinkSource> _sources = [];
  final Set<String> _enabledActions = {};

  List<QuickLinkSource> get sources => _sources;

  static const List<Map<String, dynamic>> availableActions = [
    {
      'id': 'rainMode',
      'icon': Icons.thunderstorm,
      'labelKey': 'enableRainMode',
    },
    {
      'id': 'refreshAudio',
      'icon': Icons.cached_outlined,
      'labelKey': 'refreshAudioSources',
    },
    {
      'id': 'raid',
      'icon': Icons.connect_without_contact,
      'labelKey': 'raidAChannel',
    },
  ];

  bool isActionEnabled(String actionId) => _enabledActions.contains(actionId);

  void toggleAction(String actionId) {
    if (_enabledActions.contains(actionId)) {
      _enabledActions.remove(actionId);
    } else {
      _enabledActions.add(actionId);
    }
    notifyListeners();
  }

  void addSource(QuickLinkSource source) {
    _sources.add(source);
    notifyListeners();
  }

  void removeSource(QuickLinkSource source) {
    _sources.remove(source);
    notifyListeners();
  }

  void swapSource(int a, int b) {
    if (a < b) {
      b -= 1;
    }
    final item = _sources.removeAt(a);
    _sources.insert(b, item);
    notifyListeners();
  }

  QuickLinksModel.fromJson(Map<String, dynamic> json) {
    final sources = json['sources'];
    if (sources != null) {
      for (dynamic source in sources) {
        _sources.add(QuickLinkSource.fromJson(source));
      }
    }
    final enabledActions = json['enabledActions'];
    if (enabledActions != null) {
      for (dynamic action in enabledActions) {
        if (action is String) {
          _enabledActions.add(action);
        }
      }
    }
  }

  Map<String, dynamic> toJson() => {
        "sources": _sources.map((source) => source.toJson()).toList(),
        "enabledActions": _enabledActions.toList(),
      };
}
