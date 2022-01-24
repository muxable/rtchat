import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class QuickLinkSource {
  final String icon;
  final Uri url;

  QuickLinkSource(this.icon, this.url);

  @override
  bool operator ==(other) => other is QuickLinkSource && other.url == url;

  @override
  int get hashCode => url.hashCode;

  QuickLinkSource.fromJson(Map<String, dynamic> json)
      : icon = json['icon'],
        url = Uri.parse(json['url']);

  Map<String, dynamic> toJson() => {
        "url": url.toString(),
        "icon": icon,
      };

  @override
  String toString() => url.toString();
}

class QuickLinksModel extends ChangeNotifier {
  final List<QuickLinkSource> _sources = [];

  List<QuickLinkSource> get sources => _sources;

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
  }

  Map<String, dynamic> toJson() => {
        "sources": _sources.map((source) => source.toJson()).toList(),
      };
}
