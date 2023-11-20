import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

final gradientMap = <String, Gradient>{
  "warmFlame": FlutterLinearGradients.warmFlame(),
  "nightFade": FlutterLinearGradients.nightFade(),
  "juicyPeach": FlutterLinearGradients.juicyPeach(),
  "springWarmth": FlutterLinearGradients.springWarmth(),
  "youngPassion": FlutterLinearGradients.youngPassion(),
  "sunnyMorning": FlutterLinearGradients.sunnyMorning(),
  "ladyLips": FlutterLinearGradients.ladyLips(),
  "rainyAshville": FlutterLinearGradients.rainyAshville(),
  "frozenDreams": FlutterLinearGradients.frozenDreams(),
  "temptingAzure": FlutterLinearGradients.temptingAzure(),
  "dustyGrass": FlutterLinearGradients.dustyGrass(),
  "winterNeva": FlutterLinearGradients.winterNeva(),
};

class QRModel extends ChangeNotifier {
  int _currentGradient = 0;

  Gradient get currentGradient {
    var keyName = gradientMap.keys.toList()[_currentGradient];
    return gradientMap[keyName]!;
  }

  void changeGradient() {
    _currentGradient = (_currentGradient + 1) % gradientMap.length;
    notifyListeners();
  }

  QRModel.fromJson(Map<String, dynamic> json) {
    if (json["currentGradient"] != null) {
      _currentGradient = json["currentGradient"];
    }
  }

  Map<String, dynamic> toJson() => {
        "currentGradient": _currentGradient,
      };
}

class FlutterLinearGradients {
  static Gradient warmFlame({TileMode tileMode = TileMode.clamp}) =>
      LinearGradient(
        colors: const [Color(0xffff9a9e), Color(0xfffad0c4)],
        stops: const [0.0, 0.99, 1.0],
        tileMode: tileMode,
      );

  static Gradient nightFade({TileMode tileMode = TileMode.clamp}) =>
      LinearGradient(
        transform: gradientRotation(-pi / 2),
        colors: const [Color(0xffa18cd1), Color(0xfffbc2eb)],
        stops: const [0.0, 1.0],
        tileMode: tileMode,
      );

  static Gradient springWarmth({TileMode tileMode = TileMode.clamp}) =>
      LinearGradient(
        transform: gradientRotation(-pi / 2),
        colors: const [Color(0xfffad0c4), Color(0xfffad0c4), Color(0xffffd1ff)],
        stops: const [0.0, 0.01, 1.0],
        tileMode: tileMode,
      );

  static Gradient juicyPeach({TileMode tileMode = TileMode.clamp}) =>
      LinearGradient(
        transform: gradientRotation(0.0),
        colors: const [Color(0xffffecd2), Color(0xfffcb69f)],
        stops: const [0.0, 1.0],
        tileMode: tileMode,
      );

  static Gradient youngPassion({TileMode tileMode = TileMode.clamp}) =>
      LinearGradient(
        transform: gradientRotation(0.0),
        colors: const [
          Color(0xffff8177),
          Color(0xffff867a),
          Color(0xffff8c7f),
          Color(0xfff99185),
          Color(0xffcf556c),
          Color(0xffb12a5b)
        ],
        stops: const [0.0, 0.0, 0.21, 0.52, 0.78, 1.0],
        tileMode: tileMode,
      );

  static Gradient ladyLips({TileMode tileMode = TileMode.clamp}) =>
      LinearGradient(
        transform: gradientRotation(pi / 2),
        colors: const [Color(0xffff9a9e), Color(0xfffecfef), Color(0xfffecfef)],
        stops: const [0.0, 0.99, 1.0],
        tileMode: tileMode,
      );

  static Gradient sunnyMorning({TileMode tileMode = TileMode.clamp}) =>
      LinearGradient(
        transform: gradientRotation(pi / 6),
        colors: const [Color(0xfff6d365), Color(0xfffda085)],
        stops: const [0.0, 1.0],
        tileMode: tileMode,
      );

  static Gradient rainyAshville({TileMode tileMode = TileMode.clamp}) =>
      LinearGradient(
        transform: gradientRotation(-pi / 2),
        colors: const [Color(0xfffbc2eb), Color(0xffa6c1ee)],
        stops: const [0.0, 1.0],
        tileMode: tileMode,
      );

  static Gradient frozenDreams({TileMode tileMode = TileMode.clamp}) =>
      LinearGradient(
        transform: gradientRotation(-pi / 2),
        colors: const [Color(0xfffdcbf1), Color(0xfffdcbf1), Color(0xffe6dee9)],
        stops: const [0.0, 0.01, 1.0],
        tileMode: tileMode,
      );

  static Gradient winterNeva({TileMode tileMode = TileMode.clamp}) =>
      LinearGradient(
        transform: gradientRotation(pi / 6),
        colors: const [Color(0xffa1c4fd), Color(0xffc2e9fb)],
        stops: const [0.0, 1.0],
        tileMode: tileMode,
      );

  static Gradient dustyGrass({TileMode tileMode = TileMode.clamp}) =>
      LinearGradient(
        transform: gradientRotation(pi / 6),
        colors: const [Color(0xffd4fc79), Color(0xff96e6a1)],
        stops: const [0.0, 1.0],
        tileMode: tileMode,
      );

  static Gradient temptingAzure({TileMode tileMode = TileMode.clamp}) =>
      LinearGradient(
        transform: gradientRotation(pi / 6),
        colors: const [Color(0xff84fab0), Color(0xff8fd3f4)],
        stops: const [0.0, 1.0],
        tileMode: tileMode,
      );
}

GradientRotation gradientRotation(double angle) {
  return GradientRotation(angle * (pi / 180));
}
