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
  double _version = 20;
  bool _useProfileImage = false;

  Gradient get currentGradient =>
      gradientMap[gradientMap.keys.toList()[_currentGradient]]!;
  double get version => _version;
  bool get useProfile => _useProfileImage;

  void changeGradient() {
    _currentGradient = (_currentGradient + 1) % gradientMap.length;
    notifyListeners();
  }

  void toggleProfileImage() {
    _useProfileImage = !_useProfileImage;
    notifyListeners();
  }

  set size(double updatedVersion) {
    _version = updatedVersion;
    notifyListeners();
  }

  QRModel.fromJson(Map<String, dynamic> json) {
    if (json["currentGradient"] != null) {
      _currentGradient = json["currentGradient"];
    }
    if (json["size"] != null) {
      _version = json["size"];
    }
    if (json["useProfileImage"] != null) {
      _useProfileImage = json["useProfileImage"];
    }
  }

  Map<String, dynamic> toJson() => {
        "currentGradient": _currentGradient,
        "size": _version,
        "useProfileImage": _useProfileImage,
      };
}

// Code  from https://github.com/JonathanMonga/flutter_gradients
class FlutterLinearGradients {
  static LinearGradient linear(
    String name,
    double angle,
    List<Color> colors,
    List<double> stops,
    TileMode tileMode,
  ) =>
      create(
        angle,
        colors,
        stops,
        tileMode,
      );

  /// 1. Warm Flame
  static Gradient warmFlame({TileMode tileMode = TileMode.clamp}) => linear(
        "Warm Flame",
        -45.0,
        [
          const Color(0x00ff9a9e),
          const Color(0x00fad0c4),
          const Color(0x00fad0c4)
        ],
        [0.0, 0.99, 1.0],
        tileMode,
      );

  /// 2. Night Fade
  static Gradient nightFade({TileMode tileMode = TileMode.clamp}) => linear(
        "Night Fade",
        -90.0,
        [const Color(0x00a18cd1), const Color(0x00fbc2eb)],
        [0.0, 1.0],
        tileMode,
      );

  /// 3. Spring Warmth
  static Gradient springWarmth({TileMode tileMode = TileMode.clamp}) => linear(
        "Spring Warmth",
        -90.0,
        [
          const Color(0x00fad0c4),
          const Color(0x00fad0c4),
          const Color(0x00ffd1ff)
        ],
        [0.0, 0.01, 1.0],
        tileMode,
      );

  /// 4. Juicy Peach
  static Gradient juicyPeach({TileMode tileMode = TileMode.clamp}) => linear(
        "Juicy Peach",
        0.0,
        [const Color(0x00ffecd2), const Color(0x00fcb69f)],
        [0.0, 1.0],
        tileMode,
      );

  /// 5. Young Passion
  static Gradient youngPassion({TileMode tileMode = TileMode.clamp}) => linear(
        "Young Passion",
        0.0,
        [
          const Color(0x00ff8177),
          const Color(0x00ff867a),
          const Color(0x00ff8c7f),
          const Color(0x00f99185),
          const Color(0x00cf556c),
          const Color(0x00b12a5b)
        ],
        [0.0, 0.0, 0.21, 0.52, 0.78, 1.0],
        tileMode,
      );

  /// 6. Lady Lips
  static Gradient ladyLips({TileMode tileMode = TileMode.clamp}) => linear(
        "Lady Lips",
        -90.0,
        [
          const Color(0x00ff9a9e),
          const Color(0x00fecfef),
          const Color(0x00fecfef)
        ],
        [0.0, 0.99, 1.0],
        tileMode,
      );

  /// 7. Sunny Morning
  static Gradient sunnyMorning({TileMode tileMode = TileMode.clamp}) => linear(
        "Sunny Morning",
        30.0,
        [const Color(0x00f6d365), const Color(0x00fda085)],
        [0.0, 1.0],
        tileMode,
      );

  /// 8. Rainy Ashville
  static Gradient rainyAshville({TileMode tileMode = TileMode.clamp}) => linear(
        "Rainy Ashville",
        -90.0,
        [const Color(0x00fbc2eb), const Color(0x00a6c1ee)],
        [0.0, 1.0],
        tileMode,
      );

  /// 9. Frozen Dreams
  static Gradient frozenDreams({TileMode tileMode = TileMode.clamp}) => linear(
        "Frozen Dreams",
        -90.0,
        [
          const Color(0x00fdcbf1),
          const Color(0x00fdcbf1),
          const Color(0x00e6dee9)
        ],
        [0.0, 0.01, 1.0],
        tileMode,
      );

  /// 10. Winter Neva
  static Gradient winterNeva({TileMode tileMode = TileMode.clamp}) => linear(
        "Winter Neva",
        30.0,
        [const Color(0x00a1c4fd), const Color(0x00c2e9fb)],
        [0.0, 1.0],
        tileMode,
      );

  /// 11. Dusty Grass
  static Gradient dustyGrass({TileMode tileMode = TileMode.clamp}) => linear(
        "Dusty Grass",
        30.0,
        [const Color(0x00d4fc79), const Color(0x0096e6a1)],
        [0.0, 1.0],
        tileMode,
      );

  /// 12. Tempting Azure
  static Gradient temptingAzure({TileMode tileMode = TileMode.clamp}) => linear(
        "Tempting Azure",
        30.0,
        [const Color(0x0084fab0), const Color(0x008fd3f4)],
        [0.0, 1.0],
        tileMode,
      );
}

/// The method that create a LinearGradient object
LinearGradient create(
  double angle,
  List<Color> colors,
  List<double> stops,
  TileMode tileMode,
) =>
    LinearGradient(
      colors: colors,
      stops: stops,
      tileMode: tileMode,
      transform: GradientRotation(toRadians(angle)),
    );

double toRadians(double angle) {
  const degToRad = pi / 180;
  return angle * degToRad;
}

Color _intToColor(int hexNumber) => Color.fromARGB(
    255,
    (hexNumber >> 16) & 0xFF,
    ((hexNumber >> 8) & 0xFF),
    (hexNumber >> 0) & 0xFF);

//Substring
String _textSubString(String text) {
  if (text.length < 6) return "";

  if (text.length == 6) return text;

  return text.substring(1, text.length);
}

/// String To Material color
Color stringToColor(String hex) =>
    _intToColor(int.parse(_textSubString(hex), radix: 16));
