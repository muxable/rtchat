import 'package:flutter/material.dart';

class StreamUptime extends ChangeNotifier {
  bool _isOnline = false;
  DateTime? _streamStartTimestamp;

  set isOnline(bool isOnline) {
    _isOnline = isOnline;
    notifyListeners();
  }

  bool get isOnline => _isOnline;

  set streamStartTimestamp(DateTime streamStartTimestamp) {
    _streamStartTimestamp = streamStartTimestamp;
    notifyListeners();
  }

  DateTime get streamStartTimestamp => _streamStartTimestamp!;
}
