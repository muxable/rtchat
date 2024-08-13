import 'package:flutter/material.dart';

class Themes {
  static final lightTheme = ThemeData(
    fontFamily: "Oskari G2",
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF009FDF),
      tertiary: const Color(0xFF1D1D1F),
      surface: Colors.white,
      brightness: Brightness.light,
    ),
  );

  static final darkTheme = ThemeData(
    fontFamily: "Oskari G2",
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF009FDF),
      tertiary: const Color(0xFF1D1D1F),
      surface: Colors.black,
      brightness: Brightness.dark,
    ),
  );
}
