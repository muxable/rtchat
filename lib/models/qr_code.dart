import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Available QR code background gradients.
const Map<String, Gradient> gradientMap = {
  'warmFlame': LinearGradient(
    colors: [Color(0xffff9a9e), Color(0xfffad0c4), Color(0xfffad0c4)],
    stops: [0.0, 0.99, 1.0],
  ),
  'nightFade': LinearGradient(
    transform: GradientRotation(-math.pi / 2),
    colors: [Color(0xffa18cd1), Color(0xfffbc2eb)],
  ),
  'juicyPeach': LinearGradient(colors: [Color(0xffffecd2), Color(0xfffcb69f)]),
  'springWarmth': LinearGradient(
    transform: GradientRotation(-math.pi / 2),
    colors: [Color(0xfffad0c4), Color(0xfffad0c4), Color(0xffffd1ff)],
    stops: [0.0, 0.01, 1.0],
  ),
  'youngPassion': LinearGradient(
    colors: [
      Color(0xffff8177),
      Color(0xffff867a),
      Color(0xffff8c7f),
      Color(0xfff99185),
      Color(0xffcf556c),
      Color(0xffb12a5b),
    ],
    stops: [0.0, 0.0, 0.21, 0.52, 0.78, 1.0],
  ),
  'sunnyMorning': LinearGradient(
    transform: GradientRotation(math.pi / 6),
    colors: [Color(0xfff6d365), Color(0xfffda085)],
  ),
  'ladyLips': LinearGradient(
    transform: GradientRotation(math.pi / 2),
    colors: [Color(0xffff9a9e), Color(0xfffecfef), Color(0xfffecfef)],
    stops: [0.0, 0.99, 1.0],
  ),
  'rainyAshville': LinearGradient(
    transform: GradientRotation(-math.pi / 2),
    colors: [Color(0xfffbc2eb), Color(0xffa6c1ee)],
  ),
  'frozenDreams': LinearGradient(
    transform: GradientRotation(-math.pi / 2),
    colors: [Color(0xfffdcbf1), Color(0xfffdcbf1), Color(0xffe6dee9)],
    stops: [0.0, 0.01, 1.0],
  ),
  'temptingAzure': LinearGradient(
    transform: GradientRotation(math.pi / 6),
    colors: [Color(0xff84fab0), Color(0xff8fd3f4)],
  ),
  'dustyGrass': LinearGradient(
    transform: GradientRotation(math.pi / 6),
    colors: [Color(0xffd4fc79), Color(0xff96e6a1)],
  ),
  'winterNeva': LinearGradient(
    transform: GradientRotation(math.pi / 6),
    colors: [Color(0xffa1c4fd), Color(0xffc2e9fb)],
  ),
};

/// Cached gradients for efficient indexed access.
final List<Gradient> _gradients = gradientMap.values.toList(growable: false);

final List<String> _gradientNames = gradientMap.keys.toList(growable: false);

class QRModel extends ChangeNotifier {
  QRModel({int initialGradient = 0})
    : _currentGradient = _normalizeIndex(initialGradient);

  QRModel.fromJson(Map<String, dynamic> json)
    : _currentGradient = _normalizeIndex(
        (json['currentGradient'] as num?)?.toInt() ?? 0,
      );

  int _currentGradient;

  static int _normalizeIndex(int index) {
    return ((index % _gradients.length) + _gradients.length) %
        _gradients.length;
  }

  int get currentGradientIndex => _currentGradient;

  String get currentGradientName => _gradientNames[_currentGradient];

  Gradient get currentGradient => _gradients[_currentGradient];

  /// Advances to the next gradient.
  void changeGradient() {
    _currentGradient = (_currentGradient + 1) % _gradients.length;
    notifyListeners();
  }

  /// Selects a gradient by index.
  void setGradient(int index) {
    final normalizedIndex = _normalizeIndex(index);

    if (normalizedIndex == _currentGradient) return;

    _currentGradient = normalizedIndex;
    notifyListeners();
  }

  /// Restores the selected gradient from JSON.
  Map<String, dynamic> toJson() => {'currentGradient': _currentGradient};
}
